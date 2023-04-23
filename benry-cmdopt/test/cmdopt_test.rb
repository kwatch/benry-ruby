# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/ok'

require 'benry/cmdopt'


def new_sample_schema()
  sc = Benry::CmdOpt::Schema.new
  sc.add(:help   , "-h, --help"            , "show help message.")
  sc.add(:version, "--version"             , "print version")
  sc.add(:file   , "-f, --file=<FILE>"     , "filename")
  sc.add(:indent , "-i, --indent[=<WIDTH>]", "enable indent", type: Integer)
  sc.add(:mode   , "-m, --mode=<MODE>"     , "mode", enum: ['verbose', 'quiet'])
  sc.add(:libpath, "-I, --path=<PATH>"     , "library path (multiple ok)") do |optdef, key, val|
    File.directory?(val)  or raise "directory not exist."
    arr = optdef[key] || []
    arr << val
    arr
  end
  sc
end



class Benry::CmdOpt::Schema::Test < MiniTest::Test


  describe "#parse()" do

    before do
      @schema = Benry::CmdOpt::Schema.new
    end

    it "[!qw0ac] parses command option definition string." do
      sc = @schema
      tuple = sc.__send__(:parse_optdef, "-h, --help")
      ok {tuple} == ['h', 'help', nil, nil]
      tuple = sc.__send__(:parse_optdef, "-h")
      ok {tuple} == ['h', nil, nil, nil]
      tuple = sc.__send__(:parse_optdef, "--help")
      ok {tuple} == [nil, 'help', nil, nil]
    end

    it "[!ae733] parses command option definition which has a required param." do
      sc = @schema
      tuple = sc.__send__(:parse_optdef, "-f, --file=<FILE>")
      ok {tuple} == ['f', 'file', '<FILE>', true]
      tuple = sc.__send__(:parse_optdef, "-f <FILE>")
      ok {tuple} == ['f', nil, '<FILE>', true]
      tuple = sc.__send__(:parse_optdef, "--file=<FILE>")
      ok {tuple} == [nil, 'file', '<FILE>', true]
    end

    it "[!4h05c] parses command option definition which has an optional param." do
      sc = @schema
      tuple = sc.__send__(:parse_optdef, "-i, --indent[=<WIDTH>]")
      ok {tuple} == ['i', 'indent', '<WIDTH>', false]
      tuple = sc.__send__(:parse_optdef, "-i[<WIDTH>]")
      ok {tuple} == ['i', nil, '<WIDTH>', false]
      tuple = sc.__send__(:parse_optdef, "--indent[=<WIDTH>]")
      ok {tuple} == [nil, 'indent', '<WIDTH>', false]
    end

    it "[!b7jo3] raises SchemaError when command option definition is invalid." do
      sc = @schema
      pr = proc {
        tuple = sc.__send__(:parse_optdef, "-i, --indent <WIDTH>")
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     "-i, --indent <WIDTH>: invalid option definition (use '=--indent' instead of ' --indent').")
    end

  end


  describe "#dup()" do

    before do
      @schema = Benry::CmdOpt::Schema.new
      @schema.add(:help   , "-h" , "print help")
    end

    it "[!lxb0o] copies self object." do
      this  = @schema
      other = @schema.dup()
      #
      this_items  = this.instance_variable_get(:@items)
      other_items = other.instance_variable_get(:@items)
      ok {this_items} != nil
      ok {other_items} != nil
      ok {other_items} == this_items
      ok {other_items.object_id} != this_items.object_id
      #
      this.add(:silent, "-s", "silent")
      other.add(:quiet, "-q", "quiet")
      ok {this.option_help()}  == ("  -h       : print help\n" +
                                   "  -s       : silent\n")
      ok {other.option_help()} == ("  -h       : print help\n" +
                                   "  -q       : quiet\n")
    end

  end


  describe "#add()" do

    before do
      @schema = Benry::CmdOpt::Schema.new
    end

    it "[!7hi2d] takes command option definition string." do
      sc = @schema
      sc.add(:indent, "-i, --indent=<WIDTH>", "print help")
      items = sc.instance_eval { @items }
      ok {items.length} == 1
      ok {items[0]}.is_a?(Benry::CmdOpt::SchemaItem)
      ok {items[0].key} == :indent
      ok {items[0].short} == 'i'
      ok {items[0].long} == 'indent'
      ok {items[0].param} == '<WIDTH>'
      ok {items[0].required?} == true
      ok {items[0].type} == nil
      ok {items[0].rexp} == nil
      ok {items[0].enum} == nil
      ok {items[0].callback} == nil
    end

    it "[!p9924] option key is omittable only when long option specified." do
      sc = @schema
      sc.add(nil, "-m, --max-num=<N>", nil)
      items = sc.instance_eval { @items }
      ok {items[0].key} == :max_num
    end

    it "[!jtp7z] raises SchemaError when key is nil and no long option." do
      sc = @schema
      pr = proc { sc.add(nil, "-i <N>", nil) }
      msg = "add(nil, \"-i <N>\"): long option required when option key (1st arg) not specified."
      ok {pr}.raise?(Benry::CmdOpt::SchemaError, msg)
    end

    it "[!97sn0] raises SchemaError when ',' is missing between short and long options." do
      sc = @schema
      pr = proc { sc.add(:exec, '-x --exec=ARG', "exec") }
      msg = "add(:exec, \"-x --exec=ARG\"): missing ',' between short option and long options."
      ok {pr}.raise?(Benry::CmdOpt::SchemaError, msg)
    end

    it "[!yht0v] keeps command option definitions." do
      sc = @schema
      sc.add(:indent, "-i, --indent[=<WIDTH>]", "indent width",
                      type: Integer, rexp: /\A\d+\z/, enum: [2, 4, 8]) {|v| v.to_i }
      items = sc.instance_eval { @items }
      ok {items.length} == 1
      ok {items[0]}.is_a?(Benry::CmdOpt::SchemaItem)
      ok {items[0].key} == :indent
      ok {items[0].short} == 'i'
      ok {items[0].long} == 'indent'
      ok {items[0].param} == '<WIDTH>'
      ok {items[0].required?} == false
      ok {items[0].type} == Integer
      ok {items[0].rexp} == /\A\d+\z/
      ok {items[0].enum} == [2, 4, 8]
      ok {items[0].callback}.is_a?(Proc)
      ok {items[0].callback.arity} == 1
    end

    it "[!kuhf9] type, rexp, and enum are can be passed as positional args as well as keyword args." do
      sc = @schema
      sc.add(:key, "--optdef=xx", "desc", Integer, /\A\d+\z/, [2,4,8])
      item = sc.each.first
      ok {item.type} == Integer
      ok {item.rexp} == /\A\d+\z/
      ok {item.enum} == [2,4,8]
    end

    it "[!e3emy] raises error when positional arg is not one of class, regexp, nor array." do
      sc = @schema
      pr = proc { sc.add(:key, "--optdef=xx", "desc", "value") }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     '"value": expected one of class, regexp, or array, but got String.')
    end

    it "[!rhhji] raises SchemaError when key is not a Symbol." do
      sc = @schema
      pr = proc {
        sc.add("-i, --indent[=<WIDTH>]", "indent width", nil)
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     'add("-i, --indent[=<WIDTH>]"): 1st arg should be a Symbol as an option key.')
    end

    it "[!vq6eq] raises SchemaError when help message is missing." do
      sc = @schema
      pr = proc {
        begin
          sc.add(:indent, "-i, --indent[=<WIDTH>]", type: Array)   # Ruby 2
        rescue ArgumentError
          sc.add(:indent, "-i, --indent[=<WIDTH>]", {type: Array}) # Ruby 3
        end
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     'add(:indent, "-i, --indent[=<WIDTH>]"): help message required as 3rd argument.')
    end

    it "[!7xmr5] raises SchemaError when type is not registered." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-i, --indent[=<WIDTH>]", "indent width", type: Array)
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     "Array: unregistered type.")
    end

    it "[!s2aaj] raises SchemaError when option has no params but type specified." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-i, --indent", "indent width", type: Integer)
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     "Integer: type specified in spite of option has no params.")
    end

    it "[!bi2fh] raises SchemaError when pattern is not a regexp." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-x, --indent[=<WIDTH>]", "indent width", rexp: '\A\d+\z')
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     '"\\\\A\\\\d+\\\\z": regexp pattern expected.')
    end

    it "[!01fmt] raises SchmeaError when option has no params but pattern specified." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-i, --indent", "indent width", rexp: /\A\d+\z/)
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     '/\A\d+\z/: regexp pattern specified in spite of option has no params.')
    end

    it "[!melyd] raises SchmeaError when enum is not a Array nor Set." do
      sc = @schema
      sc.add(:indent, "-i <N>", "indent width", enum: ["2", "4", "8"])
      sc.add(:indent, "-i <N>", "indent width", enum: Set.new(["2", "4", "8"]))
      pr = proc {
        sc.add(:indent, "-i <N>", "indent width", enum: "2,4,8")
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     '"2,4,8": array or set expected.')
    end

    it "[!xqed8] raises SchemaError when enum specified for no param option." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-i", "enable indent", enum: [2, 4, 8])
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     "[2, 4, 8]: enum specified in spite of option has no params.")
    end

    it "[!zuthh] raises SchemaError when enum element value is not instance of type class." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-i <N>", "enable indent", type: Integer, enum: ['2', '4', '8'])
      }
      ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                     '["2", "4", "8"]: enum element value should be instance of Class, but "2" is not.')
    end

  end


  describe '#option_help()' do

    before do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:help   , "-h, --help"            , "show help message.")
      sc.add(:version, "    --version"         , "print version")
      sc.add(:file   , "-f, --file=<FILE>"     , "filename")
      sc.add(:indent , "-i, --indent[=<WIDTH>]", "enable indent", type: Integer)
      sc.add(:debug  , "-d, --debug"           , nil)
      @schema = sc
    end

    it "[!0aq0i] can take integer as width." do
      helpmsg = @schema.option_help(41)
      ok {helpmsg} == <<END
  -h, --help                                : show help message.
      --version                             : print version
  -f, --file=<FILE>                         : filename
  -i, --indent[=<WIDTH>]                    : enable indent
END
      s = helpmsg.each_line.first.split(':')[0]
      ok {s.length} == 41+3
    end

    it "[!pcsah] can take format string." do
      helpmsg = @schema.option_help("%-42s: %s")
      ok {helpmsg} == <<END
-h, --help                                : show help message.
    --version                             : print version
-f, --file=<FILE>                         : filename
-i, --indent[=<WIDTH>]                    : enable indent
END
      s = helpmsg.each_line.first.split(':')[0]
      ok {s.length} == 42+0
    end

    it "[!dndpd] detects option width automatically when nothing specified." do
      helpmsg = @schema.option_help()
      ok {helpmsg} == <<END
  -h, --help             : show help message.
      --version          : print version
  -f, --file=<FILE>      : filename
  -i, --indent[=<WIDTH>] : enable indent
END
      s = helpmsg.each_line.to_a.last.split(':')[0]
      ok {s.length} == 25
    end

    it "[!v7z4x] skips option help if help message is not specified." do
      helpmsg = @schema.option_help()
      ok {helpmsg} !~ /debug/
    end

    it "[!to1th] includes all option help when `all` is true." do
      helpmsg = @schema.option_help(nil, all: true)
      ok {helpmsg} =~ /debug/
      ok {helpmsg} == <<END
  -h, --help             : show help message.
      --version          : print version
  -f, --file=<FILE>      : filename
  -i, --indent[=<WIDTH>] : enable indent
  -d, --debug            : 
END
    end

    it "[!848rm] supports multi-lines help message." do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:mode, "-m, --mode=<MODE>", <<END)
output mode
  v, verbose: print many output
  q, quiet:   print litte output
  c, compact: print summary output
END
      actual = sc.option_help()
      expected = <<END
  -m, --mode=<MODE>    : output mode
                           v, verbose: print many output
                           q, quiet:   print litte output
                           c, compact: print summary output
END
      ok {actual} == expected
    end

  end


  describe '#_default_format()' do

    before do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:help   , "-h, --help"            , "show help message.")
      sc.add(:version, "    --version"         , "print version")
      sc.add(:file   , "-f, --file=<FILE>"     , "filename")
      sc.add(:indent , "-i, --indent[=<WIDTH>]", "enable indent", type: Integer)
      sc.add(:debug  , "-d, --debug"           , nil)
      @schema = sc
    end

    it "[!kkh9t] returns format string." do
      ret = @schema.__send__(:_default_format)
      ok {ret} == "  %-22s : %s"
    end

    it "[!hr45y] detects preffered option width." do
      ret = @schema.__send__(:_default_format, 10, 20)
      ok {ret} == "  %-20s : %s"
      ret = @schema.__send__(:_default_format, 30, 40)
      ok {ret} == "  %-30s : %s"
      ret = @schema.__send__(:_default_format, 10, 40)
      ok {ret} == "  %-22s : %s"
    end

    it "[!bmr7d] changes min_with according to options." do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:help   , '-h', "help")
      sc.add(:version, '-v', "version")
      ok {sc.__send__(:_default_format, nil, 40)} == "  %-8s : %s"
      #
      sc.add(:file   , '-f <FILE>', "filename")
      ok {sc.__send__(:_default_format, nil, 40)} == "  %-14s : %s"
      #
      sc.add(:force  , '--force', "forcedly")
      ok {sc.__send__(:_default_format, nil, 40)} == "  %-14s : %s"
      #
      sc.add(:mode   , '-m, --mode=<MODE>', "verbose/quiet")
      ok {sc.__send__(:_default_format, nil, 40)} == "  %-20s : %s"
    end

  end


  describe '#_preferred_option_width()' do

    it "[!kl91t] shorten option help min width when only single options which take no arg." do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:help   , '-h', "help")
      sc.add(:version, '-v', "version")
      ok {sc.__send__(:_preferred_option_width)} == 8
    end

    it "[!0koqb] widen option help min width when any option takes an arg." do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:help   , '-h', "help")
      sc.add(:indent , '-i[<N>]', "indent")
      ok {sc.__send__(:_preferred_option_width)} == 14
    end

    it "[!kl91t] widen option help min width when long option exists." do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:help   , '-h', "help")
      sc.add(:version, '-v, --version', "version")
      ok {sc.__send__(:_preferred_option_width)} == 14
      #
      sc.add(:file, '--file=<FILE>', "filename")
      ok {sc.__send__(:_preferred_option_width)} == 20
    end

  end


  describe '#to_s()' do

    it "[!rrapd] '#to_s' is an alias to '#option_help()'." do
      schema = Benry::CmdOpt::Schema.new
      schema.add(:help   , "-h, --help"        , "show help message")
      schema.add(:version, "    --version"     , "print version")
      ok {schema.to_s} == schema.option_help()
    end

  end


  describe '#each_option_help()' do

    before do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:help, "-h, --help", "show help message")
      sc.add(:version, "    --version", "print version")
      sc.add(:debug  , "-D, --debug"  , nil)
      @schema = sc
    end

    it "[!4b911] yields each optin definition str and help message." do
      sc = @schema
      arr = []
      sc.each_option_help do |opt, desc|
        arr << [opt, desc]
      end
      ok {arr} == [
        ["-h, --help", "show help message"],
        ["    --version", "print version"],
      ]
    end

    it "[!cl8zy] when 'all' flag is false, not yield item which help is nil." do
      descs = []
      @schema.each_option_help(all: false) {|opt, desc| descs << desc }
      ok {descs}.all? {|x| x != nil }
    end

    it "[!tc4bk] when 'all' flag is true, yields item which help is nil." do
      descs = []
      @schema.each_option_help(all: true) {|opt, desc| descs << desc }
      ok {descs}.any? {|x| x == nil }
    end

    it "[!zbxyv] returns self." do
      sc = @schema
      ret = sc.each_option_help { nil }
      ok {ret}.same? sc
    end

  end


  describe '#each()' do

    before do
      @schema = Benry::CmdOpt::Schema.new
      @schema.add(:help   , "-h, --help"   , "help message")
      @schema.add(:version, "    --version", "print version")
    end

    it "[!y4k1c] yields each option item." do
      items = []
      @schema.each {|x| items << x }
      ok {items.length} == 2
      ok {items[0]}.is_a?(Benry::CmdOpt::SchemaItem)
      ok {items[1]}.is_a?(Benry::CmdOpt::SchemaItem)
      ok {items[0].key} == :help
      ok {items[1].key} == :version
      keys = @schema.each.collect {|x| x.key }
      ok {keys} == [:help, :version]
    end

  end


  describe '#find_short_option()' do

    before do
      @schema = new_sample_schema()
    end

    it "[!b4js1] returns option definition matched to short name." do
      x = @schema.find_short_option('h')
      ok {x.key} == :help
      x = @schema.find_short_option('f')
      ok {x.key} == :file
      x = @schema.find_short_option('i')
      ok {x.key} == :indent
    end

    it "[!s4d1y] returns nil when nothing found." do
      ok {@schema.find_short_option('v')} == nil
    end

  end


  describe '#find_long_option()' do

    before do
      @schema = new_sample_schema()
    end

    it "[!atmf9] returns option definition matched to long name." do
      x = @schema.find_long_option('help')
      ok {x.key} == :help
      x = @schema.find_long_option('file')
      ok {x.key} == :file
      x = @schema.find_long_option('indent')
      ok {x.key} == :indent
    end

    it "[!6haoo] returns nil when nothing found." do
      ok {@schema.find_long_option('lib')} == nil
    end

  end


end



class Benry::CmdOpt::SchemaItem::Test < MiniTest::Test

  ITEMS = [
    Benry::CmdOpt::SchemaItem.new(:help, "-h, --help",
                                  "h", "help", nil, "help msg", required: nil),
    Benry::CmdOpt::SchemaItem.new(:file, "-f, --file=<file>",
                                  "f", "file", "<file>", "filename", required: true),
    Benry::CmdOpt::SchemaItem.new(:indent, "-i, --indent[=<N>]",
                                  "i", "indent", "<N>", "indent width", required: false),
  ]


  describe '#required?' do

    it "[!svxny] returns nil if option takes no arguments." do
      item, _, _ = ITEMS
      ok {item.required?} == nil
    end

    it "[!togcx] returns true if argument is required." do
      _, item, _ = ITEMS
      ok {item.required?} == true
    end

    it "[!uwbgc] returns false if argument is optional." do
      _, _, item = ITEMS
      ok {item.required?} == false
    end

  end


  describe '#optional?' do

    it "[!ebkg7] returns nil if option takes no arguments." do
      item, _, _ = ITEMS
      ok {item.optional?} == nil
    end

    it "[!eh6bs] returns false if argument is required." do
      _, item, _ = ITEMS
      ok {item.optional?} == false
    end

    it "[!xecx2] returns true if argument is optional." do
      _, _, item = ITEMS
      ok {item.optional?} == true
    end

  end


  describe '#requireness()' do

    it "[!kmo28] returns :none if option takes no arguments." do
      item, _, _ = ITEMS
      ok {item.requireness()} == :none
    end

    it "[!s8gxl] returns :required if argument is required." do
      _, item, _ = ITEMS
      ok {item.requireness()} == :required
    end

    it "[!owpba] returns :optional if argument is optional." do
      _, _, item = ITEMS
      ok {item.requireness()} == :optional
    end

  end


  describe '#validate_and_convert()' do

    def new_item(key, optstr, short, long, param, desc,
                 required: nil, type: nil, rexp: nil, enum: nil, value: nil, &callback)
      return Benry::CmdOpt::SchemaItem.new(key, optstr, short, long, param, desc,
                 required: required, type: type, rexp: rexp, enum: enum, value: value, &callback)
    end

    it "[!h0s0o] raises RuntimeError when value not matched to pattern." do
      x = new_item(:indent, "", "i", "indent", "<WIDTH>", "indent width", rexp: /\A\d+\z/)
      optdict = {}
      pr = proc { x.validate_and_convert("abc", optdict) }
      ok {pr}.raise?(RuntimeError, "pattern unmatched.")
    end

    it "[!5jrdf] raises RuntimeError when value not in enum." do
      x = new_item(:indent, "", "i", "indent", "<WIDTH>", "indent width", enum: ['2', '4', '8'])
      optdict = {}
      pr = proc { x.validate_and_convert("10", optdict) }
      ok {pr}.raise?(RuntimeError, "expected one of 2/4/8.")
    end

    it "[!j4fuz] calls type-specific callback when type specified." do
      x = new_item(:indent, "", "i", "indent", "<WIDTH>", "indent width", type: Integer)
      optdict = {}
      pr = proc { x.validate_and_convert("abc", optdict) }
      ok {pr}.raise?(RuntimeError, "integer expected.")
    end

    it "[!jn9z3] calls callback when callback specified." do
      called = false
      x = new_item(:indent, "", "i", "indent", "<WIDTH>", "indent width") {|va|
        called = true
      }
      optdict = {}
      x.validate_and_convert("abc", optdict)
      ok {called} == true
    end

    it "[!iqalh] calls callback with different number of args according to arity." do
      args1 = nil
      x = new_item(:indent, "", "i", "indent", "<WIDTH>", nil) {|val|
        args1 = val
      }
      optdict = {}
      x.validate_and_convert("123", optdict)
      ok {args1} == "123"
      #
      args2 = nil
      x = new_item(:indent, "", "i", "indent", "<WIDTH>", nil) {|optdict, key, val|
        args2 = [optdict, key, val]
      }
      optdict = {}
      x.validate_and_convert("123", optdict)
      ok {args2} == [optdict, :indent, "123"]
    end

    it "[!x066l] returns new value." do
      x = new_item(:indent, "", "i", "indent", "<WIDTH>", nil, type: Integer)
      ok {x.validate_and_convert("123", {})} == 123
      #
      x = new_item(:indent, "", "i", "indent", "<WIDTH>", nil, type: Integer) {|val|
        val * 2
      }
      ok {x.validate_and_convert("123", {})} == 246
    end

    it "[!eafem] returns default value (if specified) instead of true value." do
      x1 = new_item(:flag, "desc", "f", "flag", nil, nil, value: nil)
      ok {x1.validate_and_convert(true, {})} == true
      x2 = new_item(:flag, "desc", "f", "flag", nil, nil, value: "blabla")
      ok {x2.validate_and_convert(true, {})} == "blabla"
      x3 = new_item(:flag, "desc", "f", "flag", nil, nil, value: false)
      ok {x3.validate_and_convert(true, {})} == false
    end

  end

end



class Benry::CmdOpt::Parser::Test < MiniTest::Test


  describe '#parse_options()' do

    before do
      @parser = Benry::CmdOpt::Parser.new(new_sample_schema())
    end

    it "[!3wmsy] returns command option values as a dict." do
      argv = ["-h", "--version"]
      d = @parser.parse(argv)
      ok {d} == {help: true, version: true}
    end

    it "[!uh7j8] parses long options." do
      argv = ["--help", "--file=foo.png", "--indent=10"]
      d = @parser.parse(argv)
      ok {d} == {help: true, file: "foo.png", indent: 10}
    end

    it "[!nwnjc] parses short options." do
      argv = ["-h", "-f", "foo.png", "-i10"]
      d = @parser.parse(argv)
      ok {d} == {help: true, file: "foo.png", indent: 10}
    end

    it "[!5s5b6] treats '-' as an argument, not an option." do
      argv = ["-h", "-", "xxx", "yyy"]
      d = @parser.parse(argv)
      ok {d} == {help: true}
      ok {argv} == ["-", "xxx", "yyy"]
    end

    it "[!q8356] parses options even after arguments when `parse_all=true`." do
      pr1 = proc {|argv| @parser.parse(argv, false) }
      pr2 = proc {|argv| @parser.parse(argv) }
      [pr1, pr2].each do |pr|
        argv = ["-h", "arg1", "-f", "foo.png", "arg2", "-i10", "arg3"]
        d = @parser.parse(argv, true)
        ok {d} == {help: true, file: "foo.png", indent: 10}
        ok {argv} == ["arg1", "arg2", "arg3"]
      end
    end

    it "[!ryra3] doesn't parse options after arguments when `parse_all=false`." do
      pr1 = proc {|argv| @parser.parse(argv, false) }
      #pr2 = proc {|argv| @parser.parse(argv) }
      [pr1].each do |pr|
        argv = ["-h", "arg1", "-f", "foo.png", "arg2", "-i10", "arg3"]
        d = pr.call(argv)
        ok {d} == {help: true}
        ok {argv} == ["arg1", "-f", "foo.png", "arg2", "-i10", "arg3"]
      end
    end

    it "[!y04um] skips rest options when '--' found in argv." do
      argv = ["-h", "--", "-f", "foo.png", "-i10"]
      d = @parser.parse(argv)
      ok {d} == {help: true}
      ok {argv} == ["-f", "foo.png", "-i10"]
    end

    it "[!qpuxh] handles only OptionError when block given." do
      errmsg = nil
      errcls = nil
      @parser.parse(["-ix"]) {|err|
        errmsg = err.message
        errcls = err.class
      }
      ok {errmsg} == "-ix: integer expected."
      ok {errcls} == Benry::CmdOpt::OptionError
      #
      sc = Benry::CmdOpt::Schema.new
      sc.add(:file, "--file=<FILE>", "file") do |val|
        File.open(val) {|f| f.read }
      end
      parser = Benry::CmdOpt::Parser.new(sc)
      pr = proc { parser.parse(["--file=/foo/bar/baz.png"]) }
      ok {pr}.raise?(Errno::ENOENT, /No such file or directory/)
    end

    it "[!dhpw1] returns nil when OptionError handled." do
      ret = @parser.parse(["-dx"]) {|err| 1 }
      ok {ret} == nil
    end

  end


  describe '#parse_long_option()' do

    before do
      @parser = Benry::CmdOpt::Parser.new(new_sample_schema())
    end

    it "[!3i994] raises OptionError when invalid long option format." do
      argv = ["--f/o/o"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "--f/o/o: invalid long option.")
    end

    it "[!er7h4] raises OptionError when unknown long option." do
      argv = ["--foo"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "--foo: unknown long option.")
    end

    it "[!2jd9w] raises OptionError when no arguments specified for arg required long option." do
      argv = ["--file"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "--file: argument required.")
    end

    it "[!qyq8n] raises optionError when an argument specified for no arg long option." do
      argv = ["--version=1.0.0"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "--version=1.0.0: unexpected argument.")
    end

    it "[!o596x] validates argument value." do
      argv = ["--indent=abc"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "--indent=abc: integer expected.")
      #
      argv = ["--path=/foo/bar"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "--path=/foo/bar: directory not exist.")

    end

  end


  describe '#parse_short_option()' do

    before do
      @parser = Benry::CmdOpt::Parser.new(new_sample_schema())
    end

    it "[!4eh49] raises OptionError when unknown short option specified." do
      argv = ["-hxf", "foo.png"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "-x: unknown option.")
    end

    it "[!utdbf] raises OptionError when argument required but not specified." do
      argv = ["-hf"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "-f: argument required.")
    end

    it "[!f63hf] short option arg can be specified without space separator." do
      argv = ["-hfabc.png", "xx"]
      d = @parser.parse(argv)
      ok {d} == {help: true, file: "abc.png"}
      ok {argv} == ["xx"]
    end

    it "[!yjq6b] optional arg should be specified without space separator." do
      argv = ["-hi123", "xx"]
      d = @parser.parse(argv)
      ok {d} == {help: true, indent: 123}
      ok {argv} == ['xx']
    end

    it "[!wape4] otpional arg can be omit." do
      argv = ["-hi", "xx"]
      d = @parser.parse(argv)
      ok {d} == {help: true, indent: true}
      ok {argv} == ['xx']
    end

    it "[!yu0kc] validates short option argument." do
      argv = ["-iaaa"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "-iaaa: integer expected.")
      #
      argv = ["-I", "/foo/bar"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "-I /foo/bar: directory not exist.")
    end

  end


  describe '#new_options_dict()' do

    it "[!vm6h0] returns new hash object." do
      parser = Benry::CmdOpt::Parser.new(new_sample_schema())
      ret = parser.__send__(:new_options_dict)
      ok {ret}.is_a?(Hash)
      ok {ret} == {}
    end

  end


end



class Benry::CmdOpt::Test < MiniTest::Test


  describe 'PARAM_TYPES[Integer]' do

    before do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:indent, "-i, --indent[=<N>]", "indent width", type: Integer)
      @parser = Benry::CmdOpt::Parser.new(sc)
    end

    it "[!6t8cs] converts value into integer." do
      d = @parser.parse(['-i20'])
      ok {d[:indent]} == 20
      #
      d = @parser.parse(['--indent=12'])
      ok {d[:indent]} == 12
    end

    it "[!nzwc9] raises error when failed to convert value into integer." do
      pr = proc { @parser.parse(['-i2.1']) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "-i2.1: integer expected.")
      #
      pr = proc { @parser.parse(['--indent=2.2']) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "--indent=2.2: integer expected.")
    end

  end


  describe 'PARAM_TYPES[Float]' do

    before do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:ratio, "-r, --ratio=<RATIO>", "ratio", type: Float)
      @parser = Benry::CmdOpt::Parser.new(sc)
    end

    it "[!gggy6] converts value into float." do
      d = @parser.parse(['-r', '1.25'])
      ok {d[:ratio]} == 1.25
      #
      d = @parser.parse(['--ratio=1.25'])
      ok {d[:ratio]} == 1.25
    end

    it "[!t4elj] raises error when faield to convert value into float." do
      pr = proc { @parser.parse(['-r', 'abc']) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "-r abc: float expected.")
      #
      pr = proc { @parser.parse(['--ratio=abc']) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError, "--ratio=abc: float expected.")
    end

  end


  describe 'PARAM_TYPES[TrueClass]' do

    before do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:border  , "-b, --border[=<on|off>]", "enable border", type: TrueClass)
      @parser = Benry::CmdOpt::Parser.new(sc)
    end

    it "[!47kx4] converts 'true'/'on'/'yes' into true." do
      d = @parser.parse(["-btrue"])
      ok {d} == {border: true}
      d = @parser.parse(["-bon"])
      ok {d} == {border: true}
      d = @parser.parse(["-byes"])
      ok {d} == {border: true}
      #
      d = @parser.parse(["--border=true"])
      ok {d} == {border: true}
      d = @parser.parse(["--border=on"])
      ok {d} == {border: true}
      d = @parser.parse(["--border=yes"])
      ok {d} == {border: true}
    end

    it "[!3n810] converts 'false'/'off'/'no' into false." do
      d = @parser.parse(["-bfalse"])
      ok {d} == {border: false}
      d = @parser.parse(["-boff"])
      ok {d} == {border: false}
      d = @parser.parse(["-bno"])
      ok {d} == {border: false}
      #
      d = @parser.parse(["--border=false"])
      ok {d} == {border: false}
      d = @parser.parse(["--border=off"])
      ok {d} == {border: false}
      d = @parser.parse(["--border=no"])
      ok {d} == {border: false}
    end

    it "[!h8ayh] raises error when failed to convert value into true nor false." do
      pr = proc { @parser.parse(["-bt"]) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError,
                     "-bt: boolean expected.")
      #
      pr = proc { @parser.parse(["--border=t"]) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError,
                     "--border=t: boolean expected.")
    end

  end


  describe 'PARAM_TYPES[Date]' do

    before do
      require 'date'
      sc = Benry::CmdOpt::Schema.new
      sc.add(:date, "-d, --date=<YYYY-MM-DD>]", "date", type: Date)
      @parser = Benry::CmdOpt::Parser.new(sc)
    end

    it "[!sru5j] converts 'YYYY-MM-DD' into date object." do
      d = @parser.parse(['-d', '2000-01-01'])
      ok {d[:date]} == Date.new(2000, 1, 1)
      #
      d = @parser.parse(['--date=2000-1-2'])
      ok {d[:date]} == Date.new(2000, 1, 2)
    end

    it "[!h9q9y] raises error when failed to convert into date object." do
      pr = proc { @parser.parse(['-d', '2000/01/01']) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError,
                     "-d 2000/01/01: invalid date format (ex: '2000-01-01')")
      #
      pr = proc { @parser.parse(['--date=01-01-2000']) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError,
                     "--date=01-01-2000: invalid date format (ex: '2000-01-01')")
    end

    it "[!i4ui8] raises error when specified date not exist." do
      pr = proc { @parser.parse(['-d', '2001-02-29']) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError,
                     "-d 2001-02-29: date not exist.")
      #
      pr = proc { @parser.parse(['--date=2001-02-29']) }
      ok {pr}.raise?(Benry::CmdOpt::OptionError,
                     "--date=2001-02-29: date not exist.")
    end

  end


  describe '.new()' do

    it "[!7kkqv] creates Facade object." do
      obj = Benry::CmdOpt.new
      ok {obj}.is_a?(Benry::CmdOpt::Facade)
    end

  end


end



class Benry::CmdOpt::Facade::Test < MiniTest::Test


  describe "#dup()" do

    before do
      @cmdopt = Benry::CmdOpt.new
      @cmdopt.add(:help   , "-h" , "help message")
    end

    it "[!mf5cz] copies self object." do
      this  = @cmdopt
      other = @cmdopt.dup()
      #
      this_schema  = this.instance_variable_get(:@schema)
      other_schema = other.instance_variable_get(:@schema)
      ok {this_schema} != nil
      ok {other_schema} != nil
      ok {other_schema.object_id} != this_schema.object_id
      #
      this.add(:silent, "-s", "silent")
      other.add(:quiet, "-q", "quiet")
      ok {this.option_help()}  == ("  -h       : help message\n" +
                                   "  -s       : silent\n")
      ok {other.option_help()} == ("  -h       : help message\n" +
                                   "  -q       : quiet\n")
    end

  end


  describe '#add()' do

    it "[!vmb3r] defines command option." do
      cmdopt = Benry::CmdOpt.new()
      cmdopt.add(:help, "-h, --help", "show help message")
      items = cmdopt.instance_eval { @schema.instance_variable_get('@items') }
      ok {items}.is_a?(Array)
      ok {items.length} == 1
      ok {items[0].key} == :help
      ok {items[0].short} == 'h'
      ok {items[0].long} == 'help'
      ok {items[0].desc} == 'show help message'
    end

    it "[!71cvg] type, rexp, and enum are can be passed as positional args as well as keyword args." do
      cmdopt = Benry::CmdOpt.new()
      cmdopt.add(:key, "--optdef=xx", "desc", Integer, /\A\d+\z/, [2,4,8], value: "VALUE")
      items = cmdopt.instance_eval { @schema.instance_variable_get('@items') }
      item = items.first
      ok {item.type} == Integer
      ok {item.rexp} == /\A\d+\z/
      ok {item.enum} == [2,4,8]
      ok {item.value} == "VALUE"
    end

  end


  describe '#option_help()' do

    before do
      @cmdopt = Benry::CmdOpt.new
      @cmdopt.add(:help   , "-h, --help"        , "show help message")
      @cmdopt.add(:version, "    --version"     , "print version")
      @cmdopt.add(:file   , "-f, --file=<FILE>" , "filename")
    end

    it "[!dm4p8] returns option help message." do
      helpmsg = @cmdopt.option_help()
      ok {helpmsg} == <<END
  -h, --help           : show help message
      --version        : print version
  -f, --file=<FILE>    : filename
END
    end

  end


  describe '#to_s()' do

    it "[!s61vo] '#to_s' is an alias to '#option_help()'." do
      cmdopt = Benry::CmdOpt.new
      cmdopt.add(:help   , "-h, --help"        , "show help message")
      cmdopt.add(:version, "    --version"     , "print version")
      ok {cmdopt.to_s} == cmdopt.option_help()
    end

  end


  describe '#each_option_help()' do

    before do
      @cmdopt = Benry::CmdOpt.new
      @cmdopt.add(:help   , "-h, --help"        , "show help message")
      @cmdopt.add(:version, "    --version"     , "print version")
      @cmdopt.add(:file   , "-f, --file=<FILE>" , "filename")
    end

    it "[!bw9qx] yields each option definition string and help message." do
      cmdopt = @cmdopt
      pairs = []
      cmdopt.each_option_help do |opt, desc|
        pairs << [opt, desc]
      end
      ok {pairs} == [
        ["-h, --help", "show help message"],
        ["    --version", "print version"],
        ["-f, --file=<FILE>", "filename"],
      ]
    end

  end


  describe '#each()' do

    before do
      @cmdopt = Benry::CmdOpt.new
      @cmdopt.add(:help   , "-h, --help"   , "help message")
      @cmdopt.add(:version, "    --version", "print version")
    end

    it "[!knh44] yields each option item." do
      items = []
      @cmdopt.each {|x| items << x }
      ok {items.length} == 2
      ok {items[0]}.is_a?(Benry::CmdOpt::SchemaItem)
      ok {items[1]}.is_a?(Benry::CmdOpt::SchemaItem)
      ok {items[0].key} == :help
      ok {items[1].key} == :version
      keys = @cmdopt.each.collect {|x| x.key }
      ok {keys} == [:help, :version]
    end

  end


  describe '#parse()' do

    before do
      @cmdopt = Benry::CmdOpt.new()
      @cmdopt.add(:file, "-f, --file=<FILE>", "file") do |val|
        File.open(val) {|f| f.read }
      end
      @cmdopt.add(:debug, "-d, --debug[=<LEVEL>]", "debug", type: Integer)
    end

    it "[!areof] handles only OptionError when block given." do
      errmsg = nil
      errcls = nil
      @cmdopt.parse(["-dx"]) {|err|
        errmsg = err.message
        errcls = err.class
      }
      ok {errmsg} == "-dx: integer expected."
      ok {errcls} == Benry::CmdOpt::OptionError
      #
      pr = proc do
        @cmdopt.parse(["-f", "/foo/bar/baz.png"])
      end
      ok {pr}.raise?(Errno::ENOENT, /No such file or directory/)
    end

    it "[!peuva] returns nil when OptionError handled." do
      ret = @cmdopt.parse(["-dx"]) {|err| 1 }
      ok {ret} == nil
    end

    it "[!za9at] parses options only before args when `parse_all=false`." do
      argv = ["aaa", "-d3", "bbb"]
      #
      argv1 = argv.dup
      opts1 = @cmdopt.parse(argv1)
      ok {opts1} == {:debug=>3}
      ok {argv1} == ["aaa", "bbb"]
      #
      argv2 = argv.dup
      opts2 = @cmdopt.parse(argv2, false)
      ok {opts2} == {}
      ok {argv2} == ["aaa", "-d3", "bbb"]
    end

  end


end
