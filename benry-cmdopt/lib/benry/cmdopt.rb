# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2021 kwatch@gmail.com $
### $License: MIT License $
###

require 'date'
require 'set'


module Benry
end


##
## Command option parser.
##
## See: https://github.com/kwatch/benry-ruby/tree/main/benry-cmdopt
##
module Benry::CmdOpt


  VERSION = '$Release: 0.0.0 $'.split()[1]


  def self.new()
    #; [!7kkqv] creates Facade object.
    return Facade.new
  end


  class Facade

    def initialize()
      @schema = SCHEMA_CLASS.new
    end

    attr_reader :schema

    def add(key, optdef, desc, *rest, type: nil, rexp: nil, pattern: nil, enum: nil, range: nil, value: nil, multiple: nil, detail: nil, hidden: nil, important: nil, tag: nil, &callback)
      rexp ||= pattern    # for backward compatibility
      #; [!vmb3r] defines command option.
      #; [!71cvg] type, rexp, enum, and range are can be passed as positional args as well as keyword args.
      @schema.add(key, optdef, desc, *rest,
                  type: type, rexp: rexp, enum: enum, range: range, value: value, multiple: multiple, detail: detail, hidden: hidden, important: important, tag: tag, &callback)
      #; [!tu4k3] returns self.
      self
    end

    def option_help(width_or_format=nil, all: false)
      #; [!dm4p8] returns option help message.
      return @schema.option_help(width_or_format, all: all)
    end

    #; [!s61vo] '#to_s' is an alias to '#option_help()'.
    alias to_s option_help

    def each_option_and_desc(all: false, &block)
      #; [!wght5] returns enumerator object if block not given.
      return @schema.each_option_and_desc(all: all) unless block_given?()
      #; [!bw9qx] yields each option definition string and help message.
      #; [!kunfw] yields all items (including hidden items) if `all: true` specified.
      @schema.each_option_and_desc(all: all, &block)
      self
    end
    alias each_option_help each_option_and_desc   # for backward compatibility

    def parse(argv, all: true, &error_handler)
      #; [!7gc2m] parses command options.
      #; [!no4xu] returns option values as dict.
      #; [!areof] handles only OptionError when block given.
      #; [!peuva] returns nil when OptionError handled.
      #; [!za9at] parses options only before args when `all: false`.
      parser = PARSER_CLASS.new(@schema)
      return parser.parse(argv, all: all, &error_handler)
    end

  end


  class Schema

    def initialize()
      @items = []
    end

    def dup()
      #; [!lxb0o] copies self object.
      other = self.class.new
      other.instance_variable_set(:@items, @items.dup)
      return other
    end

    def copy_from(other, except: [])
      #; [!6six3] copy schema items from others.
      #; [!vt88s] copy schema items except items specified by 'except:' kwarg.
      except = [except].flatten()
      other.each do |item|
        @items << item unless except.include?(item.key)
      end
      self
    end

    def add(key, optdef, desc, *rest, type: nil, rexp: nil, pattern: nil, enum: nil, range: nil, value: nil, multiple: nil, detail: nil, hidden: nil, important: nil, tag: nil, &callback)
      rexp ||= pattern    # for backward compatibility
      #; [!kuhf9] type, rexp, enum, and range are can be passed as positional args as well as keyword args.
      rest.each do |x|
        case x
        when Class      ; type ||= x
        when Regexp     ; rexp ||= x
        when Array, Set ; enum ||= x
        when Range      ; range ||= x
        else
          #; [!e3emy] raises error when positional arg is not one of class, regexp, array, nor range.
          raise _error("#{x.inspect}: Expected one of class, regexp, array or range, but got #{x.class.name}.")
        end
      end
      #; [!rhhji] raises SchemaError when key is not a Symbol.
      key.nil? || key.is_a?(Symbol)  or
        raise _error("add(#{key.inspect}, #{optdef.inspect}): The first arg should be a Symbol as an option key.")
      #; [!vq6eq] raises SchemaError when help message is missing.
      desc.nil? || desc.is_a?(String)  or
        raise _error("add(#{key.inspect}, #{optdef.inspect}): Help message required as 3rd argument.")
      #; [!7hi2d] takes command option definition string.
      short, long, param, required = parse_optdef(optdef)
      #; [!p9924] option key is omittable only when long option specified.
      #; [!jtp7z] raises SchemaError when key is nil and no long option.
      key || long  or
        raise _error("add(#{key.inspect}, #{optdef.inspect}): Long option required when option key (1st arg) not specified.")
      #; [!rpl98] when long option is 'foo-bar' then key name is ':foo_bar'.
      key ||= long.gsub(/-/, '_').intern
      #; [!97sn0] raises SchemaError when ',' is missing between short and long options.
      if long.nil? && param =~ /\A--/
        raise _error("add(#{key.inspect}, #{optdef.inspect}): Missing ',' between short option and long options.")
      end
      #; [!yht0v] keeps command option definitions.
      item = SchemaItem.new(key, optdef, desc, short, long, param, required,
                 type: type, rexp: rexp, enum: enum, range: range, value: value, multiple: multiple, detail: detail, hidden: hidden, important: important, tag: tag, &callback)
      add_item(item)
      item
    end

    def add_item(item)
      #; [!qyjp9] raises SchemaError if invalid item added.
      errmsg = _validate_item(item)
      errmsg == nil  or
        raise SchemaError.new(errmsg)
      #; [!a693h] adds option item into current schema.
      @items << item
      self
    end

    def _validate_item(item)
      key = item.key; short = item.short; long = item.long
      for x in @items
        #; [!ewl20] returns error message if option key duplicated.
        key != x.key  or
          return "#{key}: Option key duplicated."
        #; [!xg56v] returns error message if short option duplicated.
        short == nil || short != x.short  or
          return "-#{short}: Short option duplicated (key: #{key} and #{x.key})."
        #; [!izezi] returns error message if long option duplicated.
        long == nil || long != x.long  or
          return "--#{long}: Long option duplicated (key: #{key} and #{x.key})."
      end
      return nil
    end
    private :_validate_item

    def option_help(width_or_format=nil, all: false)
      #; [!0aq0i] can take integer as width.
      #; [!pcsah] can take format string.
      #; [!dndpd] detects option width automatically when nothing specified.
      case width_or_format
      when nil    ; format = _default_format()
      when Integer; format = "  %-#{width_or_format}s : %s"
      when String ; format = width_or_format
      else
        raise ArgumentError.new("#{width_or_format.inspect}: Width (integer) or format (string) expected.")
      end
      #; [!v7z4x] skips option help if help message is not specified.
      #; [!to1th] includes all option help when `all` is true.
      #; [!a4qe4] option should not be hidden if description is empty string.
      sb = []
      width = nil; indent = nil; color_p = $stdout.tty?
      @items.each do |item|
        next if ! all && item.hidden?
        #; [!jrwb6] decorates help message according to `important:` value of option.
        #; [!9nlfb] not decorate help message when stdout is not a tty.
        s = format % [item.optdef, item.desc || ""]
        s = _decorate_str(s, item.important?) if color_p
        sb << s << "\n"
        #; [!848rm] supports multi-lines help message.
        detail = item.detail
        if detail
          width  ||= (format % ['', '']).length
          indent ||= ' ' * width
          sb << detail.gsub(/^/, indent)
          sb << "\n" unless detail.end_with?("\n")
        end
      end
      return sb.join()
    end

    #; [!rrapd] '#to_s' is an alias to '#option_help()'.
    alias to_s option_help

    def each_option_and_desc(all: false, &block)
      #; [!03sux] returns enumerator object if block not given.
      return to_enum(:each_option_and_desc, all: all) unless block_given?()
      #; [!4b911] yields each optin definition str and help message.
      @items.each do |item|
        #; [!cl8zy] when 'all' flag is false, not yield hidden items.
        #; [!tc4bk] when 'all' flag is true, yields even hidden items.
        yield item.optdef, item.desc, item.detail if all || ! item.hidden?
      end
      #; [!zbxyv] returns self.
      self
    end
    alias each_option_help each_option_and_desc   # for backward compatibility

    def each(&block)   # :nodoc:
      #; [!y4k1c] yields each option item.
      @items.each(&block)
    end

    def empty?(all: true)
      #; [!um8am] returns false if any item exists, else returns true.
      #; [!icvm1] ignores hidden items if 'all: false' kwarg specified.
      @items.each {|item| return false if all || ! item.hidden? }
      return true
    end

    def get(key)
      #; [!3wjfp] finds option item object by key.
      #; [!0spll] returns nil if key not found.
      return @items.find {|item| item.key == key }
    end

    def delete(key)
      #; [!l86rb] deletes option item corresponding to key.
      #; [!rq0aa] returns deleted item.
      item = get(key)
      @items.delete_if {|item| item.key == key }
      return item
    end

    def find_short_option(short)
      #; [!b4js1] returns option definition matched to short name.
      #; [!s4d1y] returns nil when nothing found.
      return @items.find {|item| item.short == short }
    end

    def find_long_option(long)
      #; [!atmf9] returns option definition matched to long name.
      #; [!6haoo] returns nil when nothing found.
      return @items.find {|item| item.long == long }
    end

    private

    def _error(msg)
      return SchemaError.new(msg)
    end

    def parse_optdef(optdef)
      #; [!qw0ac] parses command option definition string.
      #; [!ae733] parses command option definition which has a required param.
      #; [!4h05c] parses command option definition which has an optional param.
      #; [!b7jo3] raises SchemaError when command option definition is invalid.
      case optdef
      when /\A[ \t]*-(\w),[ \t]*--(\w[-\w]*)(?:=(\S*?)|\[=(\S*?)\])?\z/
        short, long, param1, param2 = $1, $2, $3, $4
      when /\A[ \t]*-(\w)(?:[ \t]+(\S+)|\[(\S+)\])?\z/
        short, long, param1, param2 = $1, nil, $2, $3
      when /\A[ \t]*--(\w[-\w]*)(?:=(\S*?)|\[=(\S*?)\])?\z/
        short, long, param1, param2 = nil, $1, $2, $3
      when /(--\w[-\w])*[ \t]+(\S+)/
        raise _error("#{optdef}: Invalid option definition (use '#{$1}=#{$2}' instead of '#{$1} #{$2}').")
      else
        raise _error("#{optdef}: Invalid option definition.")
      end
      required = param1 ? true : param2 ? false : nil
      return short, long, (param1 || param2), required
    end

    def _default_format(min_width=nil, max_width=35)
      #; [!bmr7d] changes min_with according to options.
      min_width ||= _preferred_option_width()
      #; [!hr45y] detects preffered option width.
      w = 0
      each_option_help do |opt, _|
        w = opt.length if w < opt.length
      end
      w = min_width if w < min_width
      w = max_width if w > max_width
      #; [!kkh9t] returns format string.
      return "  %-#{w}s : %s"
    end

    def _preferred_option_width()
      #; [!kl91t] shorten option help min width when only single options which take no arg.
      #; [!0koqb] widen option help min width when any option takes an arg.
      #; [!kl91t] widen option help min width when long option exists.
      long_p  = @items.any? {|x| x.desc &&  x.long &&  x.param }
      short_p = @items.all? {|x| x.desc && !x.long && !x.param }
      return short_p ? 8 : long_p ? 20 : 14
    end

    def _decorate_str(str, important)
      case important
      when true  ; return "\e[1m#{str}\e[0m"  # bold
      when false ; return "\e[2m#{str}\e[0m"  # gray
      else       ; return str
      end
    end

  end


  class SchemaItem    # avoid Struct

    def initialize(key, optdef, desc, short, long, param, required, type: nil, rexp: nil, pattern: nil, enum: nil, range: nil, value: nil, multiple: nil, detail: nil, hidden: nil, important: nil, tag: nil, &callback)
      rexp ||= pattern    # for backward compatibility
      _init_validation(param, required, type, rexp, enum, range, value)
      @key      = key       unless nil == key
      @optdef   = optdef    unless nil == optdef
      @desc     = desc      unless nil == desc
      @short    = short     unless nil == short
      @long     = long      unless nil == long
      @param    = param     unless nil == param
      @required = required  unless nil == required
      @type     = type      unless nil == type
      @rexp     = rexp      unless nil == rexp
      @enum     = enum      unless nil == enum
      @range    = range     unless nil == range
      @value    = value     unless nil == value
      @multiple = multiple  unless nil == multiple
      @detail   = detail    unless nil == detail
      @hidden   = hidden    unless nil == hidden
      @important = important unless nil == important
      @tag      = tag       unless nil == tag
      @callback = callback  unless nil == callback
      #; [!nn4cp] freezes enum object.
      @enum.freeze() if @enum
    end

    attr_reader :key, :optdef, :desc, :short, :long, :param, :type, :rexp, :enum, :range, :value, :detail, :tag, :callback
    attr_writer :desc, :detail, :hidden, :important, :tag    # !!experimental!!
    alias pattern rexp   # for backward compatibility
    alias help desc      # for backward compatibility

    def required?()
      #; [!svxny] returns nil if option takes no arguments.
      #; [!uwbgc] returns false if argument is optional.
      #; [!togcx] returns true if argument is required.
      return ! @param ? nil : !! @required
    end

    def arg_requireness()
      #; [!kmo28] returns :none if option takes no arguments.
      #; [!owpba] returns :optional if argument is optional.
      #; [!s8gxl] returns :required if argument is required.
      return :none     if ! @param
      return :required if @required
      return :optional
    end

    def multiple?()
      #; [!1lj8v] returns true if @multiple is truthy.
      #; [!cun23] returns false if @multiple is falthy.
      return !! @multiple
    end

    def hidden?()
      #; [!no6ov] returns true if @hidden is true.
      #; [!ej8ot] returns false if @hidden is false.
      return @hidden if @hidden != nil
      #; [!h0uxs] returns true if desc is nil.
      #; [!28vzx] returns false if else.
      return @desc == nil
    end

    def important?()
      #; [!ua8kt] returns true/false if `important:` kwarg passed to constructor.
      #; [!hz9sx] returns nil if `important:` kwarg not passed to constructor.
      return @important
    end

    def validate_and_convert(val, optdict)
      #; [!h0s0o] raises RuntimeError when value not matched to pattern.
      if @rexp && val != true
        val =~ @rexp  or
          raise "Pattern unmatched."
      end
      #; [!j4fuz] calls type-specific callback when type specified.
      if @type && val != true
        proc_ = PARAM_TYPES[@type]
        val = proc_.call(val)
      end
      #; [!5jrdf] raises RuntimeError when value not in enum.
      if @enum && val != true
        @enum.include?(val)  or
          raise "Expected one of #{@enum.join('/')}."
      end
      #; [!5falp] raise RuntimeError when value not in range.
      #; [!a0rej] supports endless range.
      if @range && val != true
        r = @range
        r.begin == nil || r.begin <= val  or (
          raise "Positive value (>= 0) expected." if r.begin == 0
          raise "Positive value (>= 1) expected." if r.begin == 1
          raise "Too small (min: #{r.begin.inspect})"
        )
        r.end == nil || val <= r.end  or
          raise "Too large (max: #{r.end.inspect})"
      end
      #; [!jn9z3] calls callback when callback specified.
      #; [!iqalh] calls callback with different number of args according to arity.
      if @callback
        n_args = @callback.arity
        val = n_args == 1 ? @callback.call(val) \
                          : @callback.call(optdict, @key, val)
      end
      #; [!eafem] returns default value (if specified) instead of true value.
      return @value if val == true && @value != nil
      #; [!x066l] returns new value.
      return val
    end

    private

    def _error(msg)
      return SchemaError.new(msg)
    end

    def _init_validation(param, required, type, rexp, enum, range, value)
      #; [!wy2iv] when 'type:' specified...
      if type
        #; [!7xmr5] raises SchemaError when type is not registered.
        PARAM_TYPES.key?(type)  or
          raise _error("#{type.inspect}: Unregistered type.")
        #; [!s2aaj] raises SchemaError when option has no params but type specified.
        #; [!sz8x2] not raise error when no params but value specified.
        #; [!70ogf] not raise error when no params but TrueClass specified.
        param || value != nil || type == TrueClass  or
          raise _error("#{type.inspect}: Type specified in spite of option has no params.")
      end
      #; [!6y8s2] when 'rexp:' specified...
      if rexp
        #; [!bi2fh] raises SchemaError when pattern is not a regexp.
        rexp.is_a?(Regexp)  or
          raise _error("#{rexp.inspect}: Regexp pattern expected.")
        #; [!01fmt] raises SchmeaError when option has no params but pattern specified.
        param  or
          raise _error("#{rexp.inspect}: Regexp pattern specified in spite of option has no params.")
      end
      #; [!5nrvq] when 'enum:' specified...
      if enum
        #; [!melyd] raises SchemaError when enum is not an Array nor Set.
        enum.is_a?(Array) || enum.is_a?(Set)  or
          raise _error("#{enum.inspect}: Array or set expected.")
        #; [!xqed8] raises SchemaError when enum specified for no param option.
        param  or
          raise _error("#{enum.inspect}: Enum specified in spite of option has no params.")
        #; [!zuthh] raises SchemaError when enum element value is not instance of type class.
        enum.each do |x|
          x.is_a?(type)  or
            raise _error("#{enum.inspect}: Enum element value should be instance of #{type.name}, but #{x.inspect} is not.")
        end if type
      end
      #; [!hk4nw] when 'range:' specified...
      if range
        #; [!z20ky] raises SchemaError when range is not a Range object.
        range.is_a?(Range)  or
          raise _error("#{range.inspect}: Range object expected.")
        #; [!gp025] raises SchemaError when range specified with `type: TrueClass`.
        if type == TrueClass
          raise _error("#{range.inspect}: Range is not available with `type: TrueClass`.")
        #; [!7njd5] range beginning/end value should be expected type.
        else
          #; [!uymig] range object can be endless.
          type_ = type || String
          ok1 = range.begin == nil || range.begin.is_a?(type_)
          ok2 = range.end   == nil || range.end.is_a?(type_)
          ok1 && ok2  or
            raise _error("#{range.inspect}: Range value should be #{type_.name}, but not.")
        end
      end
      #; [!a0g52] when 'value:' specified...
      if value != nil
        #; [!435t6] raises SchemaError when 'value:' is specified on argument-required option.
        ! required  or
          raise _error("#{value.inspect}: 'value:' is meaningless when option has required argument (hint: change to optional argument instead).")
        if type == TrueClass
          #; [!6vwqv] raises SchemaError when type is TrueClass but value is not true nor false.
          value == true || value == false  or
            raise _error("#{value.inspect}: Value should be true or false when `type: TrueClass` specified.")
        elsif type
          #; [!c6i2o] raises SchemaError when value is not a kind of type.
          value.is_a?(type)  or
            raise _error("Type mismatched between `type: #{type.name}` and `value: #{value.inspect}`.")
        else
          #; [!lnhp6] not raise error when type is not specified.
        end
        if enum
          #; [!6xb8o] value should be included in enum values.
          enum.include?(value)  or
            raise _error("#{value}: Value should be included in enum values, but not.")
        end
      end
    end

  end


  PARAM_TYPES = {
    String => proc {|val|
      val
    },
    Integer => proc {|val|
      #; [!6t8cs] converts value into integer.
      #; [!nzwc9] raises error when failed to convert value into integer.
      val =~ /\A[-+]?\d+\z/  or
        raise "Integer expected."
      val.to_i
    },
    Float => proc {|val|
      #; [!gggy6] converts value into float.
      #; [!t4elj] raises error when faield to convert value into float.
      val =~ /\A[-+]?(\d+\.\d*|\.\d+)\z/  or
        raise "Float expected."
      val.to_f
    },
    TrueClass => proc {|val|
      #; [!47kx4] converts 'true'/'on'/'yes' into true.
      #; [!3n810] converts 'false'/'off'/'no' into false.
      #; [!h8ayh] raises error when failed to convert value into true nor false.
      case val
      when /\A(?:true|on|yes)\z/i  ; true
      when /\A(?:false|off|no)\z/i ; false
      else
        raise "Boolean expected."
      end
    },
    Date => proc {|val|
      #; [!sru5j] converts 'YYYY-MM-DD' into date object.
      #; [!h9q9y] raises error when failed to convert into date object.
      #; [!i4ui8] raises error when specified date not exist.
      val =~ /\A(\d\d\d\d)-(\d\d?)-(\d\d?)\z/  or
        raise "Invalid date format (ex: '2000-01-01')"
      begin
        Date.new($1.to_i, $2.to_i, $3.to_i)
      rescue ArgumentError => ex
        raise "Date not exist."
      end
    },
  }


  class Parser

    def initialize(schema)
      @schema = schema
    end

    def parse(argv, all: true, &error_handler)
      optdict = new_options_dict()
      index = 0
      while index < argv.length
        #; [!5s5b6] treats '-' as an argument, not an option.
        if argv[index] =~ /\A-/ && argv[index] != "-"
          optstr = argv.delete_at(index)
        #; [!q8356] parses options even after arguments when `all: true`.
        elsif all
          index += 1
          next
        #; [!ryra3] doesn't parse options after arguments when `all: false`.
        else
          break
        end
        #; [!y04um] skips rest options when '--' found in argv.
        if optstr == '--'
          break
        elsif optstr =~ /\A--/
          #; [!uh7j8] parses long options.
          parse_long_option(optstr, optdict)
        else
          #; [!nwnjc] parses short options.
          parse_short_options(optstr, optdict) { argv.delete_at(index) }
        end
      end
      #; [!3wmsy] returns command option values as a dict.
      return optdict
    rescue OptionError => ex
      #; [!qpuxh] handles only OptionError when block given.
      raise unless block_given?()
      yield ex
      #; [!dhpw1] returns nil when OptionError handled.
      nil
    end

    def _error(msg)
      return OptionError.new(msg)
    end

    protected

    def parse_long_option(optstr, optdict)
      #; [!3i994] raises OptionError when invalid long option format.
      optstr =~ /\A--(\w[-\w]*)(?:=(.*))?\z/  or
        raise _error("#{optstr}: Invalid long option.")
      name = $1; val = $2
      #; [!1ab42] invokes error handler method when unknown long option.
      #; [!er7h4] default behavior is to raise OptionError when unknown long option.
      item = @schema.find_long_option(name)  or
        return handle_unknown_long_option(optstr, name, val)
      #; [!2jd9w] raises OptionError when no arguments specified for arg required long option.
      #; [!qyq8n] raises optionError when an argument specified for no arg long option.
      case item.arg_requireness()
      when :none         # no arguments
        val == nil  or raise _error("#{optstr}: Unexpected argument.")
      when :required     # argument required
        val  or raise _error("#{optstr}: Argument required.")
      when :optional     # optonal argument
        # do nothing
      else
        raise "** internal error"
      end
      #; [!o596x] validates argument value.
      val ||= true
      begin
        val = item.validate_and_convert(val, optdict)
      rescue RuntimeError => ex
        raise _error("#{optstr}: #{ex.message}")
      end
      #; [!1m87b] supports multiple option.
      store_option_value(optdict, item, val)
    end

    def parse_short_options(optstr, optdict, &block)
      n = optstr.length
      i = 0
      while (i += 1) < n
        char = optstr[i]
        #; [!4eh49] raises OptionError when unknown short option specified.
        item = @schema.find_short_option(char)  or
          raise _error("-#{char}: Unknown option.")
        #
        case item.arg_requireness()
        when :none         # no arguments
          val = true
        when :required     # argument required
          #; [!utdbf] raises OptionError when argument required but not specified.
          #; [!f63hf] short option arg can be specified without space separator.
          val = i+1 < n ? optstr[(i+1)..-1] : yield  or
            raise _error("-#{char}: Argument required.")
          i = n
        when :optional     # optonal argument
          #; [!yjq6b] optional arg should be specified without space separator.
          #; [!wape4] otpional arg can be omit.
          val = i+1 < n ? optstr[(i+1)..-1] : true
          i = n
        else
          raise "** internal error"
        end
        #; [!yu0kc] validates short option argument.
        begin
          val = item.validate_and_convert(val, optdict)
        rescue RuntimeError => ex
          if val == true
            raise _error("-#{char}: #{ex.message}")
          else
            sp = item.required? ? ' ' : ''
            raise _error("-#{char}#{sp}#{val}: #{ex.message}")
          end
        end
        #; [!187r2] supports multiple option.
        store_option_value(optdict, item, val)
      end
    end

    def new_options_dict()
      #; [!vm6h0] returns new hash object.
      return OPTIONS_CLASS.new
    end

    def store_option_value(optdict, item, val)
      #; [!my86j] stores multiple values if multiple option item.
      if item.multiple?
        (optdict[item.key] ||= []) << val
      #; [!tm7xw] stores singile value if not multiple option item.
      else
        optdict[item.key] = val
      end
    end

    def handle_unknown_long_option(optstr, name, val)
      #; [!0q78a] raises OptionError.
      raise _error("#{optstr}: Unknown long option.")
    end

  end


  OPTIONS_CLASS = Hash
  SCHEMA_CLASS  = Schema
  PARSER_CLASS  = Parser


  class SchemaError < StandardError
  end


  class OptionError < StandardError
  end


end


module Benry
  Cmdopt = CmdOpt         # for backawrd compatibility
end
