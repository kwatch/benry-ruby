# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2023 kwatch@gmail.com $
### $License: MIT License $
###

require 'benry/cmdopt'


module Benry::CmdApp


  $VERBOSE_MODE = nil    # true when global option '-v, --verbose' specified
  $QUIET_MODE   = nil    # true when global option '-q, --quiet' specified
  $COLOR_MODE   = nil    # true when global option '--color' specified
  $DEBUG_MODE   = nil    # true when global option '--debug' specified
  #$TRACE_MODE  = nil    # use `@config.trace_mode?` instead.
  $DRYRUN_MODE  = nil    # true when global option '-X, --dryrun' specified


  class BaseError < StandardError
    def should_report_backtrace?()
      #; [!oj9x3] returns true in base exception class to report backtrace.
      return true
    end
  end

  class DefinitionError < BaseError
  end

  class ExecutionError < BaseError
  end

  class ActionError < ExecutionError
  end

  class OptionError < ExecutionError
    def should_report_backtrace?()
      #; [!6qvnc] returns false in OptionError class because no need to report backtrace.
      return false
    end
  end

  class CommandError < ExecutionError
    def should_report_backtrace?()
      #; [!o9xu2] returns false in ComamndError class because no need to report backtrace.
      return false
    end
  end


  module Util
    module_function

    def method2action(meth)
      #; [!bt77a] converts method name (Symbol) to action name (String).
      #; [!o5822] converts `:foo_` into `'foo'`.
      #; [!msgjc] converts `:aa__bb____cc` into `'aa:bb:cc'`.
      #; [!qmkfv] converts `:aa_bb_cc` into `'aa-bb-cc'`.
      #; [!tvczb] converts `:_aa_bb:_cc_dd:_ee` into `'_aa-bb:_cc-dd:_ee'`.
      s = meth.to_s                # ex: :foo            => "foo"
      s = s.sub(/_+\z/, '')        # ex: "foo_"          => "foo"
      s = s.gsub(/(__)+/, ':')     # ex: "aa__bb__cc"    => "aa:bb:cc"
      s = s.gsub(/(?<=\w)_/, '-')  # ex: '_aa_bb:_cc_dd' => '_aa-bb:_cc-dd'
      return s
    end

    def method2help(obj, meth)
      #; [!q3y3a] returns command argument string which represents method parameters.
      #; [!r6u58] converts `.foo(x)` into `' <x>'`.
      #; [!8be14] converts `.foo(x=0)` into `' [<x>]'`.
      #; [!skofc] converts `.foo(*x)` into `' [<x>...]'`.
      #; [!61xy6] converts `.foo(x, y=0, *z)` into `' <x> [<y> [<z>...]]'`.
      #; [!0342t] ignores keyword parameters.
      sb = []; n = 0
      obj.method(meth).parameters.each do |kind, param|
        case kind
        when :req  ; sb << " <#{param2arg(param)}>"
        when :opt  ; sb << " [<#{param2arg(param)}>"     ; n += 1
        when :rest ; sb << " [<#{param2arg(param)}>...]"
        when :key
        when :keyreq
        when :keyrest
        else
          raise "** assertion failed: kind=#{kind.inspect}"
        end
      end
      sb << ("]" * n) if n > 0
      #; [!mbxy5] converts `.foo(x, *x_)` into `' <x>...'`.
      #; [!mh9ni] converts `.foo(x, *x2)` into `' <x>...'`.
      return sb.join().sub(/<([^>]+)> \[<\1[-_2]?>\.\.\.\]/, "<\\1>...")
    end

    def param2arg(param)
      #; [!ahvsn] converts parameter name (Symbol) into argument name (String).
      #; [!27dpw] converts `:aa_or_bb_or_cc` into `'aa|bb|cc'`.
      #; [!to41h] converts `:aa__bb__cc` into `'aa.bb.cc'`.
      #; [!cldax] converts `:aa_` into `'aa'`.
      #; [!2ma08] converts `:aa_bb_cc` into `'aa-bb-cc'`.
      #; [!5d0qf] lefts `:_aa` as `'_aa'`.
      s = param.to_s
      s = s.gsub('_or_', '|')    # ex: 'file_or_dir' => 'file|dir'
      s = s.gsub('__'  , '.')    # ex: 'file__html'  => 'file.html'
      s = s.gsub(/_+\z/, '')     # ex: 'end_'        => 'end'
      s = s.gsub('_'   , '-')    # ex: 'foo_bar_baz' => 'foo-bar-baz'
      s = s.gsub(/\A-/ , '_')    # ex: '-aa'         => '_aa'
      return s
    end

    def validate_args_and_kwargs(obj, meth, args, kwargs)
      n_req = 0; n_opt = 0; rest_p = false; keyrest_p = false
      kws = kwargs.dup
      obj.method(meth).parameters.each do |kind, param|
        case kind
        when :req     ; n_req += 1           # ex: f(x)
        when :opt     ; n_opt += 1           # ex: f(x=0)
        when :rest    ; rest_p = true        # ex: f(*x)
        when :key     ; kws.delete(param)    # ex: f(x: 0)
        when :keyreq  ; kws.delete(param)    # ex: f(x:)
        when :keyrest ; keyrest_p = true     # ex: f(**x)
        else
          raise "** assertion failed: kind=#{kind.inspect}"
        end
      end
      #; [!jalnr] returns error message if argument required but no args specified.
      #; [!gv6ow] returns error message if too less arguments.
      if args.length < n_req
        return (args.length == 0) \
               ? "Argument required (but nothing specified)." \
               : "Too less arguments (at least #{n_req} args)."
      end
      #; [!q5rp3] returns error message if argument specified but no args expected.
      #; [!dewkt] returns error message if too much arguments specified.
      if args.length > n_req + n_opt && ! rest_p
        return (n_req + n_opt == 0) \
               ? "#{args[0].inspect}: Unexpected argument (expected no args)." \
               : "Too much arguments (at most #{n_req + n_opt} args)."
      end
      #; [!u7wgm] returns error message if unknown keyword argument specified.
      if ! kws.empty? && ! keyrest_p
        return "#{kws.keys.first}: Unknown keyword argument."
      end
      #; [!2ep76] returns nil if no error found.
      return nil
    end

    def delete_escape_chars(str)
      #; [!snl3e] removes escape chars from string.
      return str.gsub(/\e\[.*?m/, '')
    end

    def color_mode?()
      #; [!xyta1] returns value of $COLOR_MODE if it is not nil.
      #; [!8xufh] returns value of $stdout.tty? if $COLOR_MODE is nil.
      return $COLOR_MODE != nil ? $COLOR_MODE : $stdout.tty?
    end

    def method_override?(klass, meth)  # :nodoc:
      #; [!ldd1x] returns true if method defined in parent or ancestor classes.
      klass.ancestors[1..-1].each do |cls|
        if cls.method_defined?(meth) || cls.private_method_defined?(meth)
          return true
        end
        break if cls.is_a?(Class)
      end
      #; [!bc65v] returns false if meethod not defined in parent nor ancestor classes.
      return false
    end

    def name_should_be_a_string(name, kind, errcls)
      #; [!9j4d0] do nothing if name is a string.
      #; [!a2n8y] raises error if name is not a string.
      name.is_a?(String)  or
        raise errcls.new("`#{name.inspect}`: #{kind} name should be a string, but got #{name.class.name} object.")
      nil
    end

  end


  class OptionSchema < Benry::CmdOpt::Schema
  end


  class ActionOptionSchema < OptionSchema
  end


  class OptionParser < Benry::CmdOpt::Parser

    def parse(args, all: true)
      #; [!iaawe] raises OptionError if option error found.
      return super
    rescue Benry::CmdOpt::OptionError => exc
      raise OptionError.new(exc.message)
    end

  end


  ACTION_OPTION_SCHEMA_CLASS = ActionOptionSchema
  ACTION_OPTION_PARSER_CLASS = OptionParser
  ACTION_SHARED_OPTIONS      = proc {|dummy_schema|
    arr = []
    arr << dummy_schema.add(:help, "-h, --help", "print help message", hidden: true)#.freeze
    arr
  }.call(OptionSchema.new)


  class OptionSet

    def initialize(*items)
      @items = items
    end

    def copy_from(schema)
      #; [!d9udc] copy option items from schema.
      schema.each {|item| @items << item }
      #; [!v1ok3] returns self.
      self
    end

    def copy_into(schema)
      #; [!n00r1] copy option items into schema.
      @items.each {|item| schema.add_item(item) }
      #; [!ynn1m] returns self.
      self
    end

    def select(*keys)
      #; [!mqkzf] creates new OptionSet object with filtered options.
      items = @items.select {|item| keys.include?(item.key) }
      return self.class.new(*items)
    end

    def exclude(*keys)
      #; [!oey0q] creates new OptionSet object with remained options.
      items = @items.select {|item| ! keys.include?(item.key) }
      return self.class.new(*items)
    end

  end


  class BaseMetadata

    def initialize(name, desc, tag: nil, important: nil, hidden: nil)
      @name      = name
      @desc      = desc
      @tag       = tag        if nil != tag
      @important = important  if nil != important
      @hidden    = hidden     if nil != hidden
    end

    attr_reader :name, :desc, :tag, :important, :hidden
    alias important? important
    alias hidden? hidden

    def alias?()
      raise NotImplementedError.new("#{self.class.name}#alias?(): not implemented yet.")
    end

  end


  class ActionMetadata < BaseMetadata

    def initialize(name, desc, schema, klass, meth, usage: nil, detail: nil, description: nil, postamble: nil, tag: nil, important: nil, hidden: nil)
      super(name, desc, tag: tag, important: important, hidden: hidden)
      @schema    = schema
      @klass     = klass
      @meth      = meth
      @usage     = usage       if nil != usage
      @detail    = detail      if nil != detail
      @description = description if nil != description
      @postamble = postamble   if nil != postamble
    end

    attr_reader :schema, :klass, :meth, :usage, :detail, :description, :postamble

    def hidden?()
      #; [!stied] returns true/false if `hidden:` kwarg provided.
      #; [!eumhz] returns true/false if method is private or not.
      return @hidden if @hidden != nil
      return ! @klass.method_defined?(@meth)
    end

    def option_empty?(all: false)
      #; [!14xgg] returns true if the action has no options.
      #; [!dbtht] returns false if the action has at least one option.
      #; [!wa315] considers hidden options if `all: true` passed.
      return @schema.empty?(all: all)
    end

    def option_help(format, all: false)
      #; [!bpkwn] returns help message string of the action.
      #; [!76hni] includes hidden options in help message if `all:` is truthy.
      return @schema.option_help(format, all: all)
    end

    def parse_options(args)
      #; [!gilca] returns parsed options.
      #; [!v34yk] raises OptionError if option has error.
      parser = ACTION_OPTION_PARSER_CLASS.new(@schema)
      return parser.parse(args, all: true)  # raises error if invalid option given
    end

    def alias?()
      #; [!c1eq3] returns false which means that this is not an alias metadata.
      return false
    end

  end


  class AliasMetadata < BaseMetadata

    def initialize(alias_name, action_name, args, tag: nil, important: nil, hidden: nil)
      #; [!qtb61] sets description string automatically.
      #; [!kgic6] includes args value into description if provided.
      desc = _build_desc(action_name, args)
      super(alias_name, desc, tag: tag, important: important, hidden: hidden)
      @action = action_name
      @args   = args
    end

    attr_reader :action, :args

    def _build_desc(action_name, args)
      return args && ! args.empty? ? "alias for '#{action_name} #{args.join(' ')}'" \
                                   : "alias for '#{action_name}'"
    end
    private :_build_desc

    def alias?()
      #; [!c798o] returns true which means that this is an alias metadata.
      return true
    end

    def name_with_args()
      #; [!6kjuv] returns alias name if no args.
      return @name if ! @args || @args.empty?
      #; [!d4xrb] returns alias name and args as combined.
      return "#{@name} (with '#{@args.join(' ')}')"
    end

  end


  module ClassMethodModule

    def define_alias(alias_name, action_name, tag: nil, important: nil, hidden: nil)
      return __define_alias(alias_name, action_name, tag: tag, important: important, hidden: hidden, alias_for_alias: false)
    end

    def define_alias!(alias_name, action_name, tag: nil, important: nil, hidden: nil)  # :nodoc:
      return __define_alias(alias_name, action_name, tag: tag, important: important, hidden: hidden, alias_for_alias: true)
    end

    def __define_alias(alias_name, action_name, tag: nil, important: nil, hidden: nil, alias_for_alias: false)  # :nodoc:
      #; [!zawcd] action arg can be a string or an array of string.
      action_arg = action_name
      if action_arg.is_a?(Array)
        action_name, *args = action_arg
      else
        args = []
      end
      #; [!hqc27] raises DefinitionError if something error exists in alias or action.
      errmsg = __validate_alias_and_action(alias_name, action_name, alias_for_alias)
      errmsg == nil  or
        raise DefinitionError.new("define_alias(#{alias_name.inspect}, #{action_arg.inspect}): #{errmsg}")
      #; [!oo91b] registers new metadata of alias.
      alias_metadata = AliasMetadata.new(alias_name, action_name, args, tag: tag, important: important, hidden: hidden)
      REGISTRY.metadata_add(alias_metadata)
      #; [!wfbqu] returns alias metadata.
      return alias_metadata
    end
    private :__define_alias

    def __validate_alias_and_action(alias_name, action_name, alias_for_alias=false)  # :nodoc:
      #; [!2x1ew] returns error message if alias name is not a string.
      #; [!galce] returns error message if action name is not a string.
      if ! alias_name.is_a?(String)
        return "Alias name should be a string, but got #{alias_name.class.name} object."
      elsif ! action_name.is_a?(String)
        return "Action name should be a string, but got #{action_name.class.name} object."
      end
      #; [!zh0a9] returns error message if other alias already exists.
      #; [!ohow0] returns error message if other action exists with the same name as alias.
      alias_md = REGISTRY.metadata_get(alias_name)
      if    alias_md == nil  ; nil   # ok: new alias should be not defined
      elsif alias_md.alias?  ; return "Alias '#{alias_name}' already defined."
      else                   ; return "Can't define new alias '#{alias_name}' because already defined as an action."
      end
      #; [!r24qn] returns error message if action doesn't exist.
      #; [!lxolh] returns error message if action is an alias name.
      action_md = REGISTRY.metadata_get(action_name)
      if    action_md == nil ; return "Action '#{action_name}' not found."
      elsif alias_for_alias  ; nil   # ok: alias for alias is allowed
      elsif action_md.alias? ; return "'#{action_name}' should be an action, but is an alias."
      else                   ; nil   # ok: action should be defined
      end
      #; [!b6my2] returns nil if no errors found.
      return nil
    end
    private :__validate_alias_and_action

    def undef_alias(alias_name)
      #; [!pk3ya] raises DefinitionError if alias name is not a string.
      Util.name_should_be_a_string(alias_name, 'Alias', DefinitionError)
      #; [!krdkt] raises DefinitionError if alias not exist.
      #; [!juykx] raises DefinitionError if action specified instead of alias.
      md = REGISTRY.metadata_get(alias_name)
      errmsg = (
        if    md == nil ; "Alias not exist."
        elsif md.alias? ; nil
        else            ; "Alias expected but action name specified."
        end
      )
      errmsg == nil  or
        raise DefinitionError.new("undef_alias(#{alias_name.inspect}): #{errmsg}")
      #; [!ocyso] deletes existing alias.
      REGISTRY.metadata_del(alias_name)
      nil
    end

    def undef_action(action_name)
      #; [!bcyn3] raises DefinitionError if action name is not a string.
      Util.name_should_be_a_string(action_name, 'Action', DefinitionError)
      #; [!bvu95] raises error if action not exist.
      #; [!717fw] raises error if alias specified instead of action.
      md = REGISTRY.metadata_get(action_name)
      errmsg = (
        if    md == nil ; "Action not exist."
        elsif md.alias? ; "Action expected but alias name specified."
        else            ; nil
        end
      )
      errmsg == nil  or
        raise DefinitionError.new("undef_action(#{action_name.inspect}): #{errmsg}")
      #; [!01sx1] deletes existing action.
      REGISTRY.metadata_del(action_name)
      #; [!op8z5] deletes action method from action class.
      md.klass.class_eval { remove_method(md.meth) }
      nil
    end

    def define_abbrev(abbrev, prefix)
      #; [!e1fob] raises DefinitionError if error found.
      errmsg = __validate_abbrev(abbrev, prefix)
      errmsg == nil  or
        raise DefinitionError.new(errmsg)
      #; [!ed6hr] registers abbrev with prefix.
      REGISTRY.abbrev_add(abbrev, prefix)
      nil
    end

    def __validate_abbrev(abbrev, prefix, _registry: REGISTRY)  # :nodoc:
      #; [!qfzbp] abbrev should be a string.
      abbrev.is_a?(String)            or return "#{abbrev.inspect}: Abbreviation should be a string, but got #{abbrev.class.name} object."
      #; [!f5isx] abbrev should end with ':'.
      abbrev.end_with?(":")           or return "'#{abbrev}': Abbreviation should end with ':'."
      #; [!r673p] abbrev should not contain unexpected symbol.
      abbrev =~ /\A\w[-\w]*:/         or return "'#{abbrev}': Invalid abbreviation."
      #; [!dckvt] abbrev should not exist.
      ! _registry.abbrev_exist?(abbrev)  or return "'#{abbrev}': Abbreviation is already defined."
      #; [!5djjt] abbrev should not be the same name with existing prefix.
      ! _registry.category_exist?(abbrev)  or return "'#{abbrev}': Abbreviation is not available because a prefix with the same name already exists."
      #; [!mq4ki] prefix should be a string.
      prefix.is_a?(String)            or return "#{prefix.inspect}: Prefix should be a string, but got #{prefix.class.name} object."
      #; [!a82z3] prefix should end with ':'.
      prefix.end_with?(":")           or return "'#{prefix}': Prefix should end with ':'."
      #; [!eq5iu] prefix should exist.
      _registry.category_exist?(prefix)    or return "'#{prefix}': No such prefix."
      #; [!jzkhc] returns nil if no error found.
      return nil
    end
    private :__validate_abbrev

    def current_app()   # :nodoc:
      #; [!xdjce] returns current application.
      return @current_app
    end

    def _set_current_app(app)   # :nodoc:
      #; [!1yqwl] sets current application.
      @current_app = app
      nil
    end

  end
  extend ClassMethodModule


  class ActionScope

    def initialize(config, context=nil)
      @config      = config
      @__context__ = context || CONTEXT_CLASS.new(config)
    end

    def __clear_recursive_reference()  # :nodoc:
      #; [!i68z0] clears instance var which refers context object.
      @__context__ = nil
      nil
    end

    def inspect()
      return super.split().first() + ">"
    end

    def self.inherited(subclass)
      subclass.class_eval do
        @__actiondef__ = nil
        @__prefixdef__ = nil
        #; [!8cck9] sets Proc object to `@action` in subclass.
        @action = lambda do |desc, usage: nil, detail: nil, description: nil, postamble: nil, tag: nil, important: nil, hidden: nil|
          #; [!r07i7] `@action.()` raises DefinitionError if called consectively.
          @__actiondef__ == nil  or
            raise DefinitionError.new("`@action.()` called without method definition (please define method for this action).")
          schema = _new_option_schema()
          #; [!34psw] `@action.()` stores arguments into `@__actiondef__`.
          kws = {usage: usage, detail: detail, description: description, postamble: postamble, tag: tag, important: important, hidden: hidden}
          @__actiondef__ = [desc, schema, kws]
        end
        #; [!en6n0] sets Proc object to `@option` in subclass.
        @option = lambda do |key, optstr, desc,
                             type: nil, rexp: nil, pattern: nil, enum: nil,
                             range: nil, value: nil, multiple: nil, detail: nil,
                             tag: nil, important: nil, hidden: nil, &callback|
          #; [!68hf8] raises DefinitionError if `@option.()` called without `@action.()`.
          @__actiondef__ != nil  or
            raise DefinitionError.new("`@option.()` called without `@action.()`.")
          #; [!2p98r] `@option.()` stores arguments into option schema object.
          schema = @__actiondef__[1]
          schema.add(key, optstr, desc,
                     type: type, rexp: rexp, pattern: pattern, enum: enum,
                     range: range, value: value, multiple: multiple, detail: detail,
                     tag: tag, important: important, hidden: hidden, &callback)
        end
        #; [!aiwns] `@copy_options.()` copies options from other action.
        @copy_options = lambda do |action_name, except: []|
          #; [!bfxye] `@copy_options.()` tries to find an action with current prefix.
          metadata = nil
          curr_prefix = current_prefix()
          if curr_prefix
            metadata = REGISTRY.metadata_get(curr_prefix + action_name)
          end
          #; [!mhhn2] `@copy_options.()` raises DefinitionError when action not found.
          metadata ||= REGISTRY.metadata_get(action_name)
          metadata != nil  or
            raise DefinitionError.new("@copy_options.(#{action_name.inspect}): Action not found.")
          #; [!0slo8] raises DefinitionError if `@copy_options.()` called without `@action.()`.
          @__actiondef__ != nil  or
            raise DefinitionError.new("@copy_options.(#{action_name.inspect}): Called without `@action.()`.")
          #; [!0qz0q] `@copy_options.()` stores arguments into option schema object.
          #; [!dezh1] `@copy_options.()` ignores help option automatically.
          schema = @__actiondef__[1]
          except = except.is_a?(Array) ? except : (except == nil ? [] : [except])
          schema.copy_from(metadata.schema, except: [:help] + except)
        end
        #; [!7g5ug] sets Proc object to `@optionset` in subclass.
        @optionset = lambda do |*optionsets|
          #; [!o27kt] raises DefinitionError if `@optionset.()` called without `@action.()`.
          @__actiondef__ != nil  or
            raise DefinitionError.new("`@optionset.()` called without `@action.()`.")
          #; [!ky6sg] copies option items from optionset into schema object.
          schema = @__actiondef__[1]
          optionsets.each {|optset| optset.copy_into(schema) }
        end
      end
      nil
    end

    def self._new_option_schema()  # :nodoc:
      #; [!zuxmj] creates new option schema object.
      schema = ACTION_OPTION_SCHEMA_CLASS.new()
      #; [!rruxi] adds '-h, --help' option as hidden automatically.
      ACTION_SHARED_OPTIONS.each {|item| schema.add_item(item) }
      return schema
    end
    private_class_method :_new_option_schema

    def self.method_added(method_symbol)
      #; [!6frgx] do nothing if `@action.()` is not called.
      return false if @__actiondef__ == nil
      #; [!e3yjo] clears `@__actiondef__`.
      meth = method_symbol
      desc, schema, kws = @__actiondef__
      @__actiondef__ = nil
      #; [!jq4ex] raises DefinitionError if option defined but corresponding keyword arg is missing.
      errmsg = __validate_kwargs(method_symbol, schema)
      errmsg == nil  or
        raise DefinitionError,
              "def #{method_symbol}(): #{errmsg}"
      #; [!ejdlo] converts method name to action name.
      action = Util.method2action(meth)  # ex: :a__b_c => "a:b-c"
      #; [!w9qat] when `category()` called before defining action method...
      alias_p = false
      if @__prefixdef__
        prefix, prefix_action, alias_target = @__prefixdef__
        #; [!3pl1r] renames method name to new name with prefix.
        meth = "#{prefix.gsub(':', '__')}#{meth}".intern
        alias_method(meth, method_symbol)
        remove_method(method_symbol)
        #; [!mil2g] when action name matched to 'action:' kwarg of `category()`...
        if action == prefix_action
          #; [!hztpp] uses pefix name as action name.
          action = prefix.chomp(':')
          #; [!cydex] clears `action:` kwarg.
          @__prefixdef__[1] = nil
        #; [!8xsnw] when action name matched to `alias_for:` kwarg of `category()`...
        elsif action == alias_target
          #; [!iguvp] adds prefix name to action name.
          action = prefix + action
          alias_p = true
        #; [!wmevh] else...
        else
          #; [!9cyc2] adds prefix name to action name.
          action = prefix + action
        end
      #; [!y8lh0] else...
      else
        #; [!0ki5g] not add prefix to action name.
        prefix = alias_target = nil
      end
      #; [!dad1q] raises DefinitionError if action with same name already defined.
      #; [!ur8lp] raises DefinitionError if method already defined in parent or ancestor class.
      #; [!dj0ql] method override check is done with new method name (= prefixed name).
      (errmsg = __validate_action_method(action, meth, method_symbol)) == nil  or
        raise DefinitionError.new("def #{method_symbol}(): #{errmsg}")
      #; [!7fnh4] registers action metadata.
      action_metadata = ActionMetadata.new(action, desc, schema, self, meth, **kws)
      REGISTRY.metadata_add(action_metadata)
      #; [!lyn0z] registers alias metadata if necessary.
      if alias_p
        prefix != nil  or raise "** assertion failed: ailas_target=#{alias_target.inspect}"
        alias_metadata = AliasMetadata.new(prefix.chomp(':'), action, nil)
        REGISTRY.metadata_add(alias_metadata)
        #; [!4402s] clears `alias_for:` kwarg.
        @__prefixdef__[2] = nil
      end
      #; [!u0td6] registers prefix of action if not registered yet.
      REGISTRY.category_add_via_action(action)
      #
      return true    # for testing purpose
    end

    def self.__validate_kwargs(method_symbol, schema)  # :nodoc:
      fnkeys = []
      keyrest_p = false
      self.instance_method(method_symbol).parameters.each do |kind, key|
        case kind
        when :key, :keyreq ; fnkeys << key       # ex: f(x: nil), f(x:)
        when :keyrest      ; keyrest_p = true    # ex: f(**x)
        end
      end
      #; [!xpg47] returns nil if `**kwargs` exist.
      return nil if keyrest_p
      #; [!qowwj] returns error message if option defined but corresponding keyword arg is missing.
      optkeys = schema.each.collect(&:key)
      optkeys.delete(:help)
      missing = optkeys - fnkeys
      missing.empty?  or
        return "Keyword argument `#{missing[0]}:` expected which corresponds to the `:#{missing[0]}` option, but not exist."
      #toomuch = fnkeys - optkeys
      #toomuch.empty?  or
      #  return "Keyword argument `#{toomuch[0]}:` exist but has no corresponding option."
      return nil
    end
    private_class_method :__validate_kwargs

    def self.__validate_action_method(action, meth, method_symbol)  # :nodoc:
      #; [!5a4d3] returns error message if action with same name already defined.
      ! REGISTRY.metadata_exist?(action)  or
        return "Action '#{action}' already defined (to redefine it, delete it beforehand by `undef_action()`)."
      #; [!uxsx3] returns error message if method already defined in parent or ancestor class.
      #; [!3fmpo] method override check is done with new method name (= prefixed name).
      ! Util.method_override?(self, meth)  or
        return "Please rename it to `#{method_symbol}_()`, because it overrides existing method in parent or ancestor class."
      return nil
    end
    private_class_method :__validate_action_method

    def self.current_prefix()
      #; [!2zt0f] returns current prefix name such as 'foo:bar:'.
      return @__prefixdef__ ? @__prefixdef__[0] : nil
    end

    def self.category(prefix, desc=nil, action: nil, alias_for: nil, &block)
      #; [!mp1p5] raises DefinitionError if prefix is invalid.
      errmsg = __validate_prefix(prefix)
      errmsg == nil  or
        raise DefinitionError.new("category(#{prefix.inspect}): #{errmsg}")
      #; [!q01ma] raises DefinitionError if action or alias name is invalid.
      argstr, errmsg = __validate_action_and_alias(action, alias_for)
      errmsg == nil  or
        raise DefinitionError.new("`category(#{prefix.inspect}, #{argstr})`: #{errmsg}")
      #; [!kwst6] if block given...
      if block_given?()
        #; [!t8wwm] saves previous prefix data and restore them at end of block.
        prev = @__prefixdef__
        prefix = prev[0] + prefix if prev      # ex: "foo:" => "parent:foo:"
        @__prefixdef__ = [prefix, action, alias_for]
        #; [!j00pk] registers prefix and description, even if no actions defined.
        REGISTRY.category_add(prefix, desc)
        begin
          yield
          #; [!w52y5] raises DefinitionError if `action:` specified but target action not defined.
          if action
            @__prefixdef__[1] == nil  or
              raise DefinitionError.new("category(#{prefix.inspect}, action: #{action.inspect}): Target action not defined.")
          end
          #; [!zs3b5] raises DefinitionError if `alias_for:` specified but target action not defined.
          if alias_for
            @__prefixdef__[2] == nil  or
              raise DefinitionError.new("category(#{prefix.inspect}, alias_for: #{alias_for.inspect}): Target action of alias not defined.")
          end
        ensure
          @__prefixdef__ = prev
        end
      #; [!yqhm8] else...
      else
        #; [!tgux9] just stores arguments into class.
        @__prefixdef__ = [prefix, action, alias_for]
        #; [!ncskq] registers prefix and description, even if no actions defined.
        REGISTRY.category_add(prefix, desc)
      end
      nil
    end

    def self.__validate_prefix(prefix)  # :nodoc:
      #; [!bac19] returns error message if prefix is not a string.
      #; [!608fc] returns error message if prefix doesn't end with ':'.
      #; [!vupza] returns error message if prefix contains '_'.
      #; [!5vgn3] returns error message if prefix is invalid.
      #; [!7rphu] returns nil if prefix is valid.
      prefix.is_a?(String)  or return "String expected, but got #{prefix.class.name}."
      prefix =~ /:\z/       or return "Prefix name should end with ':'."
      prefix !~ /_/         or return "Prefix name should not contain '_' (use '-' instead)."
      rexp = /\A[a-z][-a-zA-Z0-9]*:([a-z][-a-zA-Z0-9]*:)*\z/
      prefix =~ rexp        or return "Invalid prefix name."
      return nil
    end
    private_class_method :__validate_prefix

    def self.__validate_action_and_alias(action, alias_for)
      #; [!38ji9] returns error message if action name is not a string.
      action == nil || action.is_a?(String)  or
        return "action: #{action.inspect}", "Action name should be a string, but got #{action.class.name} object."
      #; [!qge3m] returns error message if alias name is not a string.
      alias_for == nil || alias_for.is_a?(String)  or
        return "alias_for: #{alias_for.inspect}", "Alias name should be a string, but got #{alias_for.class.name} object."
      #; [!ermv8] returns error message if both `action:` and `alias_for:` kwargs are specified.
      ! (action != nil && alias_for != nil)  or
        return "action: #{action.inspect}, alias_for: #{alias_for.inspect}", "`action:` and `alias_for:` are exclusive."
    end
    private_class_method :__validate_action_and_alias

    def self.define_alias(alias_name, action_name, tag: nil, important: nil, hidden: nil)
      #; [!tcpuz] just defines an alias when current prefix is nil.
      prefix = self.current_prefix()
      if prefix == nil
        nil
      #; [!b8ly2] supports array argument.
      elsif action_name.is_a?(Array)
        action_name[0] = prefix + action_name[0]
      #; [!c6duw] defines an alias with prefix when current prefix exist.
      else
        action_name = prefix + action_name
      end
      #; [!0dkrj] keyword arguments are passed to higher function.
      Benry::CmdApp.define_alias(alias_name, action_name, tag: tag, important: important, hidden: hidden)
    end

    def self.optionset(&block)
      #; [!us0g4] yields block with dummy action.
      #; [!1idwv] clears default option items.
      @action.("dummy action by optionset()")
      schema = @__actiondef__[1]
      schema.each.collect(&:key).each {|key| schema.delete(key) }
      yield
      #; [!sp3hk] clears `@__actiondef__` to make `@action.()` available.
      schema = @__actiondef__[1]
      @__actiondef__ = nil
      #; [!mwbyc] returns new OptionSet object which contains option items.
      return OptionSet.new.copy_from(schema)
    end

    def run_once(action_name, *args, **kwargs)
      #; [!nqjxk] runs action and returns true if not runned ever.
      #; [!wcyut] not run action and returns false if already runned.
      ctx = (@__context__ ||= CONTEXT_CLASS.new)
      return ctx.invoke_action(action_name, args, kwargs, once: true)
    end

    def run_action(action_name, *args, **kwargs)
      #; [!uwi68] runs action and returns true.
      ctx = (@__context__ ||= CONTEXT_CLASS.new)
      return ctx.invoke_action(action_name, args, kwargs, once: false)
    end

    def at_end(&block)
      #; [!3mqcz] registers proc object to context object.
      @__context__._add_end_block(block)
      nil
    end

    def option_error(errmsg)
      #; [!engp2] returns OptionError object.
      return OptionError.new(errmsg)
    end

    def action_error(errmsg)
      #; [!2m7d6] returns ActionError object.
      return ActionError.new(errmsg)
    end

  end


  Action = ActionScope


  class Registry

    def initialize()
      @metadata_dict = {}          # {name => (ActionMetadata|AliasMetadata)}
      @category_dict = {}          # {prefix => description}
      @abbrev_dict   = {}
    end

    def metadata_add(metadata)
      ! @metadata_dict.key?(metadata.name)  or raise "** assertion failed: metadata.name=#{metadata.name.inspect}"
      #; [!8bhxu] registers metadata with it's name as key.
      @metadata_dict[metadata.name] = metadata
      #; [!k07kp] returns registered metadata objet.
      return metadata
    end

    def metadata_get(name)
      #; [!l5m49] returns metadata object corresponding to name.
      #; [!rztk2] returns nil if metadata not found for the name.
      return @metadata_dict[name]
    end

    def metadata_del(name)
      @metadata_dict.key?(name)  or raise "** assertion failed: name=#{name.inspect}"
      #; [!69vo7] deletes metadata object corresponding to name.
      #; [!8vg6w] returns deleted metadata object.
      return @metadata_dict.delete(name)
    end

    def metadata_exist?(name)
      #; [!0ck5n] returns true if metadata object registered.
      #; [!x7ziz] returns false if metadata object not registered.
      return @metadata_dict.key?(name)
    end

    def metadata_each(all: true, &b)
      #; [!3l6r7] returns Enumerator object if block not given.
      return enum_for(:metadata_each, all: all) unless block_given?()
      #; [!r8mb3] yields each metadata object if block given.
      #; [!qvc77] ignores hidden metadata if `all: false` passed.
      @metadata_dict.keys.sort.each do |name|
        metadata = @metadata_dict[name]
        yield metadata if all || ! metadata.hidden?
      end
      nil
    end

    def metadata_action2aliases(all: true)
      #; [!krry6] returns a Hash object (key: action name, value: alias metadatas).
      dict = {}    # {action_name => [alias_metadata]}
      metadata_each(all: all) do |md|
        #; [!zhcm6] skips actions which has no aliases.
        (dict[md.action] ||= []) << md if md.alias?
      end
      return dict
    end

    def metadata_lookup(name)
      #; [!dcs9v] looks up action metadata recursively if alias name specified.
      #; [!f8fqx] returns action metadata and alias args.
      alias_args = []
      md = metadata_get(name)
      while md != nil && md.alias?
        alias_args = md.args + alias_args if md.args && ! md.args.empty?
        md = metadata_get(md.action)
      end
      return md, alias_args
    end

    def category_add(prefix, desc=nil)
      #; [!k27in] registers prefix if not registered yet.
      #; [!xubc8] registers prefix whenever desc is not a nil.
      if ! @category_dict.key?(prefix) || desc
        @category_dict[prefix] = desc
      end
      nil
    end

    def category_add_via_action(action)
      #; [!ztrfj] registers prefix of action.
      #; [!31pik] do nothing if prefix already registered.
      #; [!oqq7j] do nothing if action has no prefix.
      if action =~ /\A(?:[-\w]+:)+/
        prefix = $&
        @category_dict[prefix] = nil unless @category_dict.key?(prefix)
      end
      nil
    end

    def category_exist?(prefix)
      #; [!79cyx] returns true if prefix is already registered.
      #; [!jx7fk] returns false if prefix is not registered yet.
      return @category_dict.key?(prefix)
    end

    def category_each(&block)
      #; [!67r3i] returns Enumerator object if block not given.
      return enum_for(:category_each) unless block_given?()
      #; [!g3d1z] yields block with each prefix and desc.
      @category_dict.each(&block)
      nil
    end

    def category_get_desc(prefix)
      #; [!d47kq] returns description if prefix is registered.
      #; [!otp1b] returns nil if prefix is not registered.
      return @category_dict[prefix]
    end

    def category_count_actions(depth, all: false)
      dict = {}
      #; [!8wipx] includes prefix of hidden actions if `all: true` passed.
      metadata_each(all: all) do |metadata|
        name = metadata.name
        next unless name =~ /:/
        #; [!5n3qj] counts prefix of specified depth.
        arr = name.split(':')           # ex: "a:b:c:xx" -> ["a", "b", "c", "xx"]
        arr.pop()                       # ex: ["a", "b", "c", "xx"] -> ["a", "b", "c"]
        arr = arr.take(depth) if depth > 0  # ex: ["a", "b", "c"] -> ["a", "b"]  (if depth==2)
        prefix = arr.join(':') + ':'    # ex: ["a", "b"] -> "aa:bb:"
        dict[prefix] = (dict[prefix] || 0) + 1  # ex: dict["aa:bb:"] = (dict["aa:bb:"] || 0) + 1
        #; [!r2frb] counts prefix of lesser depth.
        while (arr.pop(); ! arr.empty?) # ex: ["a", "b"] -> ["a"]
          prefix = arr.join(':') + ':'  # ex: ["a"] -> "a:"
          dict[prefix] ||= 0            # ex: dict["a:"] ||= 0
        end
      end
      return dict
    end

    def abbrev_add(abbrev, prefix)
      #; [!n475k] registers abbrev with prefix.
      @abbrev_dict[abbrev] = prefix
      nil
    end

    def abbrev_get_prefix(abbrev)
      #; [!h1dvb] returns prefix bound to abbrev.
      return @abbrev_dict[abbrev]
    end

    def abbrev_exist?(abbrev)
      #; [!tjbdy] returns true/false if abbrev registered or not.
      return @abbrev_dict.key?(abbrev)
    end

    def abbrev_each()
      #; [!2oo4o] yields each abbrev name and prefix.
      @abbrev_dict.keys.sort.each do |abbrev|
        prefix = @abbrev_dict[abbrev]
        yield abbrev, prefix
      end
      nil
    end

    def abbrev_resolve(action)
      #; [!n7zsy] replaces abbrev in action name with prefix.
      if action =~ /\A[-\w]+:/
        abbrev = $&; rest = $'
        prefix = @abbrev_dict[abbrev]
        return prefix + rest if prefix
      end
      #; [!kdi3o] returns nil if abbrev not found in action name.
      return nil
    end

  end


  REGISTRY = Registry.new()


  class BuiltInAction < ActionScope

    @action.("print help message (of action if specified)")
    @option.(:all, "-a, --all", "show all options, including private ones")
    def help(action=nil, all: false)
      #; [!2n99u] raises ActionError if current application is not nil.
      app = Benry::CmdApp.current_app()  or
        raise ActionError.new("'help' action is available only when invoked from application.")
      #; [!g0n06] prints application help message if action name not specified.
      #; [!epj74] prints action help message if action name specified.
      str = app.render_help_message(action, all: all)
      #; [!2t43b] deletes escape characters from help message when non-color mode.
      str = Util.delete_escape_chars(str) unless Util.color_mode?
      print str
    end

  end


  class ApplicationContext

    def initialize(config, _registry: REGISTRY)
      @config        = config
      @_registry     = _registry
      #@scope_objects = {}     # {action_name => ActionScope}
      @status_dict   = {}      # {action_name => (:done|:doing)}
      @curr_action   = nil     # ActionMetadata
      @end_blocks    = []      # [Proc]
    end

    def _add_end_block(block)  # :nodoc:
      @end_blocks << block
      nil
    end

    private

    def teardown()  # :nodoc:
      #; [!4df2f] invokes end blocks in reverse order of registration.
      #; [!vskre] end block list should be cleared.
      while ! @end_blocks.empty?
        block = @end_blocks.pop()
        block.call()
      end
      #@scope_objects.each {|_, scope| scope.__clear_recursive_reference() }
      #@scope_objects.clear()
      @status_dict.clear()
    end

    public

    def start_action(action_name, cmdline_args)  ## called from Application#run()
      #; [!2mnh7] looks up action metadata with action or alias name.
      metadata, alias_args = @_registry.metadata_lookup(action_name)
      #; [!0ukvb] raises CommandError if action nor alias not found.
      metadata != nil  or
        raise CommandError.new("#{action_name}: Action nor alias not found.")
      #; [!9n46s] if alias has its own args, combines them with command-line args.
      args = alias_args + cmdline_args
      #; [!5ru31] options in alias args are also parsed as well as command-line options.
      #; [!r3gfv] raises OptionError if invalid action options specified.
      options = metadata.parse_options(args)
      #; [!lg6br] runs action with command-line arguments.
      _invoke_action(metadata, args, options, once: false)
      return nil
    ensure
      #; [!jcguj] clears instance variables.
      teardown()
    end

    def invoke_action(action_name, args, kwargs, once: false)  ## called from ActionScope#run_action_xxxx()
      action = action_name
      #; [!uw6rq] raises ActionError if action name is not a string.
      Util.name_should_be_a_string(action, 'Action', ActionError)
      #; [!dri6e] if called from other action containing prefix, looks up action with the prefix firstly.
      metadata = nil
      if action !~ /:/ && @curr_action && @curr_action.name =~ /\A(.*:)/
        prefix = $1
        metadata = @_registry.metadata_get(prefix + action)
        action = prefix + action if metadata
      end
      #; [!ygpsw] raises ActionError if action not found.
      metadata ||= @_registry.metadata_get(action)
      metadata != nil  or
        raise ActionError.new("#{action}: Action not found.")
      #; [!de6a9] raises ActionError if alias name specified.
      ! metadata.alias?  or
        raise ActionError.new("#{action}: Action expected, but it is an alias.")
      return _invoke_action(metadata, args, kwargs, once: once)
    end

    private

    def _invoke_action(action_metadata, args, kwargs, once: false)
      ! action_metadata.alias?  or raise "** assertion failed: action_metadata=#{action_metadata.inspect}"
      #; [!ev3qh] handles help option firstly if specified.
      action = action_metadata.name
      if kwargs[:help]
        invoke_action("help", [action], {}, once: false)
        return nil
      end
      #; [!6hoir] don't run action and returns false if `once: true` specified and the action already done.
      return false if once && @status_dict[action] == :done
      #; [!xwlou] raises ActionError if looped aciton detected.
      @status_dict[action] != :doing  or
        raise ActionError.new("#{action}: Looped action detected.")
      #; [!peqk8] raises ActionError if args and opts not matched to action method.
      md = action_metadata
      scope_obj = new_scope_object(md)
      errmsg = Util.validate_args_and_kwargs(scope_obj, md.meth, args, kwargs)
      errmsg == nil  or
        raise ActionError.new("#{md.name}: #{errmsg}")
      #; [!kao97] action invocation is nestable.
      @status_dict[action] ||= :doing
      prev_action = @curr_action
      @curr_action = md
      #; [!5jdlh] runs action method with scope object.
      begin
        #; [!9uue9] reports enter into and exit from action if global '-T' option specified.
        c1, c2 = Util.color_mode? ? ["\e[33m", "\e[0m"] : ["", ""]
        puts "#{c1}### enter: #{md.name}#{c2}" if @config.trace_mode
        if kwargs.empty?                        # for Ruby < 2.7
          scope_obj.__send__(md.meth, *args)    # for Ruby < 2.7
        else
          scope_obj.__send__(md.meth, *args, **kwargs)
        end
        puts "#{c1}### exit:  #{md.name}#{c2}" if @config.trace_mode
      ensure
        @curr_action = prev_action
      end
      @status_dict[action] = :done
      #; [!ndxc3] returns true if action invoked.
      return true
    end

    protected

    def new_scope_object(action_metadata)
      #; [!1uzs3] creates new scope object.
      md = action_metadata
      scope_obj = md.klass.new(@config, self)
      #scope_obj = (@scope_objects[md.klass.name] ||= md.klass.new(@config, self))
      return scope_obj
    end

  end


  CONTEXT_CLASS = ApplicationContext


  class Config

    FORMAT_OPTION         = "  %-18s : %s"
    FORMAT_ACTION         = "  %-18s : %s"
    FORMAT_ABBREV         = "  %-10s =>  %s"
    FORMAT_USAGE          = "  $ %s"
    FORMAT_CATEGORY       = nil                 # same as 'config.format_action' if nil
    DECORATION_COMMAND    = "\e[1m%s\e[0m"      # bold
    DECORATION_HEADER     = "\e[1;34m%s\e[0m"   # bold, blue
    DECORATION_EXTRA      = "\e[2m%s\e[0m"      # gray color
    DECORATION_STRONG     = "\e[1m%s\e[0m"      # bold
    DECORATION_WEAK       = "\e[2m%s\e[0m"      # gray color
    DECORATION_HIDDEN     = "\e[2m%s\e[0m"      # gray color
    DECORATION_DEBUG      = "\e[2m%s\e[0m"      # gray color
    DECORATION_ERROR      = "\e[31m%s\e[0m"     # red color
    APP_USAGE             = "<action> [<arguments>...]"

    def initialize(app_desc, app_version=nil,
                   app_name: nil, app_command: nil, app_usage: nil, app_detail: nil,
                   default_action: nil,
                   help_description: nil, help_postamble: nil,
                   format_option: nil, format_action: nil, format_abbrev: nil, format_usage: nil, format_category: nil,
                   deco_command: nil, deco_header: nil, deco_extra: nil,
                   deco_strong: nil, deco_weak: nil, deco_hidden: nil, deco_debug: nil, deco_error: nil,
                   option_help: true, option_version: nil, option_list: true, option_topic: :hidden, option_all: true,
                   option_verbose: false, option_quiet: false, option_color: false,
                   option_debug: :hidden, option_trace: false, option_dryrun: false,
                   backtrace_ignore_rexp: nil)
      #; [!pzp34] if `option_version` is not specified, then set true if `app_version` is provided.
      option_version = !! app_version if option_version == nil
      #
      @app_desc           = app_desc
      @app_version        = app_version
      @app_name           = app_name
      @app_command        = app_command || File.basename($0)
      @app_usage          = app_usage
      @app_detail         = app_detail
      @default_action     = default_action
      @help_description   = help_description
      @help_postamble     = help_postamble
      @format_option      = format_option || FORMAT_OPTION
      @format_action      = format_action || FORMAT_ACTION
      @format_abbrev      = format_abbrev || FORMAT_ABBREV
      @format_usage       = format_usage  || FORMAT_USAGE
      @format_category    = format_category   # nil means to use @format_action
      @deco_command       = deco_command || DECORATION_COMMAND  # for command name in help
      @deco_header        = deco_header  || DECORATION_HEADER   # for "Usage:" or "Actions"
      @deco_extra         = deco_extra   || DECORATION_EXTRA    # for "(default: )" or "(depth=1)"
      @deco_strong        = deco_strong  || DECORATION_STRONG   # for `important: true`
      @deco_weak          = deco_weak    || DECORATION_WEAK     # for `important: false`
      @deco_hidden        = deco_hidden  || DECORATION_HIDDEN   # for `hidden: true`
      @deco_debug         = deco_error   || DECORATION_DEBUG
      @deco_error         = deco_error   || DECORATION_ERROR
      @option_help        = option_help         # enable or disable `-h, --help`
      @option_version     = option_version      # enable or disable `-V, --version`
      @option_list        = option_list         # enable or disable `-l, --list`
      @option_topic       = option_topic        # enable or disable `-L <topic>`
      @option_all         = option_all          # enable or disable `-a, --all`
      @option_verbose     = option_verbose      # enable or disable `-v, --verbose`
      @option_quiet       = option_quiet        # enable or disable `-q, --quiet`
      @option_color       = option_color        # enable or disable `--color[=<on|off>]`
      @option_debug       = option_debug        # enable or disable `--debug`
      @option_trace       = option_trace        # enable or disable `-T, --trace`
      @option_dryrun      = option_dryrun       # enable or disable `-X, --dryrun`
      @backtrace_ignore_rexp = backtrace_ignore_rexp
      #
      #@verobse_mode       = nil
      #@quiet_mode         = nil
      #@color_mode         = nil
      #@debug_mode         = nil
      @trace_mode         = nil
    end

    attr_accessor :app_desc, :app_version, :app_name, :app_command, :app_usage, :app_detail
    attr_accessor :default_action
    attr_accessor :format_option, :format_action, :format_abbrev, :format_usage, :format_category
    attr_accessor :deco_command, :deco_header, :deco_extra
    attr_accessor :help_description, :help_postamble
    attr_accessor :deco_strong, :deco_weak, :deco_hidden, :deco_debug, :deco_error
    attr_accessor :option_help, :option_version, :option_list, :option_topic, :option_all
    attr_accessor :option_verbose, :option_quiet, :option_color
    attr_accessor :option_debug, :option_trace, :option_dryrun
    attr_accessor :trace_mode #, :verbose_mode, :quiet_mode, :color_mode, :debug_mode
    attr_accessor :backtrace_ignore_rexp
    alias trace_mode? trace_mode

    def each(sort: false, &b)
      #; [!yxi7r] returns Enumerator object if block not given.
      return enum_for(:each, sort: sort) unless block_given?()
      #; [!64zkf] yields each config name and value.
      #; [!0zatj] sorts key names if `sort: true` passed.
      ivars = instance_variables()
      ivars = ivars.sort() if sort
      ivars.each do |ivar|
        val = instance_variable_get(ivar)
        yield ivar.to_s[1..-1].intern, val
      end
      nil
    end

  end


  class BaseHelpBuilder

    def initialize(config, _registry: REGISTRY)
      @config    = config
      @_registry = _registry
    end

    HEADER_USAGE       = "Usage:"
    HEADER_DESCRIPTION = "Description:"
    HEADER_OPTIONS     = "Options:"
    HEADER_ACTIONS     = "Actions:"
    HEADER_ALIASES     = "Aliases:"
    HEADER_ABBREVS     = "Abbreviations:"
    HEADER_CATEGORIES  = "Categories:"

    def build_help_message(x, all: false)
      #; [!0hy81] this is an abstract method.
      raise NotImplementedError.new("#{self.class.name}#build_help_message(): not implemented yet.")
    end

    protected

    def render_section(header, content, extra=nil)
      #; [!61psk] returns section string with decorating header.
      #; [!0o8w4] appends '\n' to content if it doesn't end with '\n'.
      nl = content.end_with?("\n") ? nil : "\n"
      extra = " " + decorate_extra(extra) if extra
      return "#{decorate_header(header)}#{extra}\n#{content}#{nl}"
    end

    def render_sections(value, item, &b)
      #; [!tqau1] returns nil if value is nil or empty.
      #; [!ezb0d] returns value unchanged if value is a string.
      #; [!gipxn] builds sections of help message if value is a hash object.
      xs = value.is_a?(Array) ? value : [value]
      sb = []
      xs.each do |x|
        case x
        when nil     ; nil
        when String  ; sb << (x.end_with?("\n") ? x : x + "\n")
        when Hash    ; x.each {|k, v| sb << render_section(k, v) }
        else
          #; [!944rt] raises ActionError if unexpected value found in value.
          raise ActionError.new("#{x.inspect}: Unexpected value found in `#{item}`.")
        end
      end
      return sb.empty? ? nil : sb.join("\n")
    end

    def render_option_help(schema, format, all: false)
      #; [!muhem] returns option part of help message.
      #; [!4z70n] includes hidden options when `all: true` passed.
      #; [!hxy1f] includes `detail:` kwarg value with indentation.
      #; [!jcqdf] returns nil if no options.
      c = @config
      sb = []
      schema.each do |x|
        next if x.hidden? && ! all
        s = format % [x.optdef, x.desc]
        if x.detail
          space = (format % ["", ""]).gsub(/\S/, " ")
          s += "\n"
          s += x.detail.chomp("\n").gsub(/^/, space)
        end
        s = decorate_str(s, x.hidden?, x.important?)
        sb << s << "\n"
      end
      return sb.empty? ? nil : sb.join()
    end

    def decorate_command(s)
      #; [!zffx5] decorates command string.
      return @config.deco_command % s
    end

    def decorate_header(s)
      #; [!4ufhw] decorates header string.
      return @config.deco_header % s
    end

    def decorate_extra(s)
      #; [!9nch4] decorates extra string.
      return @config.deco_extra % s
    end

    def decorate_str(s, hidden, important)
      #; [!9qesd] decorates string if `hidden` is true.
      #; [!uql2d] decorates string if `important` is true.
      #; [!mdhhr] decorates string if `important` is false.
      #; [!6uzbi] not decorates string if `hidden` is falthy and `important` is nil.
      c = @config
      if    hidden             ; return c.deco_hidden % s
      elsif important == true  ; return c.deco_strong % s
      elsif important == false ; return c.deco_weak % s
      else                     ; return s
      end
    end

    def header(symbol)
      #; [!ep064] returns constant value defined in the class.
      #; [!viwtn] constant value defined in child class is prior to one defined in parent class.
      return self.class.const_get(symbol)
    end

  end


  class ApplicationHelpBuilder < BaseHelpBuilder

    def build_help_message(gschema, all: false)
      #; [!ezcs4] returns help message string of application.
      #; [!ntj2y] includes hidden actions and options if `all: true` passed.
      sb = []
      sb << section_preamble()
      sb << section_usage()
      sb << section_description()
      sb << section_options(gschema, all: all)
      sb << section_actions(true, all: all)
      #sb << section_aliases(all: all)
      #sb << section_abbrevs(all: all)
      #sb << section_categories(0, all: all)
      sb << section_postamble()
      return sb.compact().join("\n")
    end

    protected

    def section_preamble()
      #; [!51v42] returns preamble part of application help message.
      #; [!bmh17] includes `config.app_name` or `config.app_command` into preamble.
      #; [!opii8] includes `config.app_versoin` into preamble if it is set.
      #; [!3h380] includes `config.app_detail` into preamble if it is set.
      c = @config
      s = c.deco_command % (c.app_name || c.app_command)
      sb = []
      v = c.app_version ? (" " + c.deco_weak % "(#{c.app_version})") : ""
      sb << "#{s}#{v} --- #{c.app_desc}\n"
      if c.app_detail
        sb << "\n"
        sb << render_sections(c.app_detail, 'config.app_detail')
      end
      return sb.join()
    end

    def section_postamble()
      #; [!64hj1] returns postamble of application help message.
      #; [!z5k2w] returns nil if postamble not set.
      return render_sections(@config.help_postamble, 'config.help_postamble')
    end

    def section_usage()
      #; [!h98me] returns 'Usage:' section of application help message.
      c = @config
      s = c.deco_command % c.app_command
      s = c.format_usage % s + " [<options>] "
      #; [!i9d4r] includes `config.app_usage` into help message if it is set.
      usage = s + (c.app_usage || @config.class.const_get(:APP_USAGE))
      return render_section(header(:HEADER_USAGE), usage + "\n")  # "Usage:"
    end

    def section_description()
      c = @config
      #; [!qarrk] returns 'Description:' section if `config.help_description` is set.
      #; [!ealol] returns nil if `config.help_description` is nil.
      return nil unless c.help_description
      return render_section(header(:HEADER_DESCRIPTION), c.help_description)
    end

    def section_options(gschema, all: false)
      #; [!f2n70] returns 'Options:' section of application help message.
      #; [!0bboq] includes hidden options into help message if `all: true` passed.
      #; [!fjhow] returns nil if no options.
      format = @config.format_option
      s = render_option_help(gschema, format, all: all)
      return nil if s == nil
      return render_section(header(:HEADER_OPTIONS), s)  # "Options:"
    end

    public

    def section_actions(include_aliases=true, all: false)
      c = @config
      #; [!yn8ea] includes hidden actions into help message if `all: true` passed.
      str = _render_metadata_list(c.format_action, include_aliases, all: all) {|md|
        #; [!10qp0] includes aliases if the 1st argument is true.
        ! md.alias?
      }
      #; [!24by5] returns nil if no actions defined.
      return nil if str.empty?
      #; [!8qz6a] adds default action name after header if it is set.
      extra = c.default_action ? "(default: #{c.default_action})" : nil
      #; [!typ67] returns 'Actions:' section of help message.
      return render_section(header(:HEADER_ACTIONS), str, extra)  # "Actions:"
    end

    def _render_metadata_list(format, include_aliases=true, all: false, &filter)
      registry = @_registry
      #; [!iokkp] builds list of actions or aliases.
      sb = []
      action2aliases = nil  # {action_name => [alias_metadata]}
      ali_indent = nil
      registry.metadata_each(all: all) do |metadata|
        md = metadata
        #; [!grwkj] filters by block.
        next unless yield(md)
        s = format % [md.name, md.desc]
        sb << decorate_str(s, md.hidden?, md.important?) << "\n"
        #; [!hv7or] if action has any aliases, print them below of the action.
        next if ! include_aliases
        next if md.alias?
        action2aliases ||= registry.metadata_action2aliases()
        next unless action2aliases[md.name]
        ali_str = action2aliases[md.name].collect {|alias_metadata|
          alias_metadata.name_with_args()
        }.join(", ")
        ali_indent ||= (format % ["", ""]).gsub(/[^ ]/, " ")
        s2 = "#{ali_indent}(alias: #{ali_str})"
        sb << decorate_str(s2, nil, false) << "\n"
      end
      return sb.join()
    end
    private :_render_metadata_list

    def section_availables(include_aliases=true, all: false)
      #; [!pz0cu] includes 'Actions:' and 'Aliases:' sections.
      s1 = section_actions(include_aliases, all: all)
      s2 = section_aliases(all: all)
      return [s1, s2].compact.join("\n")
    end

    def section_candidates(prefix, all: false)
      c = @config
      registry = @_registry
      #; [!idm2h] includes hidden actions when `all: true` passed.
      prefix2 = prefix.chomp(':')
      str = _render_metadata_list(c.format_action, all: all) {|metadata|
        #; [!duhyd] includes actions which name is same as prefix.
        #; [!nwwrd] if prefix is 'xxx:' and alias name is 'xxx' and action name of alias matches to 'xxx:', skip it because it will be shown in 'Aliases:' section.
        _category_action?(metadata, prefix)
      }
      s1 = str.empty? ? nil : render_section(header(:HEADER_ACTIONS), str)
      #; [!otvbt] includes name of alias which corresponds to action starting with prefix.
      #; [!bgpsm] includes name of alias which is equal to prefix name excluding tailing ':'.
      #; [!h5ek7] includes hidden aliases when `all: true` passed.
      str = _render_metadata_list(c.format_action, all: all) {|metadata|
        metadata.alias? && (metadata.action.start_with?(prefix) || metadata.action == prefix2)
      }
      #; [!9lnn2] alias names in candidate list are sorted by action name.
      str = str.each_line.sort_by {|line|
        line =~ /'([^']+)'/
        [$1, line]
      }.join()
      #; [!80t51] alias names are displayed in separated section from actions.
      s2 = str.empty? ? nil : render_section(header(:HEADER_ALIASES), str)
      #; [!jek9k] raises error when no actions nor aliases found starting with prefix.
      arr = [s1, s2].compact()
      ! arr.empty?  or
        raise CommandError, "'#{prefix}' : Unknown prefix. (Hint: try ':' instead of '#{prefix}' to list all prefixes.)"
      #; [!3c3f1] returns list of actions which name starts with prefix specified.
      return arr.join("\n")
    end

    def _category_action?(md, prefix)
      return true  if md.name.start_with?(prefix)
      return false if md.name != prefix.chomp(':')
      return true  if ! md.alias?
      return false if md.action.start_with?(prefix)
      return true
    end
    private :_category_action?

    def section_aliases(all: false)
      registry = @_registry
      sb = []
      format = @config.format_action
      #; [!d7vee] ignores hidden aliases in default.
      #; [!4vvrs] include hidden aliases if `all: true` specifieid.
      #; [!v211d] sorts aliases by action names.
      registry.metadata_each(all: all).select {|md| md.alias? }.sort_by {|md| [md.action, md.name] }.each do |md|
        s = format % [md.name, md.desc]
        sb << decorate_str(s, md.hidden?, md.important?) << "\n"
      end
      #; [!fj1c7] returns nil if no aliases found.
      return nil if sb.empty?
      #; [!496qq] renders alias list.
      return render_section(header(:HEADER_ALIASES), sb.join())  # "Aliases:"
    end

    def section_abbrevs(all: false)
      registry = @_registry
      format = @config.format_abbrev
      _ = all   # not used
      sb = []
      registry.abbrev_each do |abbrev, prefix|
        sb << format % [abbrev, prefix] << "\n"
      end
      #; [!dnt12] returns nil if no abbrevs found.
      return nil if sb.empty?
      #; [!00ice] returns abbrev list string.
      return render_section(header(:HEADER_ABBREVS), sb.join())  # "Abbreviations:"
    end

    def section_categories(depth=0, all: false)
      registry = @_registry
      c = @config
      #; [!30l2j] includes number of actions per prefix.
      #; [!alteh] includes prefix of hidden actions if `all: true` passed.
      dict = registry.category_count_actions(depth, all: all)
      #registry.category_each {|prefix, _| dict[prefix] = 0 unless dict.key?(prefix) }
      #; [!p4j1o] returns nil if no prefix found.
      return nil if dict.empty?
      #; [!k3y6q] uses `config.format_category` or `config.format_action`.
      format = (c.format_category || c.format_action) + "\n"
      indent = /^( *)/.match(format)[1]
      str = dict.keys.sort.collect {|prefix|
        s = "#{prefix} (#{dict[prefix]})"
        #; [!qxoja] includes category description if registered.
        desc = registry.category_get_desc(prefix)
        desc ? (format % [s, desc]) : "#{indent}#{s}\n"
      }.join()
      #; [!crbav] returns top prefix list.
      return render_section(header(:HEADER_CATEGORIES), str, "(depth=#{depth})")  # "Categories:"
    end

  end


  class ActionHelpBuilder < BaseHelpBuilder

    def build_help_message(metadata, all: false)
      #; [!f3436] returns help message of an action.
      #; [!8acs1] includes hidden options if `all: true` passed.
      #; [!mtvw8] includes 'Aliases:' section if action has any aliases.
      #; [!vcg9w] not include 'Options:' section if action has no options.
      #; [!1auu5] not include '[<options>]' in 'Usage:'section if action has no options.
      sb = []
      sb << section_preamble(metadata)
      sb << section_usage(metadata, all: all)
      sb << section_description(metadata)
      sb << section_options(metadata, all: all)
      sb << section_aliases(metadata, all: all)
      sb << section_postamble(metadata)
      return sb.compact().join("\n")
    end

    protected

    def section_preamble(metadata)
      #; [!a6nk4] returns preamble of action help message.
      #; [!imxdq] includes `config.app_command`, not `config.app_name`, into preamble.
      #; [!7uy4f] includes `detail:` kwarg value of `@action.()` if specified.
      md = metadata
      sb = []
      c = @config
      s = c.deco_command % "#{c.app_command} #{md.name}"
      sb << "#{s} --- #{md.desc}\n"
      if md.detail
        sb << "\n"
        sb << render_sections(md.detail, '@action.(detail: ...)')
      end
      return sb.join()
    end

    def section_usage(metadata, all: false)
      md = metadata
      c = @config
      s = c.deco_command % "#{c.app_command} #{md.name}"
      s = c.format_usage % s
      #; [!jca5d] not add '[<options>]' if action has no options.
      s += " [<options>]" unless md.option_empty?(all: all)
      #; [!h5bp4] if `usage:` kwarg specified in `@action.()`, use it as usage string.
      if md.usage != nil
        #; [!nfuxz] `usage:` kwarg can be a string or an array of string.
        sb = [md.usage].flatten.collect {|x| "#{s} #{x}\n" }
      #; [!z3lh9] if `usage:` kwarg not specified in `@action.()`, generates usage string from method parameters.
      else
        sb = [s]
        sb << Util.method2help(md.klass.new(c), md.meth) << "\n"
      end
      #; [!iuctx] returns 'Usage:' section of action help message.
      return render_section(header(:HEADER_USAGE), sb.join())  # "Usage:"
    end

    def section_description(metadata)
      #; [!zeujz] returns 'Description:' section if action description is set.
      #; [!0zffw] returns nil if action description is nil.
      md = metadata
      return nil unless md.description
      return render_section(header(:HEADER_DESCRIPTION), md.description)
    end

    def section_options(metadata, all: false)
      #; [!pafgs] returns 'Options:' section of help message.
      #; [!85wus] returns nil if action has no options.
      format = @config.format_option
      s = render_option_help(metadata.schema, format, all: all)
      return nil if s == nil
      return render_section(header(:HEADER_OPTIONS), s)  # "Options:"
    end

    def section_aliases(metadata, all: false)
      #; [!kjpt9] returns 'Aliases:' section of help message.
      #; [!cjr0q] returns nil if action has no options.
      format = @config.format_action
      registry = @_registry
      action_name = metadata.name
      sb = []
      registry.metadata_each(all: all) do |md|
        next unless md.alias?
        action_md, args = registry.metadata_lookup(md.name)
        next unless action_md
        next unless action_md.name == action_name
        desc = "alias for '#{([action_name] + args).join(' ')}'"
        s = format % [md.name, desc]
        #s = format % [md.name, md.desc]
        sb << decorate_str(s, md.hidden?, md.important?) << "\n"
      end
      return nil if sb.empty?
      return render_section(header(:HEADER_ALIASES), sb.join())  # "Aliases:"
    end

    def section_postamble(metadata)
      #; [!q1jee] returns postamble of help message if `postamble:` kwarg specified in `@action.()`.
      #; [!jajse] returns nil if postamble is not set.
      return render_sections(metadata.postamble, '@action.(postamble: "...")')
    end

  end


  APPLICATION_HELP_BUILDER_CLASS = ApplicationHelpBuilder
  ACTION_HELP_BUILDER_CLASS      = ActionHelpBuilder


  class GlobalOptionSchema < OptionSchema

    def initialize(config)
      super()
      setup(config)
    end

    def setup(config)
      #; [!umjw5] add nothing if config is nil.
      return if ! config
      #; [!ppcvp] adds options according to config object.
      c = config
      topics = ["action", "actions", "alias", "aliases",
                "category", "categories", "abbrev", "abbrevs",
                "category1", "categories1", "category2", "categories2",
                "category3", "categories3", "category4", "categories4",
                "metadata"]
      _add(c, :help   , "-h, --help"   , "print help message (of action if specified)")
      _add(c, :version, "-V, --version", "print version")
      _add(c, :list   , "-l, --list"   , "list actions and aliases")
      _add(c, :topic  , "-L <topic>"   , "topic list (actions|aliases|categories|abbrevs)", enum: topics)
      _add(c, :all    , "-a, --all"    , "list hidden actions/options, too")
      _add(c, :verbose, "-v, --verbose", "verbose mode")
      _add(c, :quiet  , "-q, --quiet"  , "quiet mode")
      _add(c, :color  , "--color[=<on|off>]", "color mode", type: TrueClass)
      _add(c, :debug  , "    --debug"  , "debug mode")
      _add(c, :trace  , "-T, --trace"  , "trace mode")
      _add(c, :dryrun , "-X, --dryrun" , "dry-run mode (not run; just echoback)")
    end

    def _add(c, key, optstr, desc, type: nil, enum: nil)
      flag = c.__send__("option_#{key}")
      return unless flag
      #; [!doj0k] if config option is `:hidden`, makes option as hidden.
      if flag == :hidden
        hidden = true
        optstr = optstr.sub(/^-\w, /, "    ")  # ex: "-T, --trace" -> "    --trace"
      else
        hidden = nil
      end
      add(key, optstr, desc, hidden: hidden, type: type, enum: enum)
    end
    private :_add

    def reorder_options(*keys)
      #; [!2cp9s] sorts options in order of keys specified.
      #; [!xe7e1] moves options which are not included in specified keys to end of option list.
      n = @items.length
      @items.sort_by! {|item| keys.index(item.key) || @items.index(item) + n }
      nil
    end

  end

  GLOBAL_OPTION_SCHEMA_CLASS = GlobalOptionSchema
  GLOBAL_OPTION_PARSER_CLASS = OptionParser


  class Application

    def initialize(config, global_option_schema=nil, app_help_builder=nil, action_help_builder=nil, _registry: REGISTRY)
      @config        = config
      @option_schema = global_option_schema || GLOBAL_OPTION_SCHEMA_CLASS.new(config)
      @_registry     = _registry
      @app_help_builder    = app_help_builder
      @action_help_builder = action_help_builder
    end

    attr_reader :config, :option_schema

    def inspect()
      return super.split().first() + ">"
    end

    def main(argv=ARGV)
      #; [!65e9n] returns `0` as status code.
      status_code = run(*argv)
      return status_code
    #rescue Benry::CmdOpt::OptionError => exc
    #  raise if $DEBUG_MODE
    #  print_error(exc)
    #  return 1
    #; [!bkbb4] when error raised...
    rescue StandardError => exc
      #; [!k4qov] not catch error if debug mode is enabled.
      raise if $DEBUG_MODE
      #; [!lhlff] catches error if BaseError raised or `should_rescue?()` returns true.
      raise if ! should_rescue?(exc)
      #; [!35x5p] prints error into stderr.
      print_error(exc)
      #; [!z39bh] prints backtrace unless error is a CommandError.
      print_backtrace(exc) if ! exc.is_a?(BaseError) || exc.should_report_backtrace?()
      #; [!dzept] returns `1` as status code.
      return 1
    end

    def run(*args)
      #; [!etbbc] calls setup method at beginning of this method.
      setup()
      #; [!hguvb] handles global options.
      global_opts = parse_global_options(args)  # raises OptionError
      toggle_global_options(global_opts)
      status_code = handle_global_options(global_opts, args)
      return status_code if status_code
      return handle_action(args, global_opts)
    ensure
      #; [!pf1d2] calls teardown method at end of this method.
      teardown()
    end

    def handle_action(args, global_opts)
      #; [!3qw3p] when no arguments specified...
      if args.empty?
        #; [!zl9em] lists actions if default action is not set.
        #; [!89hqb] lists all actions including hidden ones if `-a` or `--all` specified.
        if @config.default_action == nil
          return handle_blank_action(all: global_opts[:all])
        end
        #; [!k4xxp] runs default action if it is set.
        action = @config.default_action
      #; [!xaamy] when prefix specified...
      elsif args[0].end_with?(':')
        #; [!7l3fh] lists actions starting with prefix.
        #; [!g0k1g] lists all actions including hidden ones if `-a` or `--all` specified.
        prefix = args.shift()
        return handle_prefix(prefix, all: global_opts[:all])
      #; [!vphz3] else...
      else
        #; [!bq39a] runs action with arguments.
        action = args.shift()
      end
      #; [!5yd8x] returns 0 when action invoked successfully.
      return start_action(action, args)
    end
    protected :handle_action

    def render_help_message(action=nil, all: false)
      #; [!2oax5] returns action help message if action name is specified.
      #; [!d6veb] returns application help message if action name is not specified.
      #; [!tf2wp] includes hidden actions and options into help message if `all: true` passed.
      return render_action_help(action, all: all) if action
      return render_application_help(all: all)
    end

    protected

    def setup()
      #; [!6hi1y] stores current application.
      Benry::CmdApp._set_current_app(self)
    end

    def teardown()
      #; [!t44mv] removes current applicatin from data store.
      Benry::CmdApp._set_current_app(nil)
    end

    def parse_global_options(args)
      #; [!9c9r8] parses global options.
      parser = GLOBAL_OPTION_PARSER_CLASS.new(@option_schema)
      global_opts = parser.parse(args, all: false)  # raises OptionError
      return global_opts
    end

    def toggle_global_options(global_opts)
      #; [!xwcyl] sets `$VERBOSE_MODE` and `$QUIET_MODE` according to global options.
      d = global_opts
      if    d[:verbose] ; $VERBOSE_MODE = true ; $QUIET_MODE = false
      elsif d[:quiet]   ; $VERBOSE_MODE = false; $QUIET_MODE = true
      end
      #; [!510eb] sets `$COLOR_MODE` according to global option.
      $COLOR_MODE        = d[:color] if d[:color] != nil
      #; [!sucqp] sets `$DEBUG_MODE` according to global options.
      $DEBUG_MODE        = d[:debug] if d[:debug] != nil
      #; [!y9fow] sets `config.trace_mode` if global option specified.
      @config.trace_mode = d[:trace] if d[:trace] != nil
      #; [!dply7] sets `$DRYRUN_MODE` according to global option.
      $DRYRUN_MODE       = d[:dryrun] if d[:dryrun] != nil
      nil
    end

    def handle_global_options(global_opts, args)
      all = global_opts[:all]
      #; [!366kv] prints help message if global option `-h, --help` specified.
      #; [!7mapy] includes hidden actions into help message if `-a, --all` specified.
      if global_opts[:help]
        action = args.empty? ? nil : args[0]
        print_str render_action_help(action, all: all)   if action
        print_str render_application_help(all: all)  unless action
        return 0
      end
      #; [!dkjw8] prints version number if global option `-V, --version` specified.
      if global_opts[:version]
        print_str render_version()
        return 0
      end
      #; [!hj4hf] prints action and alias list if global option `-l, --list` specified.
      #; [!tyxwo] includes hidden actions into action list if `-a, --all` specified.
      if global_opts[:list]
        print_str render_item_list(nil, all: all)
        return 0
      end
      #; [!ooiaf] prints topic list if global option '-L <topic>' specified.
      #; [!ymifi] includes hidden actions into topic list if `-a, --all` specified.
      if global_opts[:topic]
        print_str render_topic_list(global_opts[:topic], all: all)
        return 0
      end
      #; [!k31ry] returns `0` if help or version or actions printed.
      #; [!9agnb] returns `nil` if do nothing.
      return nil       # do action
    end

    def render_action_help(action, all: false)
      #; [!c510c] returns action help message.
      metadata, _alias_args = @_registry.metadata_lookup(action)
      metadata  or
        raise CommandError.new("#{action}: Action not found.")
      builder = get_action_help_builder()
      return builder.build_help_message(metadata, all: all)
    end

    def render_application_help(all: false)
      #; [!iyxxb] returns application help message.
      builder = get_app_help_builder()
      return builder.build_help_message(@option_schema, all: all)
    end

    def render_version()
      #; [!bcp2g] returns version number string.
      return (@config.app_version || "?.?.?") + "\n"
    end

    def render_item_list(prefix=nil, all: false)
      builder = get_app_help_builder()
      case prefix
      #; [!tftl5] when prefix is not specified...
      when nil
        #; [!36vz6] returns action list string if any actions defined.
        #; [!znuy4] raises CommandError if no actions defined.
        s = builder.section_availables(all: all)  or
          raise CommandError.new("No actions defined.")
        return s
      #; [!jcq4z] when separator is specified...
      when /\A:+\z/
        #; [!w1j1e] returns top prefix list if ':' specified.
        #; [!bgput] returns two depth prefix list if '::' specified.
        #; [!tiihg] raises CommandError if no actions found having prefix.
        depth = prefix.length
        s = builder.section_categories(depth, all: all)  or
          raise CommandError.new("Prefix of actions not found.")
        return s
      #; [!xut9o] when prefix is specified...
      when /:\z/
        #; [!z4dqn] filters action list by prefix if specified.
        #; [!1834c] raises CommandError if no actions found with names starting with that prefix.
        s = builder.section_candidates(prefix, all: all)  or
          raise CommandError.new("No actions found with names starting with '#{prefix}'.")
        return s
      #; [!xjdrm] else...
      else
        #; [!9r4w9] raises ArgumentError.
        raise ArgumentError.new("#{prefix.inspect}: Invalid value as a prefix.")
      end
    end

    def render_topic_list(topic, all: false)
      #; [!uzmml] renders topic list.
      #; [!vrzu0] topic 'category1' or 'categories2' is acceptable.
      #; [!xyn5g] global option '-L metadata' renders registry data in YAML format.
      builder = get_app_help_builder()
      return (
        case topic
        when "action", "actions"; builder.section_actions(false, all: all)
        when "alias" , "aliases"; builder.section_aliases(all: all)
        when "abbrev", "abbrevs"; builder.section_abbrevs(all: all)
        when /\Acategor(?:y|ies)(\d+)?\z/ ; builder.section_categories(($1 || 0).to_i, all: all)
        when "metadata"; MetadataRenderer.new(@_registry).render_metadata()
        else raise "** assertion failed: topic=#{topic.inspect}"
        end
      )
    end

    def handle_blank_action(all: false)
      #; [!seba7] prints action list and returns `0`.
      print_str render_item_list(nil, all: all)
      return 0
    end

    def handle_prefix(prefix, all: false)
      #; [!8w301] prints action list starting with prefix and returns `0`.
      print_str render_item_list(prefix, all: all)
      return 0
    end

    def start_action(action_name, args)
      #; [!6htva] supports abbreviation of prefix.
      if ! @_registry.metadata_exist?(action_name)
        resolved = @_registry.abbrev_resolve(action_name)
        action_name = resolved if resolved
      end
      #; [!vbymd] runs action with args and returns `0`.
      @_registry.metadata_get(action_name)  or
        raise CommandError.new("#{action_name}: Action not found.")
      new_context().start_action(action_name, args)
      return 0
    end

    private

    def get_app_help_builder()
      return @app_help_builder || APPLICATION_HELP_BUILDER_CLASS.new(@config)
    end

    def get_action_help_builder()
      return @action_help_builder || ACTION_HELP_BUILDER_CLASS.new(@config)
    end

    def new_context()
      #; [!9ddcl] creates new context object with config object.
      return CONTEXT_CLASS.new(@config)
    end

    def print_str(str)
      #; [!yiabh] do nothing if str is nil.
      return nil unless str
      #; [!6kyv9] prints string as is if color mode is enabled.
      #; [!lxhvq] deletes escape characters from string and prints it if color mode is disabled.
      str = Util.delete_escape_chars(str) unless Util.color_mode?
      print str
      nil
    end

    def print_error(exc)
      #; [!sdbj8] prints exception as error message.
      #; [!6z0mu] prints colored error message if stderr is a tty.
      #; [!k1s3o] prints non-colored error message if stderr is not a tty.
      prompt = "[ERROR]"
      prompt = @config.deco_error % prompt if $stderr.tty?
      $stderr.puts "#{prompt} #{exc.message}"
      nil
    end

    def print_backtrace(exc)
      cache = {}    # {filename => [line]}
      color_p = $stderr.tty?
      sb = []
      exc.backtrace().each do |bt|
        #; [!i010e] skips backtrace in `benry/cmdapp.rb`.
        next if bt.start_with?(__FILE__)
        #; [!ilaxg] skips backtrace if `#skip_backtrace?()` returns truthy value.
        next if skip_backtrace?(bt)
        #; [!5sa5k] prints filename and line number in slant format if stdout is a tty.
        s = "From #{bt}"
        s = "\e[3m#{s}\e[0m" if color_p   # slant
        sb << "    #{s}\n"
        if bt =~ /:(\d+)/
          #; [!2sg9r] not to try to read file content if file not found.
          fname = $`; lineno = $1.to_i
          next unless File.exist?(fname)
          #; [!ihizf] prints lines of each backtrace entry.
          cache[fname] ||= read_file_as_lines(fname)
          line = cache[fname][lineno - 1]
          sb << "        #{line.strip()}\n" if line
        end
      end
      #; [!8wzxg] prints backtrace of exception.
      $stderr.print sb.join()
      cache.clear()
      nil
    end

    def skip_backtrace?(bt)
      #; [!r2fmv] ignores backtraces if matched to 'config.backtrace_ignore_rexp'.
      #; [!c6f11] not ignore backtraces if 'config.backtrace_ignore_rexp' is not set.
      rexp = @config.backtrace_ignore_rexp
      return rexp ? bt =~ rexp : false
    end

    def read_file_as_lines(filename)
      #; [!e9c74] reads file content as an array of line.
      return File.read(filename, encoding: 'utf-8').each_line().to_a()
    end

    protected

    def should_rescue?(exc)
      #; [!8lwyn] returns trueif exception is a BaseError.
      return exc.is_a?(BaseError)
    end

  end


  class MetadataRenderer

    def initialize(registry)
      @registry = registry
    end

    def render_metadata(all: false)
      #; [!gduge] renders registry data in YAML format.
      sb = []
      sb << "actions:\n"
      render_actions(all: all) {|s| sb << s }
      sb << "\n"
      sb << "aliases:\n"
      render_aliases(all: all) {|s| sb << s }
      sb << "\n"
      sb << "categories:\n"
      render_categories(all: all) {|s| sb << s }
      sb << "\n"
      sb << "abbreviations:\n"
      render_abbrevs() {|s| sb << s }
      return sb.join()
    end

    protected

    def render_actions(all: false, &b)
      @registry.metadata_each(all: all) do |metadata|
        md = metadata
        if ! md.alias?
          yield "  - action:    #{md.name}\n"
          yield "    desc:      #{qq(md.desc)}\n"
          yield "    class:     #{md.klass.name}\n"
          yield "    method:    #{md.meth}\n"
          yield "    usage:     #{md.usage.inspect}\n" if md.usage
          yield "    detail:    #{md.detail.inspect}\n" if md.detail
          yield "    description: #{md.description.inspect}\n" if md.description
          yield "    postamble: #{md.postamble.inspect.gsub(/"=>"/, '": "')}\n" if md.postamble
          yield "    tag:       #{md.tag}\n" if md.tag
          yield "    important: #{md.important}\n" if md.important? != nil
          yield "    hidden:    #{md.hidden?}\n" if md.hidden? != nil
          obj = md.klass.new(nil)
          paramstr = Util.method2help(obj, md.meth).strip
          if ! paramstr.empty?
            yield "    paramstr:  #{qq(paramstr)}\n"
            yield "    parameters:\n"
            render_parameters(md, all: all, &b)
          end
          if ! md.schema.empty?
            yield "    options:\n"
            render_options(md, all: all, &b)
          end
        end
      end
    end

    def render_parameters(metadata, all: false)
      obj = metadata.klass.new(nil)
      obj.method(metadata.meth).parameters.each do |ptype, pname|
        yield "      - param:   #{pname}\n"
        yield "        type:    #{ptype}\n"
      end
    end

    def render_options(metadata, all: false)
      metadata.schema.each() do |item|
        next if all == false && item.hidden?
        yield "      - key:     #{item.key}\n"
        yield "        desc:    #{qq(item.desc)}\n"
        yield "        optdef:  #{qq(item.optdef)}\n"
        yield "        short:   #{item.short}\n" if item.short
        yield "        long:    #{item.long}\n"  if item.long
        yield "        param:   #{qq(item.param)}\n" if item.param
        yield "        paramreq: #{item.arg_requireness}\n"
        yield "        type:    #{item.type.name}\n" if item.type
        yield "        rexp:    #{item.rexp.inspect}\n" if item.rexp
        yield "        enum:    #{item.enum.inspect}\n" if item.enum
        yield "        range:   #{item.range.inspect}\n" if item.range
        yield "        value:   #{item.value.inspect}\n" if item.value != nil
        yield "        detail:  #{item.detail.inspect}\n" if item.detail != nil
        yield "        tag:     #{item.tag}\n" if item.tag
        yield "        important: #{item.important}\n" if item.important? != nil
        yield "        hidden:  #{item.hidden?}\n" if item.hidden? != nil
      end
    end

    def render_aliases(all: false)
      @registry.metadata_each(all: all) do |metadata|
        md = metadata
        if md.alias?
          yield "  - alias:     #{md.name}\n"
          yield "    desc:      #{qq(md.desc)}\n"
          yield "    action:    #{md.action}\n"
          yield "    args:      #{md.args.inspect}\n" if md.args && ! md.args.empty?
          yield "    tag:       #{md.tag}\n" if md.tag
          yield "    important: #{md.important}\n" if md.important != nil
          yield "    hidden:    #{md.hidden?}\n" if md.hidden? != nil
        end
      end
    end

    def render_categories(all: false)
      dict = @registry.category_count_actions(0, all: all)
      @registry.category_each do |prefix, desc|
        yield "  - prefix:    \"#{prefix}\"\n"
        yield "    count:     #{dict[prefix] || 0}\n"
        yield "    desc:      #{qq(desc)}\n" if desc
      end
    end

    def render_abbrevs()
      @registry.abbrev_each do |abbrev, prefix|
        yield "  - abbrev:    \"#{abbrev}\"\n"
        yield "    prefix:    \"#{prefix}\"\n"
      end
    end

    private

    def qq(s)
      return "" if s.nil?
      return '"' + s.gsub(/"/, '\\"') + '"'
    end

  end


  def self.main(app_desc, app_version=nil, **kwargs)
    #; [!6mfxt] accepts the same arguments as 'Config#initialize()'.
    config = Config.new(app_desc, app_version, **kwargs)
    #; [!scpwa] runs application.
    app = Application.new(config)
    #; [!jbv9z] returns the status code.
    status_code = app.main()
    return status_code
  end


end
