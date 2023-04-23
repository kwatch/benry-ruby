# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require 'date'
require 'set'


module Benry


  ##
  ## Command option parser.
  ##
  ## See: https://github.com/kwatch/benry-ruby/tree/ruby/benry-cmdopt
  ##
  module CmdOpt


    VERSION = '$Release: 0.0.0 $'.split()[1]


    def self.new
      #; [!7kkqv] creates Facade object.
      return Facade.new
    end


    class Facade

      def initialize
        @schema = SCHEMA_CLASS.new
      end

      def dup()
        #; [!mf5cz] copies self object.
        other = self.class.new
        other.instance_variable_set(:@schema, @schema.dup)
        return other
      end

      def add(key, optdef, desc, *rest, type: nil, rexp: nil, pattern: nil, enum: nil, value: nil, &callback)
        rexp ||= pattern    # for backward compatibility
        #; [!vmb3r] defines command option.
        #; [!71cvg] type, rexp, and enum are can be passed as positional args as well as keyword args.
        @schema.add(key, optdef, desc, *rest, type: type, rexp: rexp, enum: enum, value: value, &callback)
        #; [!tu4k3] returns self.
        self
      end

      def option_help(width_or_format=nil, all: false)
        #; [!dm4p8] returns option help message.
        return @schema.option_help(width_or_format, all: all)
      end

      #; [!s61vo] '#to_s' is an alias to '#option_help()'.
      alias to_s option_help

      def each_option_and_desc(&block)
        #; [!bw9qx] yields each option definition string and help message.
        @schema.each_option_and_desc(&block)
        self
      end
      alias each_option_help each_option_and_desc   # for backward compatibility

      def each(&block)   # :nodoc:
        #; [!knh44] yields each option item.
        @schema.each(&block)
      end

      def parse(argv, parse_all=true, &error_handler)
        #; [!7gc2m] parses command options.
        #; [!no4xu] returns option values as dict.
        #; [!areof] handles only OptionError when block given.
        #; [!peuva] returns nil when OptionError handled.
        #; [!za9at] parses options only before args when `parse_all=false`.
        parser = PARSER_CLASS.new(@schema)
        return parser.parse(argv, parse_all, &error_handler)
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

      def add(key, optdef, desc, *rest, type: nil, rexp: nil, pattern: nil, enum: nil, value: nil, &callback)
        rexp ||= pattern    # for backward compatibility
        #; [!kuhf9] type, rexp, and enum are can be passed as positional args as well as keyword args.
        rest.each do |x|
          case x
          when Class      ; type ||= x
          when Regexp     ; rexp ||= x
          when Array, Set ; enum ||= x
          else
            #; [!e3emy] raises error when positional arg is not one of class, regexp, nor array.
            raise error("#{x.inspect}: expected one of class, regexp, or array, but got #{x.class.name}.")
          end
        end
        #; [!rhhji] raises SchemaError when key is not a Symbol.
        key.nil? || key.is_a?(Symbol)  or
          raise error("add(#{key.inspect}): 1st arg should be a Symbol as an option key.")
        #; [!vq6eq] raises SchemaError when help message is missing."
        desc.nil? || desc.is_a?(String)  or
          raise error("add(#{key.inspect}, #{optdef.inspect}): help message required as 3rd argument.")
        #; [!7hi2d] takes command option definition string.
        short, long, param, required = parse_optdef(optdef)
        #; [!p9924] option key is omittable only when long option specified.
        #; [!jtp7z] raises SchemaError when key is nil and no long option.
        key || long  or
          raise error("add(#{key.inspect}, #{optdef.inspect}): long option required when option key (1st arg) not specified.")
        key ||= long.gsub(/-/, '_').intern
        #; [!97sn0] raises SchemaError when ',' is missing between short and long options.
        if long.nil? && param =~ /\A--/
          raise error("add(#{key.inspect}, #{optdef.inspect}): missing ',' between short option and long options.")
        end
        #; [!7xmr5] raises SchemaError when type is not registered.
        #; [!s2aaj] raises SchemaError when option has no params but type specified.
        if type
          PARAM_TYPES.key?(type)  or
            raise error("#{type.inspect}: unregistered type.")
          param  or
            raise error("#{type.inspect}: type specified in spite of option has no params.")
        end
        #; [!bi2fh] raises SchemaError when pattern is not a regexp.
        #; [!01fmt] raises SchmeaError when option has no params but pattern specified.
        if rexp
          rexp.is_a?(Regexp)  or
            raise error("#{rexp.inspect}: regexp pattern expected.")
          param  or
            raise error("#{rexp.inspect}: regexp pattern specified in spite of option has no params.")
        end
        #; [!melyd] raises SchmeaError when enum is not a Array nor Set.
        #; [!xqed8] raises SchemaError when enum specified for no param option.
        #; [!zuthh] raises SchemaError when enum element value is not instance of type class.
        if enum
          enum.is_a?(Array) || enum.is_a?(Set)  or
            raise error("#{enum.inspect}: array or set expected.")
          param  or
            raise error("#{enum.inspect}: enum specified in spite of option has no params.")
          enum.each do |x|
            x.is_a?(type)  or
              raise error("#{enum.inspect}: enum element value should be instance of #{type.class.name}, but #{x.inspect} is not.")
          end if type
        end
        #; [!yht0v] keeps command option definitions.
        item = SchemaItem.new(key, optdef, desc, short, long, param, required,
                   type: type, rexp: rexp, enum: enum, value: value, &callback)
        @items << item
        item
      end

      def option_help(width_or_format=nil, all: false)
        #; [!0aq0i] can take integer as width.
        #; [!pcsah] can take format string.
        #; [!dndpd] detects option width automatically when nothing specified.
        case width_or_format
        when nil    ; format = _default_format()
        when Integer; format = "  %-#{width_or_format}s : %s"
        when String ; format = width_or_format
        else
          raise ArgumentError.new("#{width_or_format.inspect}: width (integer) or format (string) expected.")
        end
        #; [!v7z4x] skips option help if help message is not specified.
        #; [!to1th] includes all option help when `all` is true.
        sb = []
        width = nil
        each_option_and_desc(all: all) do |opt, desc|
          #sb << format % [opt, desc] << "\n" if desc || all
          if desc
            #; [!848rm] supports multi-lines help message.
            n = 0
            desc.each_line do |line|
              if (n += 1) == 1
                sb << format % [opt, line.chomp] << "\n"
              else
                width ||= (format % ['', '']).length
                sb << (' ' * width) << line.chomp << "\n"
              end
            end
          elsif all
            sb << format % [opt, ''] << "\n"
          end
        end
        return sb.join()
      end

      #; [!rrapd] '#to_s' is an alias to '#option_help()'.
      alias to_s option_help

      def each_option_and_desc(all: false, &block)
        #; [!4b911] yields each optin definition str and help message.
        @items.each do |item|
          #; [!cl8zy] when 'all' flag is false, not yield item which help is nil.
          #; [!tc4bk] when 'all' flag is true, yields item which help is nil.
          yield item.optdef, item.desc if all || item.desc
        end
        #; [!zbxyv] returns self.
        self
      end
      alias each_option_help each_option_and_desc   # for backward compatibility

      def each(&block)   # :nodoc:
        #; [!y4k1c] yields each option item.
        @items.each(&block)
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

      def error(msg)
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
          raise error("#{optdef}: invalid option definition (use '#{$1}=#{$2}' instead of '#{$1} #{$2}').")
        else
          raise error("#{optdef}: invalid option definition.")
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

    end


    class SchemaItem    # avoid Struct

      def initialize(key, optdef, desc, short, long, param, required, type: nil, rexp: nil, pattern: nil, enum: nil, value: nil, &callback)
        rexp ||= pattern    # for backward compatibility
        @key      = key       unless key.nil?
        @optdef   = optdef    unless optdef.nil?
        @desc     = desc      unless desc.nil?
        @short    = short     unless short.nil?
        @long     = long      unless long.nil?
        @param    = param     unless param.nil?
        @required = required  unless required.nil?
        @type     = type      unless type.nil?
        @rexp     = rexp      unless rexp.nil?
        @enum     = enum      unless enum.nil?
        @value    = value     unless value.nil?
        @callback = callback  unless callback.nil?
        #; [!nn4cp] freezes enum object.
        @enum.freeze() if @enum
      end

      attr_reader :key, :optdef, :desc, :short, :long, :param, :type, :rexp, :enum, :value, :callback
      alias pattern rexp   # for backward compatibility
      alias help desc      # for backward compatibility

      def required?
        #; [!svxny] returns nil if option takes no arguments.
        #; [!uwbgc] returns false if argument is optional.
        #; [!togcx] returns true if argument is required.
        return ! @param ? nil : !! @required
      end

      def optional?
        #; [!ebkg7] returns nil if option takes no arguments.
        #; [!eh6bs] returns false if argument is required.
        #; [!xecx2] returns true if argument is optional.
        return ! @param ? nil : ! @required
      end

      def arg_requireness()
        #; [!kmo28] returns :none if option takes no arguments.
        #; [!owpba] returns :optional if argument is optional.
        #; [!s8gxl] returns :required if argument is required.
        return :none     if ! @param
        return :required if @required
        return :optional
      end

      def validate_and_convert(val, optdict)
        #; [!h0s0o] raises RuntimeError when value not matched to pattern.
        if @rexp && val != true
          val =~ @rexp  or
            raise "pattern unmatched."
        end
        #; [!j4fuz] calls type-specific callback when type specified.
        if @type && val != true
          proc_ = PARAM_TYPES[@type]
          val = proc_.call(val)
        end
        #; [!5jrdf] raises RuntimeError when value not in enum.
        if @enum && val != true
          @enum.include?(val)  or
            raise "expected one of #{@enum.join('/')}."
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

    end


    PARAM_TYPES = {
      String => proc {|val|
        val
      },
      Integer => proc {|val|
        #; [!6t8cs] converts value into integer.
        #; [!nzwc9] raises error when failed to convert value into integer.
        val =~ /\A[-+]?\d+\z/  or
          raise "integer expected."
        val.to_i
      },
      Float => proc {|val|
        #; [!gggy6] converts value into float.
        #; [!t4elj] raises error when faield to convert value into float.
        val =~ /\A[-+]?(\d+\.\d*|\.\d+)\z/  or
          raise "float expected."
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
          raise "boolean expected."
        end
      },
      Date => proc {|val|
        #; [!sru5j] converts 'YYYY-MM-DD' into date object.
        #; [!h9q9y] raises error when failed to convert into date object.
        #; [!i4ui8] raises error when specified date not exist.
        val =~ /\A(\d\d\d\d)-(\d\d?)-(\d\d?)\z/  or
          raise "invalid date format (ex: '2000-01-01')"
        begin
          Date.new($1.to_i, $2.to_i, $3.to_i)
        rescue ArgumentError => ex
          raise "date not exist."
        end
      },
    }


    class Parser

      def initialize(schema)
        @schema = schema
      end

      def parse(argv, parse_all=true, &error_handler)
        optdict = new_options_dict()
        index = 0
        while index < argv.length
          #; [!5s5b6] treats '-' as an argument, not an option.
          if argv[index] =~ /\A-/ && argv[index] != "-"
            optstr = argv.delete_at(index)
          #; [!q8356] parses options even after arguments when `parse_all=true`.
          elsif parse_all
            index += 1
            next
          #; [!ryra3] doesn't parse options after arguments when `parse_all=false`.
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

      def error(msg)
        return OptionError.new(msg)
      end

      protected

      def parse_long_option(optstr, optdict)
        #; [!3i994] raises OptionError when invalid long option format.
        optstr =~ /\A--(\w[-\w]*)(?:=(.*))?\z/  or
          raise error("#{optstr}: invalid long option.")
        name = $1; val = $2
        #; [!er7h4] raises OptionError when unknown long option.
        item = @schema.find_long_option(name)  or
          raise error("#{optstr}: unknown long option.")
        #; [!2jd9w] raises OptionError when no arguments specified for arg required long option.
        #; [!qyq8n] raises optionError when an argument specified for no arg long option.
        if ! item.param            # no arguments
          val.nil?  or raise error("#{optstr}: unexpected argument.")
        elsif item.required?       # argument required
          val  or raise error("#{optstr}: argument required.")
        else                       # optional argument
          # do nothing
        end
        #; [!o596x] validates argument value.
        val ||= true
        begin
          val = item.validate_and_convert(val, optdict)
        rescue RuntimeError => ex
          raise error("#{optstr}: #{ex.message}")
        end
        optdict[item.key] = val
      end

      def parse_short_options(optstr, optdict, &block)
        n = optstr.length
        i = 0
        while (i += 1) < n
          char = optstr[i]
          #; [!4eh49] raises OptionError when unknown short option specified.
          item = @schema.find_short_option(char)  or
            raise error("-#{char}: unknown option.")
          #
          if ! item.param          # no arguments
            val = true
          elsif item.required?     # argument required
            #; [!utdbf] raises OptionError when argument required but not specified.
            #; [!f63hf] short option arg can be specified without space separator.
            val = i+1 < n ? optstr[(i+1)..-1] : yield  or
              raise error("-#{char}: argument required.")
            i = n
          else                     # optional argument
            #; [!yjq6b] optional arg should be specified without space separator.
            #; [!wape4] otpional arg can be omit.
            val = i+1 < n ? optstr[(i+1)..-1] : true
            i = n
          end
          #; [!yu0kc] validates short option argument.
          begin
            val = item.validate_and_convert(val, optdict)
          rescue RuntimeError => ex
            if val == true
              raise error("-#{char}: #{ex.message}")
            else
              s = item.optional? ? '' : ' '
              raise error("-#{char}#{s}#{val}: #{ex.message}")
            end
          end
          optdict[item.key] = val
        end
      end

      def new_options_dict()
        #; [!vm6h0] returns new hash object.
        return OPTIONS_CLASS.new
      end

    end


    OPTIONS_CLASS = Hash
    SCHEMA_CLASS = Schema
    PARSER_CLASS = Parser


    class SchemaError < StandardError
    end


    class OptionError < StandardError
    end


  end


  Cmdopt = CmdOpt         # for backawrd compatibility


end
