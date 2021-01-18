# -*- coding: utf-8 -*-

###
### $Release$
### $Copyright$
### $License$
###

require 'date'
require 'set'


module Benry


  ##
  ## Command option parser.
  ##
  ## Usage:
  ##     ## define
  ##     cmdopt = Benry::Cmdopt.new
  ##     cmdopt.add(:help   , '-h, --help'   , "print help message")
  ##     cmdopt.add(:version, '    --version', "print version")
  ##     ## parse
  ##     options = cmdopt.parse(ARGV) do |err|
  ##       $stderr.puts "ERROR: #{err.message}"
  ##       exit(1)
  ##     end
  ##     p options     # ex: {:help => true, :version => true}
  ##     p ARGV        # options are removed from ARGV
  ##     ## help
  ##     if options[:help]
  ##       puts "Usage: foobar [<options>] [<args>...]"
  ##       puts ""
  ##       puts "Options:"
  ##       puts cmdopt.option_help()
  ##       ## or
  ##       #format = "  %-20s : %s"
  ##       #cmdopt.each_option_help {|opt, help| puts format % [opt, help] }
  ##     end
  ##
  ## Command option parameter:
  ##     ## required
  ##     cmdopt.add(:file, '-f, --file=<FILE>', "filename")
  ##     cmdopt.add(:file, '    --file=<FILE>', "filename")
  ##     cmdopt.add(:file, '-f <FILE>'        , "filename")
  ##     ## optional
  ##     cmdopt.add(:file, '-f, --file[=<FILE>]', "filename")
  ##     cmdopt.add(:file, '    --file[=<FILE>]', "filename")
  ##     cmdopt.add(:file, '-f[<FILE>]'         , "filename")
  ##
  ## Validation:
  ##     ## type
  ##     cmdopt.add(:indent , '-i <N>', "indent width", type: Integer)
  ##     ## pattern
  ##     cmdopt.add(:indent , '-i <N>', "indent width", pattern: /\A\d+\z/)
  ##     ## enum
  ##     cmdopt.add(:indent , '-i <N>', "indent width", enum: [2, 4, 8])
  ##     ## callback
  ##     cmdopt.add(:indent , '-i <N>', "indent width") {|val|
  ##       val =~ /\A\d+\z/  or
  ##         raise "integer expected."  # raise without exception class.
  ##       val.to_i                     # convert argument value.
  ##     }
  ##
  ## Available types:
  ##     * Integer   (`/\A[-+]?\d+\z/`)
  ##     * Float     (`/\A[-+]?(\d+\.\d*\|\.\d+)z/`)
  ##     * TrueClass (`/\A(true|on|yes|false|off|no)\z/`)
  ##     * Date      (`/\A\d\d\d\d-\d\d?-\d\d?\z/`)
  ##
  ## Multiple parameters:
  ##     cmdopt.add(:lib , '-I <NAME>', "library name") {|optdict, key, val|
  ##       arr = optdict[key] || []
  ##       arr << val
  ##       arr
  ##     }
  ##
  ## Hidden option:
  ##     ### if help string is nil, that option is removed from help message.
  ##     require 'benry/cmdopt'
  ##     cmdopt = Benry::Cmdopt.new
  ##     cmdopt.add(:verbose, '-v, --verbose', "verbose mode")
  ##     cmdopt.add(:debug  , '-d[<LEVEL>]'  , nil, type: Integer) # hidden
  ##     puts cmdopt.option_help()
  ##     ### output ('-d' doesn't appear because help string is nil)
  ##     #  -v, --verbose        : verbose mode
  ##
  ## Not supported:
  ##     * default value
  ##     * `--no-xxx` style option
  ##     * bash/zsh completion
  ##
  module Cmdopt


    VERSION = '$Release: 0.0.0 $'.split()[1]


    def self.new
      #; [!7kkqv] creates Facade object.
      return Facade.new
    end


    class Facade

      def initialize
        @schema = SCHEMA_CLASS.new
      end

      def add(key, optdef, help, type: nil, pattern: nil, enum: nil, &callback)
        #; [!vmb3r] defines command option.
        @schema.add(key, optdef, help, type: type, pattern: pattern, enum: enum, &callback)
        #; [!tu4k3] returns self.
        self
      end

      def option_help(width_or_format=nil, all: false)
        #; [!dm4p8] returns option help message.
        return @schema.option_help(width_or_format, all: all)
      end

      def each_option_help(&block)
        #; [!bw9qx] yields each option definition string and help message.
        @schema.each_option_help(&block)
        self
      end

      def parse(argv, &error_handler)
        #; [!7gc2m] parses command options.
        #; [!no4xu] returns option values as dict.
        #; [!areof] handles only OptionError when block given.
        #; [!peuva] returns nil when OptionError handled.
        parser = PARSER_CLASS.new(@schema)
        return parser.parse(argv, &error_handler)
      end

    end


    class Schema

      def initialize()
        @items = []
      end

      def add(key, optdef, help, type: nil, pattern: nil, enum: nil, &callback)
        #; [!rhhji] raises SchemaError when key is not a Symbol.
        key.nil? || key.is_a?(Symbol)  or
          raise error("add(#{key.inspect}): 1st arg should be a Symbol as an option key.")
        #; [!vq6eq] raises SchemaError when help message is missing."
        help.nil? || help.is_a?(String)  or
          raise error("add(#{key.inspect}, #{optdef.inspect}): help message required as 3rd argument.")
        #; [!7hi2d] takes command option definition string.
        short, long, param, optional = parse_optdef(optdef)
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
        if pattern
          pattern.is_a?(Regexp)  or
            raise error("#{pattern.inspect}: regexp expected.")
          param  or
            raise error("#{pattern.inspect}: pattern specified in spite of option has no params.")
        end
        #; [!melyd] raises SchmeaError when enum is not a Array nor Set.
        #; [!xqed8] raises SchemaError when enum specified for no param option.
        if enum
          enum.is_a?(Array) || enum.is_a?(Set)  or
            raise error("#{enum.inspect}: array or set expected.")
          param  or
            raise error("#{enum.inspect}: enum specified in spite of option has no params.")
        end
        #; [!yht0v] keeps command option definitions.
        item = SchemaItem.new(key, optdef, short, long, param, help,
                   optional: optional, type: type, pattern: pattern, enum: enum, &callback)
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
        buf = []
        width = nil
        each_option_help do |opt, help|
          #buf << format % [opt, help] << "\n" if help || all
          if help
            #; [!848rm] supports multi-lines help message.
            n = 0
            help.each_line do |line|
              if (n += 1) == 1
                buf << format % [opt, line.chomp] << "\n"
              else
                width ||= (format % ['', '']).length
                buf << (' ' * width) << line.chomp << "\n"
              end
            end
          elsif all
            buf << format % [opt, ''] << "\n"
          end
        end
        return buf.join()
      end

      def each_option_help(&block)
        #; [!4b911] yields each optin definition str and help message.
        @items.each do |item|
          yield item.optdef, item.help
        end
        #; [!zbxyv] returns self.
        self
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
        return short, long, param1 || param2, !!param2
      end

      def _default_format(min_width=nil, max_width=35)
        #; [!bmr7d] changes min_with according to options.
        min_width ||= _preferred_option_width()
        #; [!hr45y] detects preffered option width.
        w = 0
        each_option_help do |opt, help|
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
        long_p  = @items.any? {|x| x.help &&  x.long &&  x.param }
        short_p = @items.all? {|x| x.help && !x.long && !x.param }
        return short_p ? 8 : long_p ? 20 : 14
      end

    end


    class SchemaItem    # avoid Struct

      def initialize(key, optdef, short, long, param, help, optional: nil, type: nil, pattern: nil, enum: nil, &callback)
        @key      = key       unless key.nil?
        @optdef   = optdef    unless optdef.nil?
        @short    = short     unless short.nil?
        @long     = long      unless long.nil?
        @param    = param     unless param.nil?
        @help     = help      unless help.nil?
        @optional = optional  unless optional.nil?
        @type     = type      unless type.nil?
        @pattern  = pattern   unless pattern.nil?
        @enum     = enum      unless enum.nil?
        @callback = callback  unless callback.nil?
      end

      attr_reader :key, :optdef, :short, :long, :param, :help, :optional, :type, :pattern, :enum, :callback
      alias optional_param? optional

      def validate_and_convert(val, optdict)
        #; [!h0s0o] raises RuntimeError when value not matched to pattern.
        if @pattern && val != true
          val =~ @pattern  or
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
        when /\A(?:true|on|yes)\z/i
          true
        when /\A(?:false|off|no)\z/i
          false
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

      def parse(argv, &error_handler)
        optdict = new_options_dict()
        while !argv.empty? && argv[0] =~ /\A-/
          optstr = argv.shift
          #; [!y04um] skips rest options when '--' found in argv.
          if optstr == '--'
            break
          elsif optstr =~ /\A--/
            #; [!uh7j8] parses long options.
            parse_long_option(optstr, optdict, argv)
          else
            #; [!nwnjc] parses short options.
            parse_short_options(optstr, optdict, argv)
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

      def parse_long_option(optstr, optdict, _argv)
        #; [!3i994] raises OptionError when invalid long option format.
        optstr =~ /\A--(\w[-\w]*)(?:=(.*))?\z/  or
          raise error("#{optstr}: invalid long option.")
        name = $1; val = $2
        #; [!er7h4] raises OptionError when unknown long option.
        item = @schema.find_long_option(name)  or
          raise error("#{optstr}: unknown long option.")
        #; [!2jd9w] raises OptionError when no arguments specified for arg required long option.
        #; [!qyq8n] raises optionError when an argument specified for no arg long option.
        if item.optional_param?
          # do nothing
        elsif item.param
          val  or raise error("#{optstr}: argument required.")
        else
          val.nil?  or raise error("#{optstr}: unexpected argument.")
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

      def parse_short_options(optstr, optdict, argv)
        n = optstr.length
        i = 0
        while (i += 1) < n
          char = optstr[i]
          #; [!4eh49] raises OptionError when unknown short option specified.
          item = @schema.find_short_option(char)  or
            raise error("-#{char}: unknown option.")
          #
          if !item.param
            val = true
          elsif !item.optional_param?
            #; [!utdbf] raises OptionError when argument required but not specified.
            #; [!f63hf] short option arg can be specified without space separator.
            val = i+1 < n ? optstr[(i+1)..-1] : argv.shift  or
              raise error("-#{char}: argument required.")
            i = n
          else
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
              s = item.optional_param? ? '' : ' '
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


end
