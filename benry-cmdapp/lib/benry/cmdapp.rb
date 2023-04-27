# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2023 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require 'benry/cmdopt'


module Benry::CmdApp


  SCHEMA_CLASS   = Benry::CmdOpt::Schema
  PARSER_CLASS   = Benry::CmdOpt::Parser
  OPTION_ERROR   = Benry::CmdOpt::OptionError


  class BaseError < StandardError; end

  class DefinitionError     < BaseError; end
  class ActionDefError      < DefinitionError; end
  class OptionDefError      < DefinitionError; end
  class AliasDefError       < DefinitionError; end

  class ExecutionError      < BaseError; end
  class CommandError        < ExecutionError; end
  class ActionNotFoundError < ExecutionError; end
  class LoopedActionError   < ExecutionError; end


  module Util
    module_function

    def hidden_name?(name)
      #; [!fcfic] returns true if name is '_foo'.
      #; [!po5co] returns true if name is '_foo:bar'.
      return true if name =~ /\A_/
      #; [!9iqz3] returns true if name is 'foo:_bar'.
      return true if name =~ /:_[-\w]*\z/
      #; [!mjjbg] returns false if else.
      return false
    end

    def schema_empty?(schema, all=false)
      #; [!8t5ju] returns true if schema empty.
      #; [!c4ljy] returns true if schema contains only private (hidden) options.
      schema.each {|item| return false if all || ! item.hidden? }
      return true
    end

    def method2action(name)
      #; [!801f9] converts action name 'aa_bb_cc_' into 'aa_bb_cc'.
      name = name.sub(/_+\z/, '')  # ex: 'aa_bb_cc_' => 'aa_bb_cc'
      #; [!9pahu] converts action name 'aa__bb__cc' into 'aa:bb:cc'.
      name = name.gsub(/__/, ':')  # ex: 'aa__bb__cc' => 'aa:bb:cc'
      #; [!7a1s7] converts action name 'aa_bb:_cc_dd' into 'aa-bb:_cc-dd'.
      name = name.gsub(/(?<=\w)_/, '-')   # ex: 'aa_bb:_cc_dd' => 'aa-bb:_cc-dd'
      return name
    end

    def colorize?()
      #; [!801y1] returns $COLOR_MODE value if it is not nil.
      return $COLOR_MODE if $COLOR_MODE != nil
      #; [!0harg] returns true if stdout is a tty.
      #; [!u1j1x] returns false if stdout is not a tty.
      return $stdout.tty?
    end

    def del_escape_seq(str)
      #; [!wgp2b] deletes escape sequence.
      return str.gsub(/\e\[.*?m/, '')
    end

    def alias_desc(action_name)
      return "alias of '#{action_name}' action"
    end

    class Doing    # :nodoc:
      def inspect(); "<DOING>"; end
      alias to_s inspect
    end

    DOING = Doing.new   # :nodoc:

  end


  class Index

    ACTIONS   = {}   # {action_name => ActionMetadata}
    ALIASES   = {}   # {alias_name  => action_name}
    DONE      = {}   # {action_name => Object}

    def self.lookup_action(name)
      #; [!vivoa] returns action metadata object.
      #; [!tnwq0] supports alias name.
      name = name.to_s
      name = ALIASES[name] if ALIASES[name]
      metadata = ACTIONS[name]
      return metadata
    end

    def self.each_action_name_and_desc(include_alias=true, all: false, &block)
      #; [!5lahm] yields action name and description.
      #; [!27j8b] includes alias names when the first arg is true.
      #; [!8xt8s] rejects hidden actions if 'all: false' kwarg specified.
      #; [!5h7s5] includes hidden actions if 'all: true' kwarg specified.
      #; [!arcia] action names are sorted.
      metadatas = ACTIONS.values()
      metadatas = metadatas.reject {|ameta| ameta.hidden? } if ! all
      pairs = metadatas.collect {|ameta| [ameta.name, ameta.desc] }
      pairs += ALIASES.collect {|ali, act| [ali, Util.alias_desc(act)] } if include_alias
      pairs.sort_by {|name, _| name }.each(&block)
    end

  end


  class ActionMetadata

    def initialize(name, klass, method, desc, schema, detail: nil, postamble: nil, tag: nil)
      @name   = name
      @klass  = klass
      @method = method
      @schema = schema
      @desc   = desc
      @detail = detail       if detail != nil
      @postamble = postamble if postamble != nil
      @tag    = tag          if tag != nil
    end

    attr_reader :name, :method, :klass, :schema, :desc, :detail, :postamble, :tag

    def hidden?()
      #; [!kp10p] returns true when action method is private.
      #; [!nw322] returns false when action method is not private.
      return ! @klass.method_defined?(@method)
    end

    def parse_options(argv, all=true)
      #; [!ab3j8] parses argv and returns options.
      return PARSER_CLASS.new(@schema).parse(argv, all)
    end

    def run_action(*args, **kwargs)
      if ! $TRACING_MODE
        _run_action(*args, **kwargs)
      else
        #; [!tubhv] if $TRACING_MODE is on, prints tracing info.
        #; [!zgp14] tracing info is colored when stdout is a tty.
        s = "## enter: #{@name}"
        s = "\e[33m#{s}\e[0m" if Util.colorize?
        puts s
        _run_action(*args, **kwargs)
        s = "## exit:  #{@name}"
        s = "\e[33m#{s}\e[0m" if Util.colorize?
        puts s
      end
      nil
    end

    def _run_action(*args, **kwargs)
      #; [!veass] runs action with args and kwargs.
      action_obj = @klass.new
      if kwargs.empty?                        # for Ruby < 2.7
        action_obj.__send__(@method, *args)   # for Ruby < 2.7
      else
        action_obj.__send__(@method, *args, **kwargs)
      end
    end

    def method_arity()
      #; [!7v4tp] returns min and max number of positional arguments.
      n_req = 0
      n_opt = 0
      has_rest = false
      @klass.instance_method(@method).parameters.each do |kind, _|
        case kind
        when :req     ; n_req += 1
        when :opt     ; n_opt += 1
        when :rest    ; has_rest = true
        when :key     ; nil
        when :keyrest ; nil
        else          ; nil
        end
      end
      #; [!w3rer] max is nil if variable argument exists.
      return has_rest ? [n_req, nil] : [n_req, n_req + n_opt]
    end

    def validate_method_params()
      #; [!plkhs] returns error message if keyword parameter for option not exist.
      #; [!1koi8] returns nil if all keyword parameters for option exist.
      kw_params = []
      method_obj = @klass.instance_method(@method)
      method_obj.parameters.each {|kind, param| kw_params << param if kind == :key }
      opt_keys = @schema.each.collect {|item| item.key }
      key = (opt_keys - kw_params).first
      return nil if key == nil
      return "should have keyword parameter '#{key}' for '@option.(#{key.inspect})', but not."
    end

    def help_message(command, all=false)
      #; [!i7siu] returns help message of action.
      builder = ACTION_HELP_MESSAGE_BUILDER_CLASS.new(self)
      return builder.build_help_message(command, all)
    end

  end


  class ActionHelpMessageBuilder

    def initialize(action_metadata)
      @am = action_metadata
    end

    def build_help_message(command, all=false)
      sb = []
      sb << build_preamble(command, all)
      sb << build_usage(command, all)
      sb << build_options(command, all)
      sb << build_postamble(command, all)
      return sb.reject {|x| x.nil? || x.empty? }.join("\n")
    end

    protected

    def build_preamble(command, all=false)
      #; [!pqoup] adds detail text into help if specified.
      sb = []
      sb << "#{command} #{@am.name} -- #{@am.desc}\n"
      if @am.detail
        sb << "\n"
        sb << @am.detail
        sb << "\n" unless @am.detail.end_with?("\n")
      end
      return sb.join()
    end

    def build_usage(command, all=false)
      config = $cmdapp_config
      format = config ? config.format_usage : Config::FORMAT_USAGE
      #; [!zbc4y] adds '[<options>]' into 'Usage:' section only when any options exist.
      #; [!8b02e] ignores '[<options>]' in 'Usage:' when only hidden options speicified.
      #; [!ou3md] not add extra whiespace when no arguments of command.
      s = build_argstr().strip()
      s = "[<options>] " + s unless Util.schema_empty?(@am.schema, all)
      s = s.rstrip()
      sb = []
      sb << "#{heading('Usage:')}\n"
      sb << (format % ["#{command} #{@am.name}", s]) << "\n"
      return sb.join()
    end

    def build_options(command, all=false)
      config = $cmdapp_config
      format = config ? config.format_help : Config::FORMAT_HELP
      format += "\n"
      #; [!g2ju5] adds 'Options:' section.
      #; [!pvu56] ignores 'Options:' section when no options exist.
      #; [!hghuj] ignores 'Options:' section when only hidden options speicified.
      sb = []
      @am.schema.each do |item|
        sb << format % [item.optdef, item.desc] if all || ! item.hidden?
      end
      return nil if sb.empty?
      return heading('Options:') + "\n" + sb.join()
    end

    def build_postamble(command, all=false)
      #; [!0p2gt] adds postamble text if specified.
      s = @am.postamble
      if s
        #; [!v5567] adds '\n' at end of preamble text if it doesn't end with '\n'.
        s += "\n" unless s.end_with?("\n")
      end
      return s
    end

    def heading(str)
      config = $cmdapp_config
      format = config ? config.format_heading : Config::FORMAT_HEADING
      return format % str
    end

    private

    def build_argstr()
      #; [!x0z89] required arg is represented as '<arg>'.
      #; [!md7ly] optional arg is represented as '[<arg>]'.
      #; [!xugkz] variable args are represented as '[<arg>...]'.
      method_obj = @am.klass.instance_method(@am.method)
      sb = []; n = 0
      method_obj.parameters.each do |kind, param|
        arg = param2arg(param)
        case kind
        when :req     ; sb <<  " <#{arg}>"
        when :opt     ; sb << " [<#{arg}>"    ; n += 1
        when :rest    ; sb << " [<#{arg}>..." ; n += 1
        when :key     ; nil
        when :keyrest ; nil
        else          ; nil
        end
      end
      sb << ("]" * n)
      return sb.join()
    end

    def param2arg(param)
      #; [!eou4h] converts arg name 'xx_or_yy_or_zz' into 'xx|yy|zz'.
      #; [!naoft] converts arg name '_xx_yy_zz' into '_xx-yy-zz'.
      s = param.to_s
      s = s.gsub(/_or_/, '|')          # ex: 'file_or_dir' => 'file|dir'
      s = s.gsub(/(?<=\w)_/, '-')      # ex: 'aa_bb_cc' => 'aa-bb-cc'
      return s
    end

  end


  ACTION_HELP_MESSAGE_BUILDER_CLASS = ActionHelpMessageBuilder


  class Action

    def run_action_once(action_name, *args, **kwargs)
      #; [!oh8dc] don't invoke action if already invoked.
      return __run_action(action_name, true, args, kwargs)
    end

    def run_action!(action_name, *args, **kwargs)
      #; [!2yrc2] invokes action even if already invoked.
      return __run_action(action_name, false, args, kwargs)
    end

    private

    def __run_action(action_name, once, args, kwargs)
      #; [!7vszf] raises error if action specified not found.
      metadata = Index.lookup_action(action_name)  or
        raise ActionNotFoundError.new("#{action_name}: action not found.")
      name = metadata.name
      #; [!u8mit] raises error if action flow is looped.
      if Index::DONE.key?(name)
        Index::DONE[name] != Util::DOING  or
          raise LoopedActionError.new("#{name}: looped action detected.")
        #; [!vhdo9] don't invoke action twice if 'once' arg is true.
        return Index::DONE[name] if once
      end
      #; [!r8fbn] invokes action.
      Index::DONE[name] = Util::DOING
      ret = metadata.run_action(*args, **kwargs)
      Index::DONE[name] = ret
      return ret
    end

    def self.prefix(str, alias_of: nil, default: nil)
      #; [!1gwyv] converts symbol into string.
      str = str.to_s
      #; [!pz46w] error if prefix contains extra '_'.
      str =~ /\A\w[-a-zA-Z0-9]*(:\w[-a-zA-Z0-9]*)*\z/  or
        raise ActionDefError.new("#{str}: invalid prefix name (please use ':' or '-' instead of '_' as word separator).")
      #; [!9pu01] adds ':' at end of prefix name if prefix not end with ':'.
      str += ':' unless str.end_with?(':')
      @__prefix__  = str
      @__aliasof__ = alias_of  # method name if symbol, or action name if string
      @__default__ = default   # method name if symbol, or action name if string
    end

    SUBCLASSES = []

    def self.inherited(subclass)
      #; [!f826w] registers all subclasses into 'Action::SUBCLASSES'.
      SUBCLASSES << subclass
      #; [!2imrb] sets class instance variables in subclass.
      subclass.instance_eval do
        @__action__   = nil    # ex: ["action desc", {detail: nil, postamble: nil}]
        @__option__   = nil    # Benry::CmdOpt::Schema object
        @__prefix__   = nil    # ex: "foo:bar:"
        @__aliasof__  = nil    # ex: :method_name or "action-name"
        @__default__  = nil    # ex: :method_name or "action-name"
        #; [!1qv12] @action is a Proc object and saves args.
        @action = proc do |desc, detail: nil, postamble: nil, tag: nil|
          @__action__ = [desc, {detail: detail, postamble: postamble, tag: tag}]
        end
        #; [!33ma7] @option is a Proc object and saves args.
        @option = proc do |param, optdef, desc, *rest, type: nil, rexp: nil, enum: nil, value: nil, tag: nil, &block|
          #; [!gxybo] '@option.()' raises error when '@action.()' not called.
          @__action__ != nil  or
            raise OptionDefError.new("@option.(#{param.inspect}): `@action.()` required but not called.")
          schema = (@__option__ ||= SCHEMA_CLASS.new)
          schema.add(param, optdef, desc, *rest, type: type, rexp: rexp, enum: enum, value: value, tag: nil, &block)
        end
        #; [!yrkxn] @copy_options is a Proc object and copies options from other action.
        @copy_options = proc do |action_name, except: nil|
          #; [!mhhn2] '@copy_options.()' raises error when action not found.
          metadata = Index::ACTIONS[action_name.to_s]  or
            raise OptionDefError.new("@copy_options.(#{action_name.inspect}): action not found.")
          @__option__ ||= SCHEMA_CLASS.new
          @__option__.copy_from(metadata.schema, except: except)
        end
      end
    end

    def self.method_added(method)
      #; [!idh1j] do nothing if '@__action__' is nil.
      return unless @__action__
      #; [!ernnb] clears both '@__action__' and '@__option__'.
      desc, kws = @__action__
      schema = @__option__ || SCHEMA_CLASS.new
      @__action__ = @__option__ = nil
      #; [!n8tem] creates ActionMetadata object if '@__action__' is not nil.
      name = __method2action(method)
      metadata = ActionMetadata.new(name, self, method, desc, schema, **kws)
      #; [!4pbsc] raises error if keyword param for option not exist in method.
      errmsg = metadata.validate_method_params()
      errmsg == nil  or
        raise ActionDefError.new("def #{method}(): #{errmsg}")
      Index::ACTIONS[name] = metadata
      #; [!jpzbi] defines same name alias of action as prefix.
      #; [!997gs] not raise error when action not found.
      self.__define_alias_of_action(method, name)
    end

    def self.__method2action(method)   # :nodoc:
      #; [!5e5o0] when method name is same as default action name...
      if method == @__default__      # when Symbol
        #; [!myj3p] uses prefix name (expect last char ':') as action name.
        @__prefix__ != nil  or raise "** assertion failed"
        name = @__prefix__.chomp(":")
        #; [!j5oto] clears '@__default__'.
        @__default__ = nil
      #; [!agpwh] else...
      else
        #; [!3icc4] uses method name as action name.
        #; [!c643b] converts action name 'aa_bb_cc_' into 'aa_bb_cc'.
        #; [!3fkb3] converts action name 'aa__bb__cc' into 'aa:bb:cc'.
        #; [!o9s9h] converts action name 'aa_bb:_cc_dd' into 'aa-bb:_cc-dd'.
        name = Util.method2action(method.to_s)
        #; [!8hlni] when action name is same as default name, uses prefix as action name.
        if name == @__default__      # when String
          name = @__prefix__.chomp(":")
          #; [!q8oxi] clears '@__default__' when default name matched to action name.
          @__default__ = nil
        #; [!xfent] when prefix is provided, adds it to action name.
        elsif @__prefix__
          name = "#{@__prefix__}#{name}"
        end
      end
      return name
    end

    def self.__define_alias_of_action(method, action_name)
      return if @__aliasof__ == nil
      @__prefix__ != nil  or raise "** internal error"
      alias_of = @__aliasof__
      if alias_of == method || alias_of == Util.method2action(method.to_s)
        alias_name = @__prefix__.chomp(":")
        #; [!349nr] raises error when same name action or alias with prefix already exists.
        Benry::CmdApp.action_alias(alias_name, action_name)
        #; [!tvjb0] clears '@__aliasof__' only when alias created.
        @__aliasof__ = nil
      end
    end

  end


  def self.action_alias(alias_name, action_name)
    invocation = "action_alias(#{alias_name.inspect}, #{action_name.inspect})"
    #; [!5immb] convers both alias name and action name into string.
    alias_  = alias_name.to_s
    action_ = action_name.to_s
    #; [!nrz3d] error if action not found.
    Index::ACTIONS[action_]  or
      raise AliasDefError.new("#{invocation}: action not found.")
    #; [!vvmwd] error when action with same name as alias exists.
    ! Index::ACTIONS[alias_]  or
      raise AliasDefError.new("#{invocation}: not allowed to define same name alias as existing action.")
    #; [!i9726] error if alias already defined.
    ! Index::ALIASES[alias_]  or
      raise AliasDefError.new("#{invocation}: alias name duplicated.")
    #; [!vzlrb] registers alias name with action name.
    Index::ALIASES[alias_] = action_
  end


  class Config  #< BasicObject

    #FORMAT_HELP      = "  %-18s : %s"
    FORMAT_HELP       = "  \e[1m%-18s\e[0m : %s"   # bold
    #FORMAT_HELP      = "  \e[34m%-18s\e[0m : %s"  # blue

    #FORMAT_USAGE     = "  $ %s %s"
    FORMAT_USAGE      = "  $ \e[1m%s\e[0m %s"      # bold
    #FORMAT_USAGE     = "  $ \e[34m%s\e[0m %s"     # blue

    #FORMAT_HEADING   = "%s"
    #FORMAT_HEADING   = "\e[1m%s\e[0m"             # bold
    #FORMAT_HEADING   = "\e[1;4m%s\e[0m"           # bold, underline
    FORMAT_HEADING    = "\e[34m%s\e[0m"            # blue
    #FORMAT_HEADING   = "\e[33;4m%s\e[0m"          # yellow, underline

    def initialize(app_desc, app_version=nil,
                   app_name: nil, app_command: nil, app_detail: nil,
                   default_action: nil, default_help: false,
                   option_help: true, option_all: false, option_debug: false,
                   option_verbose: false, option_quiet: false, option_color: false,
                   help_sections: [], help_postamble: nil,
                   format_help: nil, format_usage: nil, format_heading: nil)
      #; [!uve4e] sets command name automatically if not provided.
      @app_desc       = app_desc        # ex: "sample application"
      @app_version    = app_version     # ex: "1.0.0"
      @app_name       = app_name    || ::File.basename($0)   # ex: "MyApp"
      @app_command    = app_command || ::File.basename($0)   # ex: "myapp"
      @app_detail     = app_detail      # ex: "See https://.... for details.\n"
      @default_action = default_action  # default action name
      @default_help   = default_help    # print help message if action not specified
      @option_help    = option_help     # '-h' and '--help' are enabled when true
      @option_all     = option_all      # '-a' and '--all' are enable when true
      @option_verbose = option_verbose  # '-v' and '--verbose' are enabled when true
      @option_quiet   = option_quiet    # '-q' and '--quiet' are enabled when true
      @option_color   = option_color    # '--color[=<on|off>]' enabled when true
      @option_debug   = option_debug    # '-D' and '--debug' are enable when true
      @help_sections  = help_sections   # ex: [["Example", "..text.."], ...]
      @help_postamble = help_postamble  # ex: "(Tips: ....)\n"
      @format_help    = format_help    || FORMAT_HELP
      @format_usage   = format_usage   || FORMAT_USAGE
      @format_heading = format_heading || FORMAT_HEADING
    end

    attr_accessor :app_desc, :app_version, :app_name, :app_command, :app_detail
    attr_accessor :default_action, :default_help
    attr_accessor :option_help, :option_all, :option_debug
    attr_accessor :option_verbose, :option_quiet, :option_color
    attr_accessor :help_sections, :help_postamble
    attr_accessor :format_help, :format_usage, :format_heading

  end


  class GlobalOptionSchema < Benry::CmdOpt::Schema

    def self.create(config)
      c = config
      #; [!enuxy] creates schema object.
      schema = self.new
      #; [!tq2ol] adds '-h, --help' option if 'config.option_help' is set.
      schema.add(:help   , "-h, --help"   , "print help message (of action if action specified)") if c.option_help
      #; [!mbtw0] adds '-V, --version' option if 'config.app_version' is set.
      schema.add(:version, "-V, --version", "print version")      if c.app_version
      #; [!f5do6] adds '-a, --all' option if 'config.option_all' is set.
      schema.add(:all    , "-a, --all"    , "list all actions/options including private (hidden) ones") if c.option_all
      #; [!cracf] adds '-v, --verbose' option if 'config.option_verbose' is set.
      schema.add(:verbose, "-v, --verbose", "verbose mode") if c.option_verbose
      #; [!2vil6] adds '-q, --quiet' option if 'config.option_quiet' is set.
      schema.add(:quiet  , "-q, --quiet"  , "quiet mode") if c.option_quiet
      #; [!6zw3j] adds '--color=<on|off>' option if 'config.option_color' is set.
      schema.add(:color  , "--color[=<on|off>]", "enable/disable color", type: TrueClass) if c.option_color
      #; [!29wfy] adds '-D, --debug' option if 'config.option_debug' is set.
      schema.add(:debug  , "-D, --debug"  , "set $DEBUG_MODE to true") if c.option_debug
      return schema
    end

  end


  GLOBAL_OPTION_SCHEMA_CLASS = GlobalOptionSchema


  class Application

    def initialize(config, schema=nil, help_builder=nil, &callback)
      @config = config
      #; [!h786g] acceps callback block.
      @callback = callback
      #; [!jkprn] creates option schema object according to config.
      @schema = schema || do_create_global_option_schema(config)
      @help_builder = help_builder
      @global_options = nil
    end

    attr_reader :config, :schema, :help_builder, :callback

    def main(argv=ARGV)
      begin
        #; [!y6q9z] runs action with options.
        self.run(*argv)
      rescue ExecutionError, OPTION_ERROR => exc
        #; [!6ro6n] not catch error when $DEBUG_MODE is on.
        raise if $DEBUG_MODE
        #; [!a7d4w] prints error message with '[ERROR]' prompt.
        $stderr.puts "\033[0;31m[ERROR]\033[0m #{exc.message}"
        #loc = exc.backtrace_locations.find {|x| x.path !~ /\/benry\/cmd(app|opt)\.rb\z/ }
        #$stderr.puts "\t(file: #{loc.path}, line: #{loc.lineno})" if loc
        #; [!qk5q5] returns 1 as exit code when error occurred.
        return 1
      else
        #; [!5oypr] returns 0 as exit code when no errors occurred.
        return 0
      end
    end

    def run(*args)
      #; [!t4ypg] sets $cmdapp_config at beginning.
      do_setup()
      #; [!pyotc] sets global options to '@global_options'.
      @global_options = do_parse_global_options(args)
      #; [!5iczl] skip actions if help option or version option specified.
      result = do_handle_global_options(args)
      return if result == :SKIP
      #; [!w584g] calls callback method.
      #; [!pbug7] skip actions if callback method returns `:SKIP` value.
      result = do_callback(args)
      return if result == :SKIP
      #; [!avxos] prints candidate actions if action name ends with ':'.
      if ! args.empty? && args[0].end_with?(':')
        do_print_candidates(args)
        return
      end
      #; [!agfdi] reports error when action not found.
      #; [!o5i3w] reports error when default action not found.
      #; [!n60o0] reports error when action nor default action not specified.
      #; [!7h0ku] prints help if no action but 'config.default_help' is true.
      #; [!l0g1l] skip actions if no action specified and 'config.default_help' is set.
      metadata = do_find_action(args)
      if metadata == nil
        do_print_help_message([])
        do_validate_actions()
        return
      end
      #; [!x1xgc] run action with options and arguments.
      #; [!v5k56] runs default action if action not specified.
      do_run_action(metadata, args)
    rescue => exc
      raise
    ensure
      #; [!hk6iu] unsets $cmdapp_config at end.
      #; [!wv22u] calls teardown method at end of running action.
      #; [!dhba4] calls teardown method even if exception raised.
      do_teardown(exc)
    end

    protected

    def do_create_global_option_schema(config)
      #; [!u3zdg] creates global option schema object according to config.
      return GLOBAL_OPTION_SCHEMA_CLASS.create(config)
    end

    def do_create_help_message_builder(config, schema)
      #; [!pk5da] creates help message builder object.
      return COMMAND_HELP_MESSAGE_BUILDER_CLASS.new(config, schema)
    end

    def do_parse_global_options(args)
      #; [!5br6t] parses only global options and not parse action options.
      parser = PARSER_CLASS.new(@schema)
      global_opts = parser.parse(args, false)
      return global_opts
    end

    def do_handle_global_options(args)
      global_opts = @global_options
      #; [!j6u5x] sets $VERBOSE_MODE to true if '-v' or '--verbose' specified.
      #; [!p1l1i] sets $QUIET_MODE to true if '-q' or '--quiet' specified.
      #; [!2zvf9] sets $COLOR_MODE to true/false according to '--color' option.
      #; [!ywl1a] sets $DEBUG_MODE to true if '-D' or '--debug' specified.
      [:verbose, :quiet, :color, :debug].each do |key|
        do_set_global_switch(key, global_opts[key])
        ## not return
      end
      #; [!xvj6s] prints help message if '-h' or '--help' specified.
      if global_opts[:help]
        #; [!lpoz7] prints help message of action if action name specified with help option.
        do_print_help_message(args)
        do_validate_actions()
        return :SKIP
      end
      #; [!fslsy] prints version if '-V' or '--version' specified.
      if global_opts[:version]
        puts @config.app_version
        return :SKIP
      end
      #
      return nil
    end

    def do_set_global_switch(key, val)
      #; [!go9kk] sets global variable according to key.
      case key
      when :quiet   ; $QUIET_MODE   = val
      when :verbose ; $VERBOSE_MODE = val
      when :color   ; $COLOR_MODE   = val
      when :debug   ; $DEBUG_MODE   = val   # or $DEBUG = val
      else          ; # do nothing
      end
    end

    def do_callback(args)
      #; [!xwo0v] calls callback if provided.
      #; [!lljs1] calls callback only once.
      if @callback && ! @__called
        @__called = true
        @callback.call(args, @global_options, @config)
      end
    end

    def do_find_action(args)
      c = @config
      #; [!bm8np] returns action metadata.
      if ! args.empty?
        action_name = args.shift()
        #; [!vl0zr] error when action not found.
        metadata = Index.lookup_action(action_name)  or
          raise CommandError.new("#{action_name}: unknown action.")
      #; [!gucj7] if no action specified, finds default action instead.
      elsif c.default_action
        action_name = c.default_action
        #; [!388rs] error when default action not found.
        metadata = Index.lookup_action(action_name)  or
          raise CommandError.new("#{action_name}: unknown default action.")
      #; [!drmls] returns nil if no action specified but 'config.default_help' is set.
      elsif c.default_help
        #do_print_help_message([])
        return nil
      #; [!hs589] error when action nor default action not specified.
      else
        raise CommandError.new("#{c.app_command}: action name required (run `#{c.app_command} -h` for details).")
      end
      return metadata
    end

    def do_run_action(metadata, args)
      action_name = metadata.name
      #; [!62gv9] parses action options even if specified after args.
      options = metadata.parse_options(args, true)
      #; [!6mlol] error if action requries argument but nothing specified.
      #; [!72jla] error if action requires N args but specified less than N args.
      #; [!zawxe] error if action requires N args but specified over than N args.
      #; [!y97o3] action can take any much args if action has variable arg.
      min, max = metadata.method_arity()
      n = args.length
      if n < min
        raise CommandError.new("#{action_name}: argument required.") if n == 0
        raise CommandError.new("#{action_name}: too less arguments (at least #{min}).")
      elsif max && max < n
        raise CommandError.new("#{action_name}: too much arguments (at most #{max}).")
      end
      #; [!cf45e] runs action with arguments and options.
      #; [!tsal4] detects looped action.
      Index::DONE[action_name] = Util::DOING
      ret = metadata.run_action(*args, **options)
      Index::DONE[action_name] = ret
      return ret
    end

    def do_print_help_message(args)
      #; [!4qs7y] shows private (hidden) actions/options if '--all' option specified.
      #; [!l4d6n] `all` flag should be true or false, not nil.
      all = !! @global_options[:all]
      #; [!eabis] prints help message of action if action name provided.
      action_name = args[0]
      if action_name
        #; [!cgxkb] error if action for help option not found.
        metadata = Index.lookup_action(action_name)  or
          raise CommandError.new("#{action_name}: action not found.")
        msg = metadata.help_message(@config.app_command, all)
      #; [!nv0x3] prints help message of command if action name not provided.
      else
        msg = help_message(all)
      end
      #; [!efaws] prints colorized help message when stdout is a tty.
      #; [!9vdy1] prints non-colorized help message when stdout is not a tty.
      #; [!gsdcu] prints colorized help message when '--color[=on]' specified.
      #; [!be8y2] prints non-colorized help message when '--color=off' specified.
      msg = Util.del_escape_seq(msg) unless Util.colorize?
      puts msg
    end

    def do_validate_actions()
      #; [!6xhvt] reports warning at end of help message.
      nl = "\n"
      Action::SUBCLASSES.each do |klass|
        #; [!iy241] reports warning if `alias_of:` specified in action class but corresponding action not exist.
        alias_of = klass.instance_variable_get(:@__aliasof__)
        if alias_of
          warn "#{nl}** [warning] in '#{klass.name}' class, `alias_of: #{alias_of.inspect}` specified but corresponding action not exist."
          nl = ""
        end
        #; [!h7lon] reports warning if `default:` specified in action class but corresponding action not exist.
        default = klass.instance_variable_get(:@__default__)
        if default
          warn "#{nl}** [warning] in '#{klass.name}' class, `default: #{default.inspect}` specified but corresponding action not exist."
          nl = ""
        end
      end
    end

    def do_print_candidates(args)
      #; [!0e8vt] prints candidate action names including prefix name without tailing ':'.
      prefix  = args[0]
      prefix2 = prefix.chomp(':')
      pairs = []
      aname2aliases = {}
      Index::ACTIONS.each do |aname, ameta|
        next unless aname.start_with?(prefix) || aname == prefix2
        #; [!k3lw0] private (hidden) action should not be printed as candidates.
        next if ameta.hidden?
        #
        pairs << [aname, ameta.desc]
        aname2aliases[aname] = []
      end
      #; [!85i5m] candidate actions should include alias names.
      Index::ALIASES.each do |alias_, aname|
        next unless alias_.start_with?(prefix) || alias_ == prefix2
        pairs << [alias_, Util.alias_desc(aname)]
      end
      #; [!i2azi] raises error when no candidate actions found.
      ! pairs.empty?  or
        raise CommandError.new("No actions starting with '#{prefix}'.")
      Index::ALIASES.each do |alias_, aname|
        aname2aliases[aname] << alias_ if aname2aliases.key?(aname)
      end
      sb = []
      sb << @config.format_heading % "Actions:" << "\n"
      format = @config.format_help
      indent = " " * (Util.del_escape_seq(format) % ['', '']).length
      pairs.sort_by {|aname, _| aname }.each do |aname, adesc|
        sb << format % [aname, adesc] << "\n"
        aliases = aname2aliases[aname]
        if aliases && ! aliases.empty?
          sb << indent << "(alias: " << aliases.join(", ") << ")\n"
        end
      end
      s = sb.join()
      s = Util.del_escape_seq(s) unless Util.colorize?
      puts s
    end

    def do_setup()
      #; [!pkio4] sets config object to '$cmdapp_config'.
      $cmdapp_config = @config
    end

    def do_teardown(exc)
      #; [!zxeo7] clears '$cmdapp_config'.
      $cmdapp_config = nil
    end

    public

    def help_message(all=false, format=nil)
      #; [!owg9y] returns help message.
      @help_builder ||= do_create_help_message_builder(@config, @schema)
      return @help_builder.build_help_message(all, format)
    end

  end


  class CommandHelpMessageBuilder

    def initialize(config, schema)
      @config = config
      @schema = schema
    end

    def build_help_message(all=false, format=nil)
      #; [!rvpdb] returns help message.
      format ||= @config.format_help
      sb = []
      sb << build_preamble(all)
      sb << build_usage(all)
      sb << build_options(all, format)
      sb << build_actions(all, format)
      #sb << build_aliases(all, format)
      @config.help_sections.each do |title, content|
        sb << build_section(title, content, all)
      end if @config.help_sections
      sb << build_postamble(all)
      return sb.reject {|s| s.nil? || s.empty? }.join("\n")
    end

    protected

    def build_preamble(all=false)
      #; [!34y8e] includes application name specified by config.
      #; [!744lx] includes application description specified by config.
      #; [!d1xz4] includes version number if specified by config.
      c = @config
      sb = []
      if c.app_desc
        v = c.app_version ? " (#{c.app_version})" : ""
        sb << "#{c.app_name}#{v} -- #{c.app_desc}\n"
      end
      #; [!775jb] includes detail text if specified by config.
      #; [!t3tbi] adds '\n' before detail text only when app desc specified.
      if c.app_detail
        sb << "\n" unless sb.empty?
        sb << c.app_detail
        sb << "\n" unless c.app_detail.end_with?("\n")
      end
      #; [!rvhzd] no preamble when neigher app desc nor detail specified.
      return nil if sb.empty?
      return sb.join()
    end

    def build_usage(all=false)
      c = @config
      format = c.format_usage
      #; [!o176w] includes command name specified by config.
      sb = []
      sb << "#{heading('Usage:')}\n"
      sb << (format % [c.app_command, "[<options>] [<action> [<arguments>...]]"]) << "\n"
      return sb.join()
    end

    def build_options(all=false, format=nil)
      format ||= @config.format_help
      format += "\n"
      #; [!in3kf] ignores private (hidden) options.
      #; [!ywarr] not ignore private (hidden) options if 'all' flag is true.
      sb = []
      @schema.each do |item|
        sb << format % [item.optdef, item.desc] if all || ! item.hidden?
      end
      #; [!bm71g] ignores 'Options:' section if no options exist.
      return nil if sb.empty?
      #; [!proa4] includes description of global options.
      return heading('Options:') + "\n" + sb.join()
    end

    def build_actions(all=false, format=nil)
      c = @config
      format ||= c.format_help
      format += "\n"
      sb = []
      sb << heading("Actions:")
      #; [!df13s] includes default action name if specified by config.
      sb << " (default: #{c.default_action})" if c.default_action
      sb << "\n"
      #; [!jat15] includes action names ordered by name.
      include_alias = true
      Index.each_action_name_and_desc(include_alias, all: all) do |name, desc|
        #; [!b3l3m] not show private (hidden) action names in default.
        #; [!yigf3] shows private (hidden) action names if 'all' flag is true.
        sb << format % [name, desc] if all || ! Util.hidden_name?(name)
      end
      return sb.join()
    end

    def build_section(title, content, all=false)
      #; [!cfijh] includes section title and content if specified by config.
      sb = []
      sb << heading(title) << "\n"
      sb << content
      sb << "\n" unless content.end_with?("\n")
      return sb.join()
    end

    def build_postamble(all=false)
      #; [!i04hh] includes postamble text if specified by config.
      s = @config.help_postamble
      if s
        #; [!ckagw] adds '\n' at end of postamble text if it doesn't end with '\n'.
        s += "\n" unless s.end_with?("\n")
      end
      return s
    end

    def heading(str)
      return @config.format_heading % str
    end

  end


  COMMAND_HELP_MESSAGE_BUILDER_CLASS = CommandHelpMessageBuilder


end
