# -*- coding: utf-8 -*-

require 'oktest'

require 'benry/cmdopt'


Oktest.scope do


  def new_sample_schema()
    sc = Benry::CmdOpt::Schema.new
    sc.add(:help   , "-h, --help"            , "show help message.")
    sc.add(:version, "--version"             , "print version")
    sc.add(:file   , "-f, --file=<FILE>"     , "filename")
    sc.add(:indent , "-i, --indent[=<WIDTH>]", "enable indent", type: Integer)
    sc.add(:mode   , "-m, --mode=<MODE>"     , "mode", enum: ['verbose', 'quiet'])
    sc.add(:libpath, "-I, --path=<PATH>"     , "library path (multiple ok)") do |optdef, key, val|
      File.directory?(val)  or raise "Directory not exist."
      arr = optdef[key] || []
      arr << val
      arr
    end
    sc
  end



  topic Benry::CmdOpt::Schema do


    topic '#parse()' do

      before do
        @schema = Benry::CmdOpt::Schema.new
      end

      spec "[!qw0ac] parses command option definition string." do
        sc = @schema
        tuple = sc.__send__(:parse_optdef, "-h, --help")
        ok {tuple} == ['h', 'help', nil, nil]
        tuple = sc.__send__(:parse_optdef, "-h")
        ok {tuple} == ['h', nil, nil, nil]
        tuple = sc.__send__(:parse_optdef, "--help")
        ok {tuple} == [nil, 'help', nil, nil]
      end

      spec "[!ae733] parses command option definition which has a required param." do
        sc = @schema
        tuple = sc.__send__(:parse_optdef, "-f, --file=<FILE>")
        ok {tuple} == ['f', 'file', '<FILE>', true]
        tuple = sc.__send__(:parse_optdef, "-f <FILE>")
        ok {tuple} == ['f', nil, '<FILE>', true]
        tuple = sc.__send__(:parse_optdef, "--file=<FILE>")
        ok {tuple} == [nil, 'file', '<FILE>', true]
      end

      spec "[!4h05c] parses command option definition which has an optional param." do
        sc = @schema
        tuple = sc.__send__(:parse_optdef, "-i, --indent[=<WIDTH>]")
        ok {tuple} == ['i', 'indent', '<WIDTH>', false]
        tuple = sc.__send__(:parse_optdef, "-i[<WIDTH>]")
        ok {tuple} == ['i', nil, '<WIDTH>', false]
        tuple = sc.__send__(:parse_optdef, "--indent[=<WIDTH>]")
        ok {tuple} == [nil, 'indent', '<WIDTH>', false]
      end

      spec "[!b7jo3] raises SchemaError when command option definition is invalid." do
        sc = @schema
        pr = proc {
          tuple = sc.__send__(:parse_optdef, "-i, --indent <WIDTH>")
        }
        ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                       "-i, --indent <WIDTH>: Invalid option definition (use '=--indent' instead of ' --indent').")
      end

    end


    topic '#dup()' do

      before do
        @schema = Benry::CmdOpt::Schema.new
        @schema.add(:help   , "-h" , "print help")
      end

      spec "[!lxb0o] copies self object." do
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


    topic '#copy_from()' do

      before do
        @schema1 = Benry::CmdOpt::Schema.new
        @schema1.add(:help, "-h" , "print help")
        @schema2 = Benry::CmdOpt::Schema.new
        @schema2.add(:version, "-v" , "print version")
        @schema2.add(:debug  , "-D" , "debug mode")
      end

      spec "[!6six3] copy schema items from others." do
        @schema1.copy_from(@schema2)
        tuples = @schema1.each.collect {|x| [x.key, x.optdef, x.desc] }
        ok {tuples} == [
          [:help   , "-h", "print help"],
          [:version, "-v", "print version"],
          [:debug  , "-D", "debug mode"],
        ]
      end

      spec "[!vt88s] copy schema items except items specified by 'except:' kwarg." do
        @schema1.copy_from(@schema2, except: [:debug])
        tuples = @schema1.each.collect {|x| [x.key, x.optdef, x.desc] }
        ok {tuples} == [
          [:help,    "-h", "print help"],
          [:version, "-v", "print version"],
        ]
      end

    end


    topic '#add()' do

      before do
        @schema = Benry::CmdOpt::Schema.new
      end

      spec "[!7hi2d] takes command option definition string." do
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

      spec "[!p9924] option key is omittable only when long option specified." do
        sc = @schema
        sc.add(nil, "-m, --max-num=<N>", nil)
        items = sc.instance_eval { @items }
        ok {items[0].key} == :max_num
      end

      spec "[!jtp7z] raises SchemaError when key is nil and no long option." do
        sc = @schema
        pr = proc { sc.add(nil, "-i <N>", nil) }
        msg = "add(nil, \"-i <N>\"): Long option required when option key (1st arg) not specified."
        ok {pr}.raise?(Benry::CmdOpt::SchemaError, msg)
      end

      spec "[!rpl98] when long option is 'foo-bar' then key name is ':foo_bar'." do
        sc = @schema
        sc.add(nil, "--foo-bar", nil)
        items = sc.instance_eval { @items }
        ok {items[0].key} == :foo_bar
      end

      spec "[!97sn0] raises SchemaError when ',' is missing between short and long options." do
        sc = @schema
        pr = proc { sc.add(:exec, '-x --exec=ARG', "exec") }
        msg = "add(:exec, \"-x --exec=ARG\"): Missing ',' between short option and long options."
        ok {pr}.raise?(Benry::CmdOpt::SchemaError, msg)
      end

      spec "[!yht0v] keeps command option definitions." do
        sc = @schema
        sc.add(:indent, "-i, --indent[=<WIDTH>]", "indent width",
                        range: (1..2), value: 8, detail: "(description)", tag: :ab,
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
        ok {items[0].range} == (1..2)
        ok {items[0].detail} == "(description)"
        ok {items[0].value} == 8
        ok {items[0].tag} == :ab
        ok {items[0].callback}.is_a?(Proc)
        ok {items[0].callback.arity} == 1
      end

      spec "[!kuhf9] type, rexp, enum, and range are can be passed as positional args as well as keyword args." do
        sc = @schema
        sc.add(:key, "--optdef=xx", "desc", Integer, /\A\d+\z/, [2,4,8], (2..8))
        item = sc.each.first
        ok {item.type} == Integer
        ok {item.rexp} == /\A\d+\z/
        ok {item.enum} == [2,4,8]
        ok {item.range} == (2..8)
      end

      spec "[!e3emy] raises error when positional arg is not one of class, regexp, array, nor range." do
        sc = @schema
        pr = proc { sc.add(:key, "--optdef=xx", "desc", "value") }
        ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                       '"value": Expected one of class, regexp, array or range, but got String.')
      end

      spec "[!rhhji] raises SchemaError when key is not a Symbol." do
        sc = @schema
        pr = proc {
          sc.add("-i, --indent[=<WIDTH>]", "indent width", nil)
        }
        ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                       'add("-i, --indent[=<WIDTH>]", "indent width"): The first arg should be a Symbol as an option key.')
      end

      spec "[!vq6eq] raises SchemaError when help message is missing." do
        sc = @schema
        pr = proc {
          begin
            sc.add(:indent, "-i, --indent[=<WIDTH>]", type: Array)   # Ruby 2
          rescue ArgumentError
            sc.add(:indent, "-i, --indent[=<WIDTH>]", {type: Array}) # Ruby 3
          end
        }
        ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                       'add(:indent, "-i, --indent[=<WIDTH>]"): Help message required as 3rd argument.')
      end


    end


    topic '#option_help()' do

      before do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:help   , "-h, --help"            , "show help message.")
        sc.add(:version, "    --version"         , "print version")
        sc.add(:file   , "-f, --file=<FILE>"     , "filename")
        sc.add(:indent , "-i, --indent[=<WIDTH>]", "enable indent", type: Integer)
        sc.add(:debug  , "-d, --debug"           , nil)
        @schema = sc
      end

      spec "[!0aq0i] can take integer as width." do
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

      spec "[!pcsah] can take format string." do
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

      spec "[!dndpd] detects option width automatically when nothing specified." do
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

      spec "[!v7z4x] skips option help if help message is not specified." do
        helpmsg = @schema.option_help()
        ok {helpmsg} !~ /debug/
      end

      spec "[!to1th] includes all option help when `all` is true." do
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

      spec "[!848rm] supports multi-lines help message." do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:mode, "-m, --mode=<MODE>", "output mode",
                      detail: <<"END")
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

      spec "[!a4qe4] option should not be hidden if description is empty string." do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:debug , "-D", nil)       # hidden
        sc.add(:trace, "-T", "trace", hidden: true)   # hidden
        sc.add(:what  , "-W", "")        # NOT hidden!
        ok {sc.option_help()} == <<END
  -W             : 
END
      end

    end


    topic '#_default_format()' do

      before do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:help   , "-h, --help"            , "show help message.")
        sc.add(:version, "    --version"         , "print version")
        sc.add(:file   , "-f, --file=<FILE>"     , "filename")
        sc.add(:indent , "-i, --indent[=<WIDTH>]", "enable indent", type: Integer)
        sc.add(:debug  , "-d, --debug"           , nil)
        @schema = sc
      end

      spec "[!kkh9t] returns format string." do
        ret = @schema.__send__(:_default_format)
        ok {ret} == "  %-22s : %s"
      end

      spec "[!hr45y] detects preffered option width." do
        ret = @schema.__send__(:_default_format, 10, 20)
        ok {ret} == "  %-20s : %s"
        ret = @schema.__send__(:_default_format, 30, 40)
        ok {ret} == "  %-30s : %s"
        ret = @schema.__send__(:_default_format, 10, 40)
        ok {ret} == "  %-22s : %s"
      end

      spec "[!bmr7d] changes min_with according to options." do
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


    topic '#_preferred_option_width()' do

      spec "[!kl91t] shorten option help min width when only single options which take no arg." do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:help   , '-h', "help")
        sc.add(:version, '-v', "version")
        ok {sc.__send__(:_preferred_option_width)} == 8
      end

      spec "[!0koqb] widen option help min width when any option takes an arg." do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:help   , '-h', "help")
        sc.add(:indent , '-i[<N>]', "indent")
        ok {sc.__send__(:_preferred_option_width)} == 14
      end

      spec "[!kl91t] widen option help min width when long option exists." do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:help   , '-h', "help")
        sc.add(:version, '-v, --version', "version")
        ok {sc.__send__(:_preferred_option_width)} == 14
        #
        sc.add(:file, '--file=<FILE>', "filename")
        ok {sc.__send__(:_preferred_option_width)} == 20
      end

    end


    topic '#to_s()' do

      spec "[!rrapd] '#to_s' is an alias to '#option_help()'." do
        schema = Benry::CmdOpt::Schema.new
        schema.add(:help   , "-h, --help"        , "show help message")
        schema.add(:version, "    --version"     , "print version")
        ok {schema.to_s} == schema.option_help()
      end

    end


    topic '#each_option_and_desc()' do

      before do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:help, "-h, --help", "show help message")
        sc.add(:version, "    --version", "print version")
        sc.add(:debug  , "-d, --debug"  , nil)            # hidden
        sc.add(:DEBUG  , "-D, --DEBUG"  , "debug mode", hidden: true)   # hidden
        @schema = sc
      end

      spec "[!4b911] yields each optin definition str and help message." do
        pairs = []
        @schema.each_option_and_desc {|opt, desc| pairs << [opt, desc] }
        ok {pairs} == [
          ["-h, --help"    , "show help message"],  # not hiddden
          ["    --version" , "print version"],      # not hidden
        ]
      end

      spec "[!cl8zy] when 'all' flag is false, not yield hidden items." do
        pairs = []
        @schema.each_option_and_desc(all: false) {|opt, desc| pairs << [opt, desc] }
        ok {pairs} == [
          ["-h, --help"    , "show help message"],  # not hiddden
          ["    --version" , "print version"],      # not hidden
        ]
      end

      spec "[!tc4bk] when 'all' flag is true, yields even hidden items." do
        pairs = []
        @schema.each_option_and_desc(all: true) {|opt, desc| pairs << [opt, desc] }
        ok {pairs} == [
          ["-h, --help"    , "show help message"],  # not hiddden
          ["    --version" , "print version"],      # not hidden
          ["-d, --debug"   , nil],                  # hidden
          ["-D, --DEBUG"   , "debug mode"],         # hidden
        ]
      end

      spec "[!03sux] returns enumerator object if block not given." do
        ## when 'all: true'
        xs = @schema.each_option_and_desc(all: true)
        ok {xs}.is_a?(Enumerator)
        ok {xs.collect {|x, _| x }} == ["-h, --help", "    --version", "-d, --debug", "-D, --DEBUG"]
        ## when 'all: false'
        xs = @schema.each_option_and_desc(all: false)
        ok {xs}.is_a?(Enumerator)
        ok {xs.collect {|x, _| x }} == ["-h, --help", "    --version"]
      end

      spec "[!zbxyv] returns self." do
        ret = @schema.each_option_and_desc { nil }
        ok {ret}.same? @schema
      end

    end


    topic '#each()' do

      before do
        @schema = Benry::CmdOpt::Schema.new
        @schema.add(:help   , "-h, --help"   , "help message")
        @schema.add(:version, "    --version", "print version")
      end

      spec "[!y4k1c] yields each option item." do
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


    topic '#empty?()' do

      spec "[!um8am] returns false if any item exists, else returns true." do
        schema = Benry::CmdOpt::Schema.new
        ok {schema.empty?()} == true
        schema.add(:help   , "-h, --help"   , "help message")
        ok {schema.empty?()} == false
      end

      spec "[!icvm1] ignores hidden items if 'all: false' kwarg specified." do
        schema = Benry::CmdOpt::Schema.new
        schema.add(:debug , "-D", nil)
        schema.add(:trace, "-T", "trace", hidden: true)
        ok {schema.empty?()} == false
        ok {schema.empty?(all: true)} == false
        ok {schema.empty?(all: false)} == true
      end

    end


    topic '#get()' do

      before do
        @schema = Benry::CmdOpt::Schema.new
        @schema.add(:help   , "-h, --help"   , "help message")
        @schema.add(:version, "    --version", "print version")
      end

      spec "[!3wjfp] finds option item object by key." do
        item = @schema.get(:help)
        ok {item.key} == :help
        item = @schema.get(:version)
        ok {item.key} == :version
      end

      spec "[!0spll] returns nil if key not found." do
        ok {@schema.get(:debug)} == nil
      end

    end


    topic '#delete()' do

      before do
        @schema = Benry::CmdOpt::Schema.new
        @schema.add(:help   , "-h, --help"   , "help message")
        @schema.add(:version, "    --version", "print version")
      end

      spec "[!l86rb] deletes option item corresponding to key." do
        keys = @schema.each.collect {|x| x.key }
        ok {keys} == [:help, :version]
        @schema.delete(:help)
        keys = @schema.each.collect {|x| x.key }
        ok {keys} == [:version]
      end

      spec "[!rq0aa] returns deleted item." do
        item = @schema.delete(:version)
        ok {item} != nil
        ok {item.key} == :version
      end

    end


    topic '#find_short_option()' do

      before do
        @schema = new_sample_schema()
      end

      spec "[!b4js1] returns option definition matched to short name." do
        x = @schema.find_short_option('h')
        ok {x.key} == :help
        x = @schema.find_short_option('f')
        ok {x.key} == :file
        x = @schema.find_short_option('i')
        ok {x.key} == :indent
      end

      spec "[!s4d1y] returns nil when nothing found." do
        ok {@schema.find_short_option('v')} == nil
      end

    end


    topic '#find_long_option()' do

      before do
        @schema = new_sample_schema()
      end

      spec "[!atmf9] returns option definition matched to long name." do
        x = @schema.find_long_option('help')
        ok {x.key} == :help
        x = @schema.find_long_option('file')
        ok {x.key} == :file
        x = @schema.find_long_option('indent')
        ok {x.key} == :indent
      end

      spec "[!6haoo] returns nil when nothing found." do
        ok {@schema.find_long_option('lib')} == nil
      end

    end


  end



  topic Benry::CmdOpt::SchemaItem do

    ITEMS = [
      Benry::CmdOpt::SchemaItem.new(:help, "-h, --help", "help msg",
                                    "h", "help", nil, nil),
      Benry::CmdOpt::SchemaItem.new(:file, "-f, --file=<file>", "filename",
                                    "f", "file", "<file>", true),
      Benry::CmdOpt::SchemaItem.new(:indent, "-i, --indent[=<N>]", "indent width",
                                    "i", "indent", "<N>", false),
    ]


    topic '#initialize()' do

      before do
        @schema = Benry::CmdOpt::Schema.new
      end

      spec "[!nn4cp] freezes enum object." do
        item = Benry::CmdOpt::SchemaItem.new(:foo, "--foo", "desc", nil, "foo", "<val>",
                                             true, enum: ["x", "y", "z"])
        ok {item.enum} == ["x", "y", "z"]
        ok {item.enum}.frozen?
      end

      case_when "[!wy2iv] when 'type:' specified..." do

        spec "[!7xmr5] raises SchemaError when type is not registered." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent[=<WIDTH>]", "indent width", type: Array)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "Array: Unregistered type.")
        end

        spec "[!s2aaj] raises SchemaError when option has no params but type specified." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent", "indent width", type: Integer)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "Integer: Type specified in spite of option has no params.")
        end

        spec "[!sz8x2] not raise error when no params but value specified." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent", "indent width", type: Integer, value: 0)
          }
          ok {pr}.NOT.raise?(Exception)
        end

        spec "[!70ogf] not raise error when no params but TrueClass specified." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent", "indent width", type: TrueClass)
          }
          ok {pr}.NOT.raise?(Exception)
        end

      end

      case_when "[!6y8s2] when 'rexp:' specified..." do

        spec "[!bi2fh] raises SchemaError when pattern is not a regexp." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-x, --indent[=<WIDTH>]", "indent width", rexp: '\A\d+\z')
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         '"\\\\A\\\\d+\\\\z": Regexp pattern expected.')
        end

        spec "[!01fmt] raises SchmeaError when option has no params but pattern specified." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent", "indent width", rexp: /\A\d+\z/)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         '/\A\d+\z/: Regexp pattern specified in spite of option has no params.')
        end

      end

      case_when "[!5nrvq] when 'enum:' specified..." do

        spec "[!melyd] raises SchemaError when enum is not an Array nor Set." do
          sc = @schema
          sc.add(:indent, "-i <N>", "indent width", enum: ["2", "4", "8"])
          sc.add(:indent, "-i <N>", "indent width", enum: Set.new(["2", "4", "8"]))
          pr = proc {
            sc.add(:indent, "-i <N>", "indent width", enum: "2,4,8")
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         '"2,4,8": Array or set expected.')
        end

        spec "[!xqed8] raises SchemaError when enum specified for no param option." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i", "enable indent", enum: [2, 4, 8])
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "[2, 4, 8]: Enum specified in spite of option has no params.")
        end

        spec "[!zuthh] raises SchemaError when enum element value is not instance of type class." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i <N>", "enable indent", type: Integer, enum: ['2', '4', '8'])
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         '["2", "4", "8"]: Enum element value should be instance of Integer, but "2" is not.')
        end

      end

      case_when "[!hk4nw] when 'range:' specified..." do

        spec "[!z20ky] raises SchemaError when range is not a Range object." do
          pr = proc {
            @schema.add(:indent, "-i <N>", "indent", type: Integer, range: [1,8])
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "[1, 8]: Range object expected.")
        end

        spec "[!gp025] raises SchemaError when range specified with `type: TrueClass`." do
          pr = proc {
            @schema.add(:indent, "-i <N>", "indent", type: TrueClass, range: 0..1)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "0..1: Range is not available with `type: TrueClass`.")
        end

        spec "[!7njd5] range beginning/end value should be expected type." do
          pr = proc {
            @schema.add(:indent, "-i <N>", "indent", range: (1..8))
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "1..8: Range value should be String, but not.")
          pr = proc {
            @schema.add(:indent, "-i <N>", "indent", type: Date, range: (1..8))
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "1..8: Range value should be Date, but not.")
        end

        spec "[!uymig] range object can be endless." do
          begin
            range1 = eval "(1..)"    # Ruby >= 2.6
            range2 = eval "(..3)"    # Ruby >= 2.6
          rescue SyntaxError
            range1 = nil             # Ruby < 2.6
            range2 = nil             # Ruby < 2.6
          end
          if range1
            pr = proc {
              @schema.add(:indent1, "-i <N>", "indent", type: Integer, range: range1)
              @schema.add(:indent2, "-j <N>", "indent", type: Integer, range: range2)
            }
            pr.call
            ok {pr}.NOT.raise?(Exception)
          end
        end

      end

      case_when "[!a0g52] when 'value:' specified..." do

        spec "[!435t6] raises SchemaError when 'value:' is specified on argument-required option." do
          sc = @schema
          pr = proc {
            sc.add(:flag, "--flag=<on|off>", "flag", type: TrueClass, value: true)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "true: 'value:' is meaningless when option has required argument (hint: change to optional argument instead).")
        end

        spec "[!6vwqv] raises SchemaError when type is TrueClass but value is not true nor false." do
          sc = @schema
          pr = proc {
            sc.add(:flag, "--flag[=<on|off>]", "flag", type: TrueClass, value: 0)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "0: Value should be true or false when `type: TrueClass` specified.")
        end

        spec "[!c6i2o] raises SchemaError when value is not a kind of type." do
          sc = @schema
          pr = proc {
            sc.add(:flag, "--flag[=<on|off>]", "flag", type: Integer, value: false)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "Type mismatched between `type: Integer` and `value: false`.")
        end

        spec "[!lnhp6] not raise error when type is not specified." do
          sc = @schema
          pr = proc {
            sc.add(:flag, "--flag[=<on|off>]", "flag", value: false)
          }
          ok {pr}.NOT.raise?(Exception)
        end

        spec "[!6xb8o] value should be included in enum values." do
          sc = @schema
          pr = proc {
            sc.add(:lang, "--lang[=<en|fr|it>]", "language", enum: ["en", "fr", "it"], value: "ja")
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "ja: Value should be included in enum values, but not.")
        end

      end

    end


    topic '#required?' do

      spec "[!svxny] returns nil if option takes no arguments." do
        item, _, _ = ITEMS
        ok {item.required?} == nil
      end

      spec "[!togcx] returns true if argument is required." do
        _, item, _ = ITEMS
        ok {item.required?} == true
      end

      spec "[!uwbgc] returns false if argument is optional." do
        _, _, item = ITEMS
        ok {item.required?} == false
      end

    end


    topic '#arg_requireness()' do

      spec "[!kmo28] returns :none if option takes no arguments." do
        item, _, _ = ITEMS
        ok {item.arg_requireness()} == :none
      end

      spec "[!s8gxl] returns :required if argument is required." do
        _, item, _ = ITEMS
        ok {item.arg_requireness()} == :required
      end

      spec "[!owpba] returns :optional if argument is optional." do
        _, _, item = ITEMS
        ok {item.arg_requireness()} == :optional
      end

    end


    topic '#hidden?()' do

      spec "[!no6ov] returns true if @hidden is true." do
        item = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil, hidden: true)
        ok {item.hidden?} == true
      end

      spec "[!ej8ot] returns false if @hidden is false." do
        item = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil, hidden: false)
        ok {item.hidden?} == false
      end

      spec "[!h0uxs] returns true if desc is nil." do
        desc = nil
        item = Benry::CmdOpt::SchemaItem.new(:debug, "-D", desc, "D", nil, nil, nil)
        ok {item.hidden?} == true
      end

      spec "[!28vzx] returns false if else." do
        desc = "debug mode"
        item = Benry::CmdOpt::SchemaItem.new(:debug, "-D", desc, "D", nil, nil, nil)
        ok {item.hidden?} == false
      end

    end


    topic '#important?()' do

      spec "[!ua8kt] returns true/false if `important:` kwarg passed to constructor." do
        item1 = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil, important: true)
        ok {item1.important?} == true
        item2 = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil, important: false)
        ok {item2.important?} == false
      end

      spec "[!hz9sx] returns nil if `important:` kwarg not passed to constructor." do
        item3 = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil)
        ok {item3.important?} == nil
      end

    end


    topic '#validate_and_convert()' do

      def new_item(key, optstr, desc, short, long, param, required,
                   type: nil, rexp: nil, enum: nil, range: nil, value: nil, &callback)
        return Benry::CmdOpt::SchemaItem.new(key, optstr, desc, short, long, param, required,
                   type: type, rexp: rexp, enum: enum, range: range, value: value, &callback)
      end

      spec "[!h0s0o] raises RuntimeError when value not matched to pattern." do
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, rexp: /\A\d+\z/)
        optdict = {}
        pr = proc { x.validate_and_convert("abc", optdict) }
        ok {pr}.raise?(RuntimeError, "Pattern unmatched.")
      end

      spec "[!5jrdf] raises RuntimeError when value not in enum." do
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, enum: ['2', '4', '8'])
        optdict = {}
        pr = proc { x.validate_and_convert("10", optdict) }
        ok {pr}.raise?(RuntimeError, "Expected one of 2/4/8.")
      end

      spec "[!5falp] raise RuntimeError when value not in range." do
        x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                     type: Integer, range: 2..8)
        optdict = {}
        pr = proc { x.validate_and_convert("1", optdict) }
        ok {pr}.raise?(RuntimeError, "Too small (min: 2)")
        pr = proc { x.validate_and_convert("9", optdict) }
        ok {pr}.raise?(RuntimeError, "Too large (max: 8)")
        ## when min==0
        x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                     type: Integer, range: 0..8)
        optdict = {}
        pr = proc { x.validate_and_convert("-1", optdict) }
        ok {pr}.raise?(RuntimeError, "Positive value (>= 0) expected.")
        ## when min==1
        x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                     type: Integer, range: 1..8)
        optdict = {}
        pr = proc { x.validate_and_convert("0", optdict) }
        ok {pr}.raise?(RuntimeError, "Positive value (>= 1) expected.")
      end

      spec "[!a0rej] supports endless range." do
        begin
          range1 = eval "(2..)"     # Ruby >= 2.6
          range2 = eval "(..8)"
        rescue SyntaxError
          range1 = nil              # Ruby < 2.6
          range2 = nil
        end
        if range1
          x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                       type: Integer, range: range1)
          optdict = {}
          pr = proc { x.validate_and_convert("1", optdict) }
          ok {pr}.raise?(RuntimeError, "Too small (min: 2)")
          pr = proc { x.validate_and_convert("9", optdict) }
          ok {pr}.NOT.raise?(RuntimeError)
        end
        if range2
          x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                       type: Integer, range: range2)
          optdict = {}
          pr = proc { x.validate_and_convert("1", optdict) }
          ok {pr}.NOT.raise?(RuntimeError)
          pr = proc { x.validate_and_convert("9", optdict) }
          ok {pr}.raise?(RuntimeError, "Too large (max: 8)")
        end
      end

      spec "[!j4fuz] calls type-specific callback when type specified." do
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, type: Integer)
        optdict = {}
        pr = proc { x.validate_and_convert("abc", optdict) }
        ok {pr}.raise?(RuntimeError, "Integer expected.")
      end

      spec "[!jn9z3] calls callback when callback specified." do
        called = false
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false) {|va|
          called = true
        }
        optdict = {}
        x.validate_and_convert("abc", optdict)
        ok {called} == true
      end

      spec "[!iqalh] calls callback with different number of args according to arity." do
        args1 = nil
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false) {|val|
          args1 = val
        }
        optdict = {}
        x.validate_and_convert("123", optdict)
        ok {args1} == "123"
        #
        args2 = nil
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false) {|optdict, key, val|
          args2 = [optdict, key, val]
        }
        optdict = {}
        x.validate_and_convert("123", optdict)
        ok {args2} == [optdict, :indent, "123"]
      end

      spec "[!x066l] returns new value." do
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, type: Integer)
        ok {x.validate_and_convert("123", {})} == 123
        #
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, type: Integer) {|val|
          val * 2
        }
        ok {x.validate_and_convert("123", {})} == 246
      end

      spec "[!eafem] returns default value (if specified) instead of true value." do
        x1 = new_item(:flag, "", "desc", "f", "flag", nil, false, value: nil)
        ok {x1.validate_and_convert(true, {})} == true
        x2 = new_item(:flag, "", "desc", "f", "flag", nil, false, value: "blabla")
        ok {x2.validate_and_convert(true, {})} == "blabla"
        x3 = new_item(:flag, "", "desc", "f", "flag", nil, false, value: false)
        ok {x3.validate_and_convert(true, {})} == false
      end

    end

  end



  topic Benry::CmdOpt::Parser do


    topic '#parse_options()' do

      before do
        @parser = Benry::CmdOpt::Parser.new(new_sample_schema())
      end

      spec "[!3wmsy] returns command option values as a dict." do
        argv = ["-h", "--version"]
        d = @parser.parse(argv)
        ok {d} == {help: true, version: true}
      end

      spec "[!uh7j8] parses long options." do
        argv = ["--help", "--file=foo.png", "--indent=10"]
        d = @parser.parse(argv)
        ok {d} == {help: true, file: "foo.png", indent: 10}
      end

      spec "[!nwnjc] parses short options." do
        argv = ["-h", "-f", "foo.png", "-i10"]
        d = @parser.parse(argv)
        ok {d} == {help: true, file: "foo.png", indent: 10}
      end

      spec "[!5s5b6] treats '-' as an argument, not an option." do
        argv = ["-h", "-", "xxx", "yyy"]
        d = @parser.parse(argv)
        ok {d} == {help: true}
        ok {argv} == ["-", "xxx", "yyy"]
      end

      spec "[!q8356] parses options even after arguments when `all: true`." do
        argv = ["-h", "arg1", "-f", "foo.png", "arg2", "-i10", "arg3"]
        d = @parser.parse(argv, all: true)
        ok {d} == {help: true, file: "foo.png", indent: 10}
        ok {argv} == ["arg1", "arg2", "arg3"]
        #
        argv = ["-h", "arg1", "-f", "foo.png", "arg2", "-i10", "arg3"]
        d = @parser.parse(argv)
        ok {d} == {help: true, file: "foo.png", indent: 10}
        ok {argv} == ["arg1", "arg2", "arg3"]
      end

      spec "[!ryra3] doesn't parse options after arguments when `all: false`." do
        argv = ["-h", "arg1", "-f", "foo.png", "arg2", "-i10", "arg3"]
        d = @parser.parse(argv, all: false)
        ok {d} == {help: true}
        ok {argv} == ["arg1", "-f", "foo.png", "arg2", "-i10", "arg3"]
      end

      spec "[!y04um] skips rest options when '--' found in argv." do
        argv = ["-h", "--", "-f", "foo.png", "-i10"]
        d = @parser.parse(argv)
        ok {d} == {help: true}
        ok {argv} == ["-f", "foo.png", "-i10"]
      end

      spec "[!qpuxh] handles only OptionError when block given." do
        errmsg = nil
        errcls = nil
        @parser.parse(["-ix"]) {|err|
          errmsg = err.message
          errcls = err.class
        }
        ok {errmsg} == "-ix: Integer expected."
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

      spec "[!dhpw1] returns nil when OptionError handled." do
        ret = @parser.parse(["-dx"]) {|err| 1 }
        ok {ret} == nil
      end

    end


    topic '#parse_long_option()' do

      before do
        @parser = Benry::CmdOpt::Parser.new(new_sample_schema())
      end

      spec "[!3i994] raises OptionError when invalid long option format." do
        argv = ["--f/o/o"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--f/o/o: Invalid long option.")
      end

      spec "[!1ab42] invokes error handler method when unknown long option." do
        def @parser.handle_unknown_long_option(optstr, name, val)
          (@_called_ ||= []) << [optstr, name, val]
        end
        ret = @parser.parse(["--xx=XX", "--yy=YY", "--zz"])
        ok {ret} == {}
        ok {@parser.instance_variable_get('@_called_')} == [
          ["--xx=XX", "xx", "XX"],
          ["--yy=YY", "yy", "YY"],
          ["--zz"   , "zz", nil],
        ]
      end

      spec "[!er7h4] default behavior is to raise OptionError when unknown long option." do
        argv = ["--foo"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--foo: Unknown long option.")
      end

      spec "[!2jd9w] raises OptionError when no arguments specified for arg required long option." do
        argv = ["--file"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--file: Argument required.")
      end

      spec "[!qyq8n] raises optionError when an argument specified for no arg long option." do
        argv = ["--version=1.0.0"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--version=1.0.0: Unexpected argument.")
      end

      spec "[!o596x] validates argument value." do
        argv = ["--indent=abc"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--indent=abc: Integer expected.")
        #
        argv = ["--path=/foo/bar"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--path=/foo/bar: Directory not exist.")

      end

    end


    topic '#parse_short_option()' do

      before do
        @parser = Benry::CmdOpt::Parser.new(new_sample_schema())
      end

      spec "[!4eh49] raises OptionError when unknown short option specified." do
        argv = ["-hxf", "foo.png"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-x: Unknown option.")
      end

      spec "[!utdbf] raises OptionError when argument required but not specified." do
        argv = ["-hf"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-f: Argument required.")
      end

      spec "[!f63hf] short option arg can be specified without space separator." do
        argv = ["-hfabc.png", "xx"]
        d = @parser.parse(argv)
        ok {d} == {help: true, file: "abc.png"}
        ok {argv} == ["xx"]
      end

      spec "[!yjq6b] optional arg should be specified without space separator." do
        argv = ["-hi123", "xx"]
        d = @parser.parse(argv)
        ok {d} == {help: true, indent: 123}
        ok {argv} == ['xx']
      end

      spec "[!wape4] otpional arg can be omit." do
        argv = ["-hi", "xx"]
        d = @parser.parse(argv)
        ok {d} == {help: true, indent: true}
        ok {argv} == ['xx']
      end

      spec "[!yu0kc] validates short option argument." do
        argv = ["-iaaa"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-iaaa: Integer expected.")
        #
        argv = ["-I", "/foo/bar"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-I /foo/bar: Directory not exist.")
      end

    end


    topic '#new_options_dict()' do

      spec "[!vm6h0] returns new hash object." do
        parser = Benry::CmdOpt::Parser.new(new_sample_schema())
        ret = parser.__send__(:new_options_dict)
        ok {ret}.is_a?(Hash)
        ok {ret} == {}
      end

    end


    topic '#handle_unknown_long_option()' do

      spec "[!0q78a] raises OptionError." do
        parser = Benry::CmdOpt::Parser.new(new_sample_schema())
        pr = proc {
          parser.__send__(:handle_unknown_long_option, "--xx=XX", "xx", "XX")
        }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--xx=XX: Unknown long option.")
      end

    end


  end



  topic Benry::CmdOpt do


    topic 'PARAM_TYPES[Integer]' do

      before do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:indent, "-i, --indent[=<N>]", "indent width", type: Integer)
        @parser = Benry::CmdOpt::Parser.new(sc)
      end

      spec "[!6t8cs] converts value into integer." do
        d = @parser.parse(['-i20'])
        ok {d[:indent]} == 20
        #
        d = @parser.parse(['--indent=12'])
        ok {d[:indent]} == 12
      end

      spec "[!nzwc9] raises error when failed to convert value into integer." do
        pr = proc { @parser.parse(['-i2.1']) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-i2.1: Integer expected.")
        #
        pr = proc { @parser.parse(['--indent=2.2']) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--indent=2.2: Integer expected.")
      end

    end


    topic 'PARAM_TYPES[Float]' do

      before do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:ratio, "-r, --ratio=<RATIO>", "ratio", type: Float)
        @parser = Benry::CmdOpt::Parser.new(sc)
      end

      spec "[!gggy6] converts value into float." do
        d = @parser.parse(['-r', '1.25'])
        ok {d[:ratio]} == 1.25
        #
        d = @parser.parse(['--ratio=1.25'])
        ok {d[:ratio]} == 1.25
      end

      spec "[!t4elj] raises error when faield to convert value into float." do
        pr = proc { @parser.parse(['-r', 'abc']) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-r abc: Float expected.")
        #
        pr = proc { @parser.parse(['--ratio=abc']) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--ratio=abc: Float expected.")
      end

    end


    topic 'PARAM_TYPES[TrueClass]' do

      before do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:border  , "-b, --border[=<on|off>]", "enable border", type: TrueClass)
        @parser = Benry::CmdOpt::Parser.new(sc)
      end

      spec "[!47kx4] converts 'true'/'on'/'yes' into true." do
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

      spec "[!3n810] converts 'false'/'off'/'no' into false." do
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

      spec "[!h8ayh] raises error when failed to convert value into true nor false." do
        pr = proc { @parser.parse(["-bt"]) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError,
                       "-bt: Boolean expected.")
        #
        pr = proc { @parser.parse(["--border=t"]) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError,
                       "--border=t: Boolean expected.")
      end

    end


    topic 'PARAM_TYPES[Date]' do

      before do
        require 'date'
        sc = Benry::CmdOpt::Schema.new
        sc.add(:date, "-d, --date=<YYYY-MM-DD>]", "date", type: Date)
        @parser = Benry::CmdOpt::Parser.new(sc)
      end

      spec "[!sru5j] converts 'YYYY-MM-DD' into date object." do
        d = @parser.parse(['-d', '2000-01-01'])
        ok {d[:date]} == Date.new(2000, 1, 1)
        #
        d = @parser.parse(['--date=2000-1-2'])
        ok {d[:date]} == Date.new(2000, 1, 2)
      end

      spec "[!h9q9y] raises error when failed to convert into date object." do
        pr = proc { @parser.parse(['-d', '2000/01/01']) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError,
                       "-d 2000/01/01: Invalid date format (ex: '2000-01-01')")
        #
        pr = proc { @parser.parse(['--date=01-01-2000']) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError,
                       "--date=01-01-2000: Invalid date format (ex: '2000-01-01')")
      end

      spec "[!i4ui8] raises error when specified date not exist." do
        pr = proc { @parser.parse(['-d', '2001-02-29']) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError,
                       "-d 2001-02-29: Date not exist.")
        #
        pr = proc { @parser.parse(['--date=2001-02-29']) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError,
                       "--date=2001-02-29: Date not exist.")
      end

    end


    topic '.new()' do

      spec "[!7kkqv] creates Facade object." do
        obj = Benry::CmdOpt.new
        ok {obj}.is_a?(Benry::CmdOpt::Facade)
      end

    end


  end



  topic Benry::CmdOpt::Facade do


    topic '#add()' do

      spec "[!vmb3r] defines command option." do
        cmdopt = Benry::CmdOpt.new()
        cmdopt.add(:help, "-h, --help", "show help message", detail: "(text)", tag: :important)
        items = cmdopt.instance_eval { @schema.instance_variable_get('@items') }
        ok {items}.is_a?(Array)
        ok {items.length} == 1
        ok {items[0].key} == :help
        ok {items[0].short} == 'h'
        ok {items[0].long} == 'help'
        ok {items[0].desc} == 'show help message'
        ok {items[0].detail} == '(text)'
        ok {items[0].tag} == :important
      end

      spec "[!71cvg] type, rexp, enum, and range are can be passed as positional args as well as keyword args." do
        cmdopt = Benry::CmdOpt.new()
        cmdopt.add(:key, "--optdef[=xx]", "desc", Integer, /\A\d+\z/, [2,4,8], (2..8), value: 4)
        items = cmdopt.instance_eval { @schema.instance_variable_get('@items') }
        item = items.first
        ok {item.type} == Integer
        ok {item.rexp} == /\A\d+\z/
        ok {item.enum} == [2,4,8]
        ok {item.range} == (2..8)
        ok {item.value} == 4
      end

      spec "[!tu4k3] returns self." do
        cmdopt = Benry::CmdOpt.new()
        x = cmdopt.add(:version, "-v, --version", "version")
        ok {x}.same?(cmdopt)
      end

    end


    topic '#option_help()' do

      before do
        @cmdopt = Benry::CmdOpt.new
        @cmdopt.add(:help   , "-h, --help"        , "show help message")
        @cmdopt.add(:version, "    --version"     , "print version")
        @cmdopt.add(:file   , "-f, --file=<FILE>" , "filename")
      end

      spec "[!dm4p8] returns option help message." do
        helpmsg = @cmdopt.option_help()
        ok {helpmsg} == <<END
  -h, --help           : show help message
      --version        : print version
  -f, --file=<FILE>    : filename
END
      end

    end


    topic '#to_s()' do

      spec "[!s61vo] '#to_s' is an alias to '#option_help()'." do
        cmdopt = Benry::CmdOpt.new
        cmdopt.add(:help   , "-h, --help"        , "show help message")
        cmdopt.add(:version, "    --version"     , "print version")
        ok {cmdopt.to_s} == cmdopt.option_help()
      end

    end


    topic '#each_option_and_desc()' do

      before do
        @cmdopt = Benry::CmdOpt.new
        @cmdopt.add(:help   , "-h, --help"        , "show help message")
        @cmdopt.add(:version, "    --version"     , "print version")
        @cmdopt.add(:debug  , "-D"                , nil)       # hidden option
        @cmdopt.add(:trace  , "-T"                , "trace", hidden: true)  # hidden option
      end

      spec "[!bw9qx] yields each option definition string and help message." do
        pairs = []
        @cmdopt.each_option_and_desc {|opt, desc| pairs << [opt, desc] }
        ok {pairs} == [
          ["-h, --help"   , "show help message"],
          ["    --version", "print version"],
        ]
      end

      spec "[!kunfw] yields all items (including hidden items) if `all: true` specified." do
        ## when 'all: true'
        pairs = []
        @cmdopt.each_option_and_desc(all: true) {|opt, desc| pairs << [opt, desc] }
        ok {pairs} == [
          ["-h, --help"   , "show help message"],
          ["    --version", "print version"],
          ["-D"           , nil],
          ["-T"           , "trace"],
        ]
        ## when 'all: false'
        pairs = []
        @cmdopt.each_option_and_desc(all: false) {|opt, desc| pairs << [opt, desc] }
        ok {pairs} == [
          ["-h, --help"   , "show help message"],
          ["    --version", "print version"],
        ]
      end

      spec "[!wght5] returns enumerator object if block not given." do
        ## when 'all: true'
        xs = @cmdopt.each_option_and_desc(all: true)
        ok {xs}.is_a?(Enumerator)
        ok {xs.collect {|x, _| x }} == ["-h, --help", "    --version", "-D", "-T"]
        ## when 'all: false'
        xs = @cmdopt.each_option_and_desc(all: false)
        ok {xs}.is_a?(Enumerator)
        ok {xs.collect {|x, _| x }} == ["-h, --help", "    --version"]
      end

    end


    topic '#parse()' do

      before do
        @cmdopt = Benry::CmdOpt.new()
        @cmdopt.add(:file, "-f, --file=<FILE>", "file") do |val|
          File.open(val) {|f| f.read }
        end
        @cmdopt.add(:debug, "-d, --debug[=<LEVEL>]", "debug", type: Integer)
      end

      spec "[!7gc2m] parses command options." do
        args = ["-d", "x", "y"]
        @cmdopt.parse(args)
        ok {args} == ["x", "y"]
      end

      spec "[!no4xu] returns option values as dict." do
        args = ["-d", "x"]
        ok {@cmdopt.parse(args)} == {:debug=>true}
      end

      spec "[!areof] handles only OptionError when block given." do
        errmsg = nil
        errcls = nil
        @cmdopt.parse(["-dx"]) {|err|
          errmsg = err.message
          errcls = err.class
        }
        ok {errmsg} == "-dx: Integer expected."
        ok {errcls} == Benry::CmdOpt::OptionError
        #
        pr = proc do
          @cmdopt.parse(["-f", "/foo/bar/baz.png"])
        end
        ok {pr}.raise?(Errno::ENOENT, /No such file or directory/)
      end

      spec "[!peuva] returns nil when OptionError handled." do
        ret = @cmdopt.parse(["-dx"]) {|err| 1 }
        ok {ret} == nil
      end

      spec "[!za9at] parses options only before args when `all: false`." do
        argv = ["aaa", "-d3", "bbb"]
        #
        argv1 = argv.dup
        opts1 = @cmdopt.parse(argv1)
        ok {opts1} == {:debug=>3}
        ok {argv1} == ["aaa", "bbb"]
        #
        argv2 = argv.dup
        opts2 = @cmdopt.parse(argv2, all: false)
        ok {opts2} == {}
        ok {argv2} == ["aaa", "-d3", "bbb"]
      end

    end


  end


end
