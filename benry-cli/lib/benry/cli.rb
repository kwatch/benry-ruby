# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


module Benry
end


module Benry::CLI


  class OptionDefinitionError < StandardError
  end


  class OptionError < StandardError
  end


  class OptionSchema

    def initialize(short, long, argname, argflag, desc, &block)
      @short    = short
      @long     = long
      @argname  = argname
      @argflag  = argflag   # :required, :optional, or nil
      @desc     = desc
      @block    = block
    end

    attr_reader :short, :long, :argname, :argflag, :desc, :block

    def ==(other)
      return (
        self.class  == other.class    \
        && @short   == other.short    \
        && @long    == other.long     \
        && @argname == other.argname  \
        && @argflag == other.argflag  \
        && @desc    == other.desc     \
        && @block   == other.block
      )
    end

    def arg_required?
      return @argflag == :required
    end

    def arg_optional?
      return @argflag == :optional
    end

    def arg_nothing?
      return @argflag == nil
    end

    def canonical_name
      #; [!86hqr] returns long option name if it is provided.
      #; [!y9xch] returns short option name if long option is not provided.
      return @long || @short
    end

    def self.parse(defstr, desc, &block)
      #; [!fdh36] can parse '-v, --version' (short + long).
      #; [!jkmee] can parse '-v' (short)
      #; [!uc2en] can parse '--version' (long).
      #; [!sy157] can parse '-f, --file=FILE' (short + long + required-arg).
      #; [!wrjqa] can parse '-f FILE' (short + required-arg).
      #; [!ip99s] can parse '--file=FILE' (long + required-arg).
      #; [!9pmv8] can parse '-i, --indent[=N]' (short + long + optional-arg).
      #; [!ooo42] can parse '-i[N]' (short + optional-arg).
      #; [!o93c7] can parse '--indent[=N]' (long + optional-arg).
      #; [!gzuhx] can parse string with extra spaces.
      defstr = defstr.strip()
      case defstr
      when /\A-(\w),\s*--(\w[-\w]*)(?:=(\S+)|\[=(\S+)\])?\z/ ; arr = [$1,  $2,  $3, $4]
      when /\A-(\w)(?:\s+(\S+)|\[(\S+)\])?\z/                ; arr = [$1,  nil, $2, $3]
      when /\A--(\w[-\w]*)(?:=(\S+)|\[=(\S+)\])?\z/          ; arr = [nil, $1,  $2, $3]
      else
        #; [!1769n] raises error when invalid format.
        raise OptionDefinitionError.new("'#{defstr}': failed to parse option definition.")
      end
      short, long, arg_required, arg_optional = arr
      #; [!j2wgf] raises error when '-i [N]' specified.
      defstr !~ /\A-\w\s+\[/  or
        raise OptionDefinitionError.new("'#{defstr}': failed to parse option definition"+\
                                        " due to extra space before '['"+\
                                        " (should be '#{defstr.sub(/\s+/, '')}').")
      #
      argname = arg_required || arg_optional
      argflag = arg_required ? :required \
              : arg_optional ? :optional : nil
      return self.new(short, long, argname, argflag, desc, &block)
    end

    def option_string
      #; [!pdaz3] builds option definition string.
      s = ""
      case
      when @short && @long ; s << "-#{@short}, --#{@long}"
      when @short          ; s << "-#{@short}"
      when           @long ; s << "    --#{@long}"
      else
        raise "unreachable"
      end
      #
      case
      when arg_required? ; s << (@long ? "=#{@argname}"   : " #{@argname}")
      when arg_optional? ; s << (@long ? "[=#{@argname}]" : "[#{@argname}]")
      else               ; nil
      end
      #
      return s
    end

  end


  class OptionParser

    def initialize(option_schemas)
      #; [!bflls] takes array of option schema.
      @option_schemas = option_schemas.collect {|x|
        case x
        when OptionSchema ; x
        when Array        ; OptionSchema.parse(*x)
        else
          raise OptionDefinitionError.new("#{x.inspect}: invalid option schema.")
        end
      }
    end

    def err(msg)
      OptionError.new(msg)
    end

    def parse_options(args)
      #; [!5jfhv] returns command-line options as hash object.
      #; [!06iq3] removes command-line options from args.
      option_values = {}
      while args[0] && args[0].start_with?('-')
        argstr = args.shift
        #; [!31h46] stops parsing when '--' appears in args.
        if argstr == '--'
          break
        #; [!w5dpy] can parse long options.
        elsif argstr.start_with?('--')
          parse_long_option(argstr, option_values)
        #; [!mov8e] can parse short options.
        else
          parse_short_option(args, argstr, option_values)
        end
      end
      return option_values
    end

    private

    def parse_long_option(argstr, option_values)
      argstr =~ /\A--(\w[-\w]*)(?:=(.*))?\z/
      long, value = $1, $2
      #; [!w67gl] raises error when long option is unknown.
      opt = @option_schemas.find {|x| x.long == long }  or
        raise err("--#{long}: unknown option.")
      #; [!kyd1j] raises error when required argument of long option is missing.
      if opt.arg_required?
        value  or
          raise err("#{argstr}: argument required.")
      #; [!wuyrh] uses true as default value of optional argument of long option.
      elsif opt.arg_optional?
        value ||= true
      #; [!91b2j] raises error when long option takes no argument but specified.
      else
        value.nil?  or
          raise err("#{argstr}: unexpected argument.")
        value = true
      end
      #; [!9td8b] invokes callback with long option value if callback exists.
      begin
        value = opt.block.call(value) if opt.block
      rescue => ex
        #; [!nkqln] regards RuntimeError callback raised as long option error.
        raise unless ex.class == RuntimeError
        raise err("#{argstr}: #{ex.message}")
      end
      #
      option_values[opt.canonical_name] = value
    end

    def parse_short_option(args, argstr, option_values)
      n = argstr.length
      i = 0
      while (i += 1) < n
        char = argstr[i]
        #; [!wr58v] raises error when unknown short option specified.
        opt = @option_schemas.find {|x| x.short == char } or
          raise err("-#{char}: unknown option.")
        #; [!jzdcr] raises error when requried argument of short option is missing.
        if opt.arg_required?
          value = argstr[(i+1)..-1]
          value = args.shift if value.empty?
          value  or
            raise err("-#{char}: argument required.")
          i = n
        #; [!hnki9] uses true as default value of optional argument of short option.
        elsif opt.arg_optional?
          value = argstr[(i+1)..-1]
          value = true if value.empty?
          i = n
        #; [!8gj65] uses true as value of short option which takes no argument.
        else
          value = true
        end
        #; [!l6gss] invokes callback with short option value if exists.
        begin
          value = opt.block.call(value) if opt.block
        rescue => ex
          #; [!d4mgr] regards RuntimeError callback raised as short option error.
          raise unless ex.class == RuntimeError
          space = opt.arg_required? ? ' ' : ''
          raise err("-#{char}#{space}#{value}: #{ex.message}")
        end
        #
        option_values[opt.canonical_name] = value
      end
    end

  end


  class Action

    SUBCLASSES = []

    def self.inherited(subclass)
      #; [!al5pr] provides @action and @option for subclass.
      subclass.class_eval do
        @__mappings = []
        @__defining = nil
        @action = proc do |action_name, desc|
          option_schemas = []
          option_schemas << OptionSchema.parse("-h, --help", "print help message")
          method_name    = nil
          @__defining = [action_name, desc, option_schemas, method_name]
        end
        #; [!ymtsg] allows block argument to @option.
        @option = proc do |defstr, desc, &block|
          #; [!di9na] raises error when @option.() called without @action.().
          @__defining  or
            raise OptionDefinitionError.new("@option.(#{defstr.inspect}): @action.() should be called prior to @option.().")
          option_schemas = @__defining[2]
          option_schemas << OptionSchema.parse(defstr, desc, &block)
        end
      end
      #; [!4otr6] registers subclass.
      SUBCLASSES << subclass
    end

    def self.method_added(method_name)
      #; [!syzvc] registers action with method.
      if @__defining
        @__defining[-1] = method_name
        @__mappings << @__defining
        #; [!m7y8p] clears current action definition.
        @__defining = nil
      end
    end

  end


  class ActionInfo

    def initialize(full_name, name, desc, option_schemas, action_class, action_method)
      @full_name      = full_name
      @name           = name
      @desc           = desc
      @option_schemas = option_schemas
      @action_class   = action_class
      @action_method  = action_method
    end

    attr_reader :full_name, :name, :desc, :option_schemas, :action_class, :action_method

    def ==(other)
      return (
        self.class == other.class                   \
        && @full_name      == other.full_name       \
        && @name           == other.name            \
        && @desc           == other.desc            \
        && @option_schemas == other.option_schemas  \
        && @action_class   == other.action_class    \
        && @action_method  == other.action_method
      )
    end

    def help_message(command)
      #; [!hjq5l] builds help message.
      meth = @action_class.new.method(@action_method)
      argstr = ""
      meth.parameters.each do |kind, name|
        name_str = name.to_s.gsub('_', '-')
        case kind
        when :req ; argstr << " #{name_str}"
        when :opt ; argstr << " [#{name_str}]"
        when :rest; argstr << " [#{name_str}...]"
        end
      end
      msg = ""
      #msg << "#{command} #{@full_name}  --  #{@desc}\n"
      msg << "#{@desc}\n"
      msg << "\n"
      msg << "Usage:\n"
      msg << "  #{command} #{@full_name} [options]#{argstr}\n"
      msg << "\n"
      msg << "Options:\n"
      pairs = @option_schemas.collect {|opt| [opt.option_string, opt.desc] }
      width = pairs.collect {|pair| pair[0].length }.max
      width = [width, 20].max
      width = [width, 35].min
      pairs.each do |option_string, desc|
        msg << "  %-#{width}s : %s\n" % [option_string, desc]
      end
      return msg
    end

  end


  class Application

    def self._setup_app_class(klass)  # :nodoc:
      klass.class_eval do
        #; [!8swia] global option '-h' and '--help' are enabled by default.
        #; [!vh08n] global option '--version' is enabled by defaut.
        @_global_option_schemas = [
          OptionSchema.parse("-h, --help",    "print help message"),
          OptionSchema.parse("    --version", "print version"),
        ]
        #; [!b09pv] provides @global_option in subclass.
        @global_option = proc do |defstr, desc, &block|
          @_global_option_schemas << OptionSchema.parse(defstr, desc, &block)
        end
      end
    end

    self._setup_app_class(self)

    def self.inherited(subclass)   # :nodoc:
      self._setup_app_class(subclass)
    end

    def initialize(action_classes=nil, desc: nil, version: '0.0')
      @action_dict = accept(action_classes || Action::SUBCLASSES)
      @desc        = desc
      @version     = version
    end

    attr_reader :desc, :version

    private

    def accept(action_classes)
      #; [!ue26k] builds action dictionary.
      action_dict = {}
      action_classes.each do |klass|
        prefix = klass.instance_variable_get('@prefix')
        (klass.instance_variable_get('@__mappings') || []).each do |tuple|
          action_name, desc, option_schemas, method_name = tuple
          action_name ||= method_name
          full_name = prefix ? "#{prefix}:#{action_name}" : action_name.to_s
          action_dict[full_name] = ActionInfo.new(full_name, action_name, desc,
                                            option_schemas, klass, method_name)
        end
      end
      return action_dict
    end

    public

    def call(*args)
      ## global options
      gopt_values = parse_global_options(args)
      output = handle_global_options(args, gopt_values)
      return output if output
      ## global help
      #; [!p5pr6] returns global help message when action is 'help'.
      #; [!3hyvi] returns help message of action when action is 'help' with action name.
      action_full_name = args.shift || "help"
      if action_full_name == "help"
        return help_message(File.basename($0), args[0])
      end
      ## action and options
      #; [!mb92l] raises error when action name is unknown.
      action_info = @action_dict[action_full_name]  or
        raise err("#{action_full_name}: unknown action.")
      option_values = parse_options(args, action_info.option_schemas)
      ## show help
      #; [!13m3q] returns help message if '-h' or '--help' specified to action.
      if option_values['help']
        return action_info.help_message(File.basename($0))
      end
      ## validation
      obj = action_info.action_class.new()
      validate_args(obj, action_info.action_method, args)
      ## do action
      ret = run_action(obj, action_info.action_method, args, option_values)
      return ret
    end

    def main(argv=ARGV)
      begin
        ret = call(*argv)
      rescue OptionError => ex
        $stderr.puts "ERROR: #{ex}"
        exit 1
      else
        case ret
        when String
          output = ret
          puts output
          exit 0
        when Integer
          status = ret
          exit status
        else
          exit 0
        end
      end
    end

    protected

    def parse_global_options(args)
      gopt_schemas = self.class.instance_variable_get('@_global_option_schemas')
      gopt_values = parse_options(args, gopt_schemas)
      return gopt_values
    end

    def handle_global_options(args, global_option_values)
      g_opts = global_option_values
      #; [!b8isy] returns help message when global option '-h' or '--help' is specified.
      if g_opts['help']
        return help_message(File.basename($0), nil)
      end
      #; [!4irzw] returns version string when global option '--version' is specified.
      if g_opts['version']
        return @version || '0.0'
      end
    end

    def validate_args(action_obj, method_name, args)
      #; [!yhry7] raises error when required argument is missing.
      meth = action_obj.method(method_name)
      n_min = meth.parameters.count {|x| x[0] == :req }
      args.length >= n_min  or
        raise err("too few arguments (at least #{n_min} args expected).")
      #; [!h5522] raises error when too much arguments specified.
      #; [!hq8b0] not raise error when many argument specified but method has *args.
      unless meth.parameters.find {|x| x[0] == :rest }
        n_max = meth.parameters.count {|x| x[0] == :req || x[0] == :opt }
        args.length <= n_max  or
          raise err("too many arguments (at most #{n_max} args expected).")
      end
    end

    def run_action(action_obj, method_name, args, option_values)
      #; [!rph9y] converts 'foo-bar' option name into :foo_bar keyword.
      kwargs = Hash[option_values.map {|k, v| [k.gsub(/-/, '_').intern, v] }]
      #; [!qwd9x] passes command arguments and options as method arguments and options.
      method_obj = action_obj.method(method_name)
      has_kwargs = method_obj.parameters.any? {|x| x[0] == :key }
      if has_kwargs
        return method_obj.call(*args, kwargs)
      else
        return method_obj.call(*args)
      end
    end

    public

    def help_message(command, action_name=nil)
      if action_name
        action_info = @action_dict[action_name]  or
          raise err("#{action_name}: no such action.")
        return action_info.help_message(command)
      end
      #
      msg = ""
      #; [!1zpv4] adds command desc if it is specified at initializer.
      if @desc
        #msg << "#{command}  -- #{@desc}\n"
        #msg << "\n"
        msg << @desc << "\n\n"
      end
      msg << "Usage:\n"
      msg << "  #{command} [options] <action> [<args>...]\n"
      msg << "\n"
      msg << "Options:\n"
      self.class.instance_variable_get('@_global_option_schemas').each do |schema|
        msg << "  %-20s : %s\n" % [schema.option_string, schema.desc]
      end
      msg << "\n"
      msg << "Actions:\n"
      #msg << "  %-20s : %s\n" % ["help", "show this help"]
      @action_dict.keys.sort.each do |action_full_name|
        action_info = @action_dict[action_full_name]
        msg << "  %-20s : %s\n" % [action_full_name, action_info.desc]
      end
      msg << "\n"
      msg << "(Use `#{command} help <action>' to show help message of each action.)\n"
      return msg
    end

    private

    def parse_options(args, option_schemas)
      return OptionParser.new(option_schemas).parse_options(args)
    end

    def err(msg)
      return OptionError.new(msg)
    end

  end


  def self.main(argv=nil)
    Application.new.main(argv || ARGV)
  end


end
