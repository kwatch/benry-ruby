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
      @argflag  = argflag
      @desc     = desc
      @block = block
    end

    attr_reader :short, :long, :argname, :argflag, :desc, :block

    def arg_required?
      return @argname == :required
    end

    def arg_optional?
      return @argname == :optional
    end

    def arg_nothing?
      return @argname == nil
    end

    def canonical_name
      return @long || @short
    end

    def self.parse(defstr, desc)
      case defstr.strip()
      when /\A-(\w),\s*--(\w[-\w]*)(?:=(\S+)|\[=(\S+)\])?\z/ ; arr = [$1,  $2,  $3, $4]
      when /\A-(\w)(?:\s+(\S+)|\[(\S+)\])?\z/                ; arr = [$1,  nil, $2, $3]
      when /\A--(\w[-\w]*)(?:=(\S+)|\[=(\S+)\])?\z/          ; arr = [nil, $1,  $2, $3]
      else
        raise OptionDefinitionError.new("'#{defstr}': failed to parse option definition.")
      end
      short, long, arg_required, arg_optional = arr
      argname = arg_required || arg_optional
      argflag = arg_required ? :required \
              : arg_optional ? :optional : nil
      return self.new(short, long, argname, argflag, desc)
    end

    def option_string
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
      option_values = {}
      while args[0] && args[0].start_with?('-')
        argstr = args.shift
        if argstr == '--'
          break
        elsif argstr.start_with?('--')
          _parse_long_option(argstr, option_values)
        else
          _parse_short_option(argstr, option_values)
        end
      end
      return option_values
    end

    def _parse_long_option(argstr, option_values)
      argstr =~ /\A--(\w[-\w]*)(?:=(.*))?\z/
      long, value = $1, $2
      opt = @option_schemas.find {|x| x.long == long }  or
        raise err("--#{long}: unknown option.")
      if opt.arg_required?
        value  or
          raise err("#{argstr}: argument required.")
      elsif opt.arg_optional?
        value ||= true
      else
        value.nil?  or
          raise err("#{argstr}: unexpected argument.")
        value = true
      end
      value = opt.block.call(value) if opt.block
      option_values[opt.canonical_name] = value
    end

    def _parse_short_option(argstr, option_values)
      n = argstr.length
      i = 0
      while (i += 1) < n
        char = argstr[i]
        opt = @option_schemas.find {|x| x.short == char } or
          raise err("-#{char}: unknown option.")
        if opt.arg_required?
          value = argstr[(i+1)..-1]
          value = args.shift if value.empty?
          value  or
            raise err("-#{char}: argument required.")
          i = n
        elsif opt.arg_optional?
          value = argstr[(i+1)..-1]
          value = true if value.empty?
          i = n
        else
          value = true
        end
        value = opt.block.call(value) if opt.block
        option_values[opt.canonical_name] = value
      end
    end

  end


  class Action

    SUBCLASSES = []

    def self.inherited(subclass)
      subclass.class_eval do
        @__mappings = []
        @__defining = nil
        @action = proc do |action_name, desc|
          option_schemas = []
          option_schemas << OptionSchema.parse("-h, --help", "print help message")
          method_name    = nil
          @__defining = [action_name, desc, option_schemas, method_name]
        end
        @option = proc do |defstr, desc|
          @__defining  or
            raise ArgumentError.new("@option.(): @action is missing.")
          option_schemas = @__defining[2]
          option_schemas << OptionSchema.parse(defstr, desc)
        end
      end
      SUBCLASSES << subclass
    end

    def self.method_added(method_name)
      if @__defining
        @__defining[-1] = method_name
        @__mappings << @__defining
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

    def help_message(command)
      meth = @action_class.new.method(@action_method)
      argstr = ""
      meth.parameters.each do |kind, name|
        name_str = name.to_s.gsub('_', '-')
        case kind
        when :req ; argstr << " #{name_str}"
        when :opt ; argstr << " [#{name_str}]"
        end
      end
      msg = ""
      msg << "#{command} #{@full_name}  --  #{@desc}\n"
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


  GLOBAL_OPTIONS = {}


  class Application

    def self.extended(subclass=nil)
      subclass.class_eval do
        @option = proc do |defstr, desc, &block|
          option_schema = OptionSchema.parse(defstr, desc, &block)
          (@__gopt_schemas ||= []) << option_schema
        end
      end
    end

    def initialize(action_classes=nil, desc: nil)
      @action_dict = accept(action_classes || Action::SUBCLASSES)
      @desc = nil
    end

    attr_reader :desc

    private

    def accept(action_classes)
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
      global_option_schemas = self.class.instance_variable_get('@__gopt_schemas')
      if global_option_schemas
        GLOBAL_OPTIONS.clear()
        gopt_values = parse_options(args, global_option_schemas)
        GLOBAL_OPTIONS.update(gopt_values)
      end
      ## global help
      action_full_name = args.shift || "help"
      if action_full_name == "help"
        if args[0]
          return help_message_of_action(File.basename($0), args[0])
        else
          return help_message(File.basename($0))
        end
      end
      ## action and options
      action_info = @action_dict[action_full_name]  or
        raise err("#{action_full_name}: unknown action.")
      option_values = parse_options(args, action_info.option_schemas)
      ## show help
      if option_values['help']
        return action_info.help_message(File.basename($0))
      end
      ## validation
      obj = action_info.action_class.new()
      meth = obj.method(action_info.action_method)
      n_min = meth.parameters.count {|x| x[0] == :req }
      args.length >= n_min  or
        raise err("too few arguments (at least #{n_min} args expected).")
      n_max = meth.parameters.count {|x| x[0] == :req || x[0] == :opt }
      args.length <= n_max  or
        raise err("too many arguments (at most #{n_max} args expected).")
      ## do action
      kwargs = option_values
      has_kwargs = meth.parameters.any? {|x| x[0] == :key }
      if has_kwargs
        ret = meth.call(*args, kwargs)
      else
        ret = meth.call(*args)
      end
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
          print output
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

    def help_message(command)
      msg = ""
      if @desc
        msg << "#{command}  -- #{@desc}\n"
        msg << "\n"
      end
      msg << "Usage:\n"
      msg << "  #{command} [actions]\n"
      msg << "\n"
      msg << "Actions:\n"
      #msg << "  %-25s : %s\n" % ["help", "show this help"]
      @action_dict.keys.sort.each do |action_full_name|
        action_info = @action_dict[action_full_name]
        msg << "  %-25s : %s\n" % [action_full_name, action_info.desc]
      end
      msg << "\n"
      msg << "(Use `#{command} help <ACTION>' to show help message of each action.)\n"
      return msg
    end

    def help_message_of_action(command, action_name)
      action_info = @action_dict[action_name]  or
        raise err("#{action_name}: no such action.")
      return action_info.help_message(command)
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


if __FILE__ == $0

  class MainAction < Benry::CLI::Action

    @action.(:hello, "say hello")
    def hello(name='world')
      puts "Hello #{name}!"
    end

  end

  class GitAction < Benry::CLI::Action
    @prefix = :git

    def sys *args
      puts "$ " + args.join(' ')
      system *args  or
        raise "ERROR: command `#{args.join(' ')}` failed."
    end

    def sys! *args
      puts "$ " + args.join(' ')
      system *args
    end

    @action.(:fork, "create new branch")
    def do_fork(branch)
      sys 'git', 'checkout', '-b', branch
    end

    @action.(:merge, "merge branch with --no-ff option")
    def do_merge(branch)
      sys 'git', 'merge', '--no-ff', branch
    end

    @action.(:stage, "add changes into staging area")
    def do_stage(*filenames)
      system 'git', 'add', '-p', *filenames
    end

    @action.(:staged, "show changes in staging area")
    def do_staged()
      system 'git', 'diff', '--cached'
    end

    @action.(:unstage, "remove changes from staging area")
    def do_unstage(*filenames)
      system 'git', 'reset', 'HEAD', *filenames
    end

  end

  class MainApp < Benry::CLI::Application
  end

  MainApp.new.main()

end
