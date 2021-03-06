# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/ok'

require 'benry/cmdopt'


def new_sample_schema()
  sc = Benry::Cmdopt::Schema.new
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



class Benry::Cmdopt::Schema::Test < MiniTest::Test


  describe "#parse()" do

    before do
      @schema = Benry::Cmdopt::Schema.new
    end

    it "[!qw0ac] parses command option definition string." do
      sc = @schema
      tuple = sc.__send__(:parse_optdef, "-h, --help")
      ok {tuple} == ['h', 'help', nil, false]
      tuple = sc.__send__(:parse_optdef, "-h")
      ok {tuple} == ['h', nil, nil, false]
      tuple = sc.__send__(:parse_optdef, "--help")
      ok {tuple} == [nil, 'help', nil, false]
    end

    it "[!ae733] parses command option definition which has a required param." do
      sc = @schema
      tuple = sc.__send__(:parse_optdef, "-f, --file=<FILE>")
      ok {tuple} == ['f', 'file', '<FILE>', false]
      tuple = sc.__send__(:parse_optdef, "-f <FILE>")
      ok {tuple} == ['f', nil, '<FILE>', false]
      tuple = sc.__send__(:parse_optdef, "--file=<FILE>")
      ok {tuple} == [nil, 'file', '<FILE>', false]
    end

    it "[!4h05c] parses command option definition which has an optional param." do
      sc = @schema
      tuple = sc.__send__(:parse_optdef, "-i, --indent[=<WIDTH>]")
      ok {tuple} == ['i', 'indent', '<WIDTH>', true]
      tuple = sc.__send__(:parse_optdef, "-i[<WIDTH>]")
      ok {tuple} == ['i', nil, '<WIDTH>', true]
      tuple = sc.__send__(:parse_optdef, "--indent[=<WIDTH>]")
      ok {tuple} == [nil, 'indent', '<WIDTH>', true]
    end

    it "[!b7jo3] raises SchemaError when command option definition is invalid." do
      sc = @schema
      pr = proc {
        tuple = sc.__send__(:parse_optdef, "-i, --indent <WIDTH>")
      }
      ok {pr}.raise?(Benry::Cmdopt::SchemaError,
                     "-i, --indent <WIDTH>: invalid option definition (use '=--indent' instead of ' --indent').")
    end

  end


  describe "#add()" do

    before do
      @schema = Benry::Cmdopt::Schema.new
    end

    it "[!7hi2d] takes command option definition string." do
      sc = @schema
      sc.add(:indent, "-i, --indent=<WIDTH>", "print help")
      items = sc.instance_eval { @items }
      ok {items.length} == 1
      ok {items[0]}.is_a?(Benry::Cmdopt::SchemaItem)
      ok {items[0].key} == :indent
      ok {items[0].short} == 'i'
      ok {items[0].long} == 'indent'
      ok {items[0].param} == '<WIDTH>'
      ok {items[0].optional} == false
      ok {items[0].type} == nil
      ok {items[0].pattern} == nil
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
      ok {pr}.raise?(Benry::Cmdopt::SchemaError, msg)
    end

    it "[!97sn0] raises SchemaError when ',' is missing between short and long options." do
      sc = @schema
      pr = proc { sc.add(:exec, '-x --exec=ARG', "exec") }
      msg = "add(:exec, \"-x --exec=ARG\"): missing ',' between short option and long options."
      ok {pr}.raise?(Benry::Cmdopt::SchemaError, msg)
    end

    it "[!yht0v] keeps command option definitions." do
      sc = @schema
      sc.add(:indent, "-i, --indent[=<WIDTH>]", "indent width",
                      type: Integer, pattern: /\A\d+\z/, enum: ['2', '4', '8']) {|v| v.to_i }
      items = sc.instance_eval { @items }
      ok {items.length} == 1
      ok {items[0]}.is_a?(Benry::Cmdopt::SchemaItem)
      ok {items[0].key} == :indent
      ok {items[0].short} == 'i'
      ok {items[0].long} == 'indent'
      ok {items[0].param} == '<WIDTH>'
      ok {items[0].optional} == true
      ok {items[0].type} == Integer
      ok {items[0].pattern} == /\A\d+\z/
      ok {items[0].enum} == ['2', '4', '8']
      ok {items[0].callback}.is_a?(Proc)
      ok {items[0].callback.arity} == 1
    end

    it "[!rhhji] raises SchemaError when key is not a Symbol." do
      sc = @schema
      pr = proc {
        sc.add("-i, --indent[=<WIDTH>]", "indent width", nil)
      }
      ok {pr}.raise?(Benry::Cmdopt::SchemaError,
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
      ok {pr}.raise?(Benry::Cmdopt::SchemaError,
                     'add(:indent, "-i, --indent[=<WIDTH>]"): help message required as 3rd argument.')
    end

    it "[!7xmr5] raises SchemaError when type is not registered." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-i, --indent[=<WIDTH>]", "indent width", type: Array)
      }
      ok {pr}.raise?(Benry::Cmdopt::SchemaError,
                     "Array: unregistered type.")
    end

    it "[!s2aaj] raises SchemaError when option has no params but type specified." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-i, --indent", "indent width", type: Integer)
      }
      ok {pr}.raise?(Benry::Cmdopt::SchemaError,
                     "Integer: type specified in spite of option has no params.")
    end

    it "[!bi2fh] raises SchemaError when pattern is not a regexp." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-x, --indent[=<WIDTH>]", "indent width", pattern: '\A\d+\z')
      }
      ok {pr}.raise?(Benry::Cmdopt::SchemaError,
                     '"\\\\A\\\\d+\\\\z": regexp expected.')
    end

    it "[!01fmt] raises SchmeaError when option has no params but pattern specified." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-i, --indent", "indent width", pattern: /\A\d+\z/)
      }
      ok {pr}.raise?(Benry::Cmdopt::SchemaError,
                     '/\A\d+\z/: pattern specified in spite of option has no params.')
    end

    it "[!melyd] raises SchmeaError when enum is not a Array nor Set." do
      sc = @schema
      sc.add(:indent, "-i <N>", "indent width", enum: ["2", "4", "8"])
      sc.add(:indent, "-i <N>", "indent width", enum: Set.new(["2", "4", "8"]))
      pr = proc {
        sc.add(:indent, "-i <N>", "indent width", enum: "2,4,8")
      }
      ok {pr}.raise?(Benry::Cmdopt::SchemaError,
                     '"2,4,8": array or set expected.')
    end

    it "[!xqed8] raises SchemaError when enum specified for no param option." do
      sc = @schema
      pr = proc {
        sc.add(:indent, "-i", "enable indent", enum: [2, 4, 8])
      }
      ok {pr}.raise?(Benry::Cmdopt::SchemaError,
                     "[2, 4, 8]: enum specified in spite of option has no params.")
    end

  end


  describe '#option_help()' do

    before do
      sc = Benry::Cmdopt::Schema.new
      sc.add(:help   , "-h, --help"            , "show help message.")
      sc.add(:version, "    --version"         , "print version")
      sc.add(:file   , "-f, --file=<FILE>"     , "filename")
      sc.add(:indent , "-i, --indent[=<WIDTH>]", "enable indent", type: Integer)
      sc.add(:debug  , "-d, --debug"           , nil)
      @schema = sc
    end

    it "[!0aq0i] can take integer as width." do
      help = @schema.option_help(41)
      ok {help} == <<END
  -h, --help                                : show help message.
      --version                             : print version
  -f, --file=<FILE>                         : filename
  -i, --indent[=<WIDTH>]                    : enable indent
END
      s = help.each_line.first.split(':')[0]
      ok {s.length} == 41+3
    end

    it "[!pcsah] can take format string." do
      help = @schema.option_help("%-42s: %s")
      ok {help} == <<END
-h, --help                                : show help message.
    --version                             : print version
-f, --file=<FILE>                         : filename
-i, --indent[=<WIDTH>]                    : enable indent
END
      s = help.each_line.first.split(':')[0]
      ok {s.length} == 42+0
    end

    it "[!dndpd] detects option width automatically when nothing specified." do
      help = @schema.option_help()
      ok {help} == <<END
  -h, --help             : show help message.
      --version          : print version
  -f, --file=<FILE>      : filename
  -i, --indent[=<WIDTH>] : enable indent
END
      s = help.each_line.to_a.last.split(':')[0]
      ok {s.length} == 25
    end

    it "[!v7z4x] skips option help if help message is not specified." do
      help = @schema.option_help()
      ok {help} !~ /debug/
    end

    it "[!to1th] includes all option help when `all` is true." do
      help = @schema.option_help(nil, all: true)
      ok {help} =~ /debug/
      ok {help} == <<END
  -h, --help             : show help message.
      --version          : print version
  -f, --file=<FILE>      : filename
  -i, --indent[=<WIDTH>] : enable indent
  -d, --debug            : 
END
    end

    it "[!848rm] supports multi-lines help message." do
      sc = Benry::Cmdopt::Schema.new
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
      sc = Benry::Cmdopt::Schema.new
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
      sc = Benry::Cmdopt::Schema.new
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
      sc = Benry::Cmdopt::Schema.new
      sc.add(:help   , '-h', "help")
      sc.add(:version, '-v', "version")
      ok {sc.__send__(:_preferred_option_width)} == 8
    end

    it "[!0koqb] widen option help min width when any option takes an arg." do
      sc = Benry::Cmdopt::Schema.new
      sc.add(:help   , '-h', "help")
      sc.add(:indent , '-i[<N>]', "indent")
      ok {sc.__send__(:_preferred_option_width)} == 14
    end

    it "[!kl91t] widen option help min width when long option exists." do
      sc = Benry::Cmdopt::Schema.new
      sc.add(:help   , '-h', "help")
      sc.add(:version, '-v, --version', "version")
      ok {sc.__send__(:_preferred_option_width)} == 14
      #
      sc.add(:file, '--file=<FILE>', "filename")
      ok {sc.__send__(:_preferred_option_width)} == 20
    end

  end


  describe '#each_option_help()' do

    before do
      sc = Benry::Cmdopt::Schema.new
      sc.add(:help, "-h, --help", "show help message")
      sc.add(:version, "    --version", "print version")
      @schema = sc
    end

    it "[!4b911] yields each optin definition str and help message." do
      sc = @schema
      arr = []
      sc.each_option_help do |opt, help|
        arr << [opt, help]
      end
      ok {arr} == [
        ["-h, --help", "show help message"],
        ["    --version", "print version"],
      ]
    end

    it "[!zbxyv] returns self." do
      sc = @schema
      ret = sc.each_option_help { nil }
      ok {ret}.same? sc
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



class Benry::Cmdopt::SchemaItem::Test < MiniTest::Test


  describe '#validate_and_convert()' do

    def new_item(key, optstr, short, long, param, help,
                 optional: nil, type: nil, pattern: nil, enum: nil, &callback)
      return Benry::Cmdopt::SchemaItem.new(key, optstr, short, long, param, help,
                 optional: optional, type: type, pattern: pattern, enum: enum, &callback)
    end

    it "[!h0s0o] raises RuntimeError when value not matched to pattern." do
      x = new_item(:indent, "", "i", "indent", "<WIDTH>", "indent width", pattern: /\A\d+\z/)
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

  end

end



class Benry::Cmdopt::Parser::Test < MiniTest::Test


  describe '#parse_options()' do

    before do
      @parser = Benry::Cmdopt::Parser.new(new_sample_schema())
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
      ok {errcls} == Benry::Cmdopt::OptionError
      #
      sc = Benry::Cmdopt::Schema.new
      sc.add(:file, "--file=<FILE>", "file") do |val|
        File.open(val) {|f| f.read }
      end
      parser = Benry::Cmdopt::Parser.new(sc)
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
      @parser = Benry::Cmdopt::Parser.new(new_sample_schema())
    end

    it "[!3i994] raises OptionError when invalid long option format." do
      argv = ["--f/o/o"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "--f/o/o: invalid long option.")
    end

    it "[!er7h4] raises OptionError when unknown long option." do
      argv = ["--foo"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "--foo: unknown long option.")
    end

    it "[!2jd9w] raises OptionError when no arguments specified for arg required long option." do
      argv = ["--file"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "--file: argument required.")
    end

    it "[!qyq8n] raises optionError when an argument specified for no arg long option." do
      argv = ["--version=1.0.0"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "--version=1.0.0: unexpected argument.")
    end

    it "[!o596x] validates argument value." do
      argv = ["--indent=abc"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "--indent=abc: integer expected.")
      #
      argv = ["--path=/foo/bar"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "--path=/foo/bar: directory not exist.")

    end

  end


  describe '#parse_short_option()' do

    before do
      @parser = Benry::Cmdopt::Parser.new(new_sample_schema())
    end

    it "[!4eh49] raises OptionError when unknown short option specified." do
      argv = ["-hxf", "foo.png"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "-x: unknown option.")
    end

    it "[!utdbf] raises OptionError when argument required but not specified." do
      argv = ["-hf"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "-f: argument required.")
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
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "-iaaa: integer expected.")
      #
      argv = ["-I", "/foo/bar"]
      pr = proc { @parser.parse(argv) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "-I /foo/bar: directory not exist.")
    end

  end


  describe '#new_options_dict()' do

    it "[!vm6h0] returns new hash object." do
      parser = Benry::Cmdopt::Parser.new(new_sample_schema())
      ret = parser.__send__(:new_options_dict)
      ok {ret}.is_a?(Hash)
      ok {ret} == {}
    end

  end


end



class Benry::Cmdopt::Test < MiniTest::Test


  describe 'PARAM_TYPES[Integer]' do

    before do
      sc = Benry::Cmdopt::Schema.new
      sc.add(:indent, "-i, --indent[=<N>]", "indent width", type: Integer)
      @parser = Benry::Cmdopt::Parser.new(sc)
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
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "-i2.1: integer expected.")
      #
      pr = proc { @parser.parse(['--indent=2.2']) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "--indent=2.2: integer expected.")
    end

  end


  describe 'PARAM_TYPES[Float]' do

    before do
      sc = Benry::Cmdopt::Schema.new
      sc.add(:ratio, "-r, --ratio=<RATIO>", "ratio", type: Float)
      @parser = Benry::Cmdopt::Parser.new(sc)
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
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "-r abc: float expected.")
      #
      pr = proc { @parser.parse(['--ratio=abc']) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError, "--ratio=abc: float expected.")
    end

  end


  describe 'PARAM_TYPES[TrueClass]' do

    before do
      sc = Benry::Cmdopt::Schema.new
      sc.add(:border  , "-b, --border[=<on|off>]", "enable border", type: TrueClass)
      @parser = Benry::Cmdopt::Parser.new(sc)
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
      ok {pr}.raise?(Benry::Cmdopt::OptionError,
                     "-bt: boolean expected.")
      #
      pr = proc { @parser.parse(["--border=t"]) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError,
                     "--border=t: boolean expected.")
    end

  end


  describe 'PARAM_TYPES[Date]' do

    before do
      require 'date'
      sc = Benry::Cmdopt::Schema.new
      sc.add(:date, "-d, --date=<YYYY-MM-DD>]", "date", type: Date)
      @parser = Benry::Cmdopt::Parser.new(sc)
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
      ok {pr}.raise?(Benry::Cmdopt::OptionError,
                     "-d 2000/01/01: invalid date format (ex: '2000-01-01')")
      #
      pr = proc { @parser.parse(['--date=01-01-2000']) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError,
                     "--date=01-01-2000: invalid date format (ex: '2000-01-01')")
    end

    it "[!i4ui8] raises error when specified date not exist." do
      pr = proc { @parser.parse(['-d', '2001-02-29']) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError,
                     "-d 2001-02-29: date not exist.")
      #
      pr = proc { @parser.parse(['--date=2001-02-29']) }
      ok {pr}.raise?(Benry::Cmdopt::OptionError,
                     "--date=2001-02-29: date not exist.")
    end

  end


  describe '.new()' do

    it "[!7kkqv] creates Facade object." do
      obj = Benry::Cmdopt.new
      ok {obj}.is_a?(Benry::Cmdopt::Facade)
    end

  end


end



class Benry::Cmdopt::Facade::Test < MiniTest::Test


  describe '#add()' do

    it "[!vmb3r] defines command option." do
      cmdopt = Benry::Cmdopt.new()
      cmdopt.add(:help, "-h, --help", "show help message")
      items = cmdopt.instance_eval { @schema.instance_variable_get('@items') }
      ok {items}.is_a?(Array)
      ok {items.length} == 1
      ok {items[0].key} == :help
      ok {items[0].short} == 'h'
      ok {items[0].long} == 'help'
      ok {items[0].help} == 'show help message'
    end

  end


  describe '#option_help()' do

    before do
      @cmdopt = Benry::Cmdopt.new
      @cmdopt.add(:help   , "-h, --help"        , "show help message")
      @cmdopt.add(:version, "    --version"     , "print version")
      @cmdopt.add(:file   , "-f, --file=<FILE>" , "filename")
    end

    it "[!dm4p8] returns option help message." do
      help = @cmdopt.option_help()
      ok {help} == <<END
  -h, --help           : show help message
      --version        : print version
  -f, --file=<FILE>    : filename
END
    end

  end


  describe '#each_option_help()' do

    before do
      @cmdopt = Benry::Cmdopt.new
      @cmdopt.add(:help   , "-h, --help"        , "show help message")
      @cmdopt.add(:version, "    --version"     , "print version")
      @cmdopt.add(:file   , "-f, --file=<FILE>" , "filename")
    end

    it "[!bw9qx] yields each option definition string and help message." do
      cmdopt = @cmdopt
      pairs = []
      cmdopt.each_option_help do |opt, help|
        pairs << [opt, help]
      end
      ok {pairs} == [
        ["-h, --help", "show help message"],
        ["    --version", "print version"],
        ["-f, --file=<FILE>", "filename"],
      ]
    end

  end


  describe '#parse_options()' do

    before do
      @cmdopt = Benry::Cmdopt.new()
      @cmdopt.add(:file, "-f, --file=<FILE>", "file") do |val|
        File.open(val) {|f| f.read }
      end
      @cmdopt.add(:file, "-d, --debug[=<LEVEL>]", "debug", type: Integer)
    end

    it "[!areof] handles only OptionError when block given." do
      errmsg = nil
      errcls = nil
      @cmdopt.parse(["-dx"]) {|err|
        errmsg = err.message
        errcls = err.class
      }
      ok {errmsg} == "-dx: integer expected."
      ok {errcls} == Benry::Cmdopt::OptionError
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

  end


end
