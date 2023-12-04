# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  def new_test_schema()
    sc = Benry::CmdOpt::Schema.new
    sc.add(:help   , "-h, --help"            , "show help message.")
    sc.add(:version, "--version"             , "print version")
    sc.add(:file   , "-f, --file=<FILE>"     , "filename")
    sc.add(:indent , "-i, --indent[=<WIDTH>]", "enable indent", type: Integer)
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


    topic '#add_item()' do

      spec "[!qyjp9] raises SchemaError if invalid item added." do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:quiet, "-q, --quiet", "quiet mode")
        #
        item1 = Benry::CmdOpt::SchemaItem.new(:quiet, "-q", "quiet", "q", nil, nil, false)
        pr = proc { sc.add_item(item1) }
        ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                       "quiet: Option key duplicated.")
        #
        item2 = Benry::CmdOpt::SchemaItem.new(:quiet2, "-q", "quiet", "q", nil, nil, false)
        pr = proc { sc.add_item(item2) }
        ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                       "-q: Short option duplicated (key: quiet2 and quiet).")
        #
        item3 = Benry::CmdOpt::SchemaItem.new(:quiet3, "--quiet", "quiet", nil, "quiet", nil, false)
        pr = proc { sc.add_item(item3) }
        ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                       "--quiet: Long option duplicated (key: quiet3 and quiet).")
      end

      spec "[!a693h] adds option item into current schema." do
        item = Benry::CmdOpt::SchemaItem.new(:quiet, "-q", "quiet", "q", nil, nil, false)
        sc = Benry::CmdOpt::Schema.new
        sc.add_item(item)
        ok {sc.to_s} == <<"END"
  -q       : quiet
END
      end

    end


    topic '#_validate_item()' do

      before do
        @schema = Benry::CmdOpt::Schema.new
        @schema.add(:quiet, "-q, --quiet", "quiet mode")
      end

      spec "[!ewl20] returns error message if option key duplicated." do
        item = Benry::CmdOpt::SchemaItem.new(:quiet, "-q", "quiet mode", "q", nil, nil, false)
        ret = @schema.__send__(:_validate_item, item)
        ok {ret} == "quiet: Option key duplicated."
      end

      spec "[!xg56v] returns error message if short option duplicated." do
        item = Benry::CmdOpt::SchemaItem.new(:quiet2, "-q", "quiet mode", "q", nil, nil, false)
        ret = @schema.__send__(:_validate_item, item)
        ok {ret} == "-q: Short option duplicated (key: quiet2 and quiet)."
      end

      spec "[!izezi] returns error message if long option duplicated." do
        item = Benry::CmdOpt::SchemaItem.new(:quiet3, "--quiet", "quiet mode", nil, "quiet", nil, false)
        ret = @schema.__send__(:_validate_item, item)
        ok {ret} == "--quiet: Long option duplicated (key: quiet3 and quiet)."
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

      fixture :schema_with_importance do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:help  , "-h, --help" , "help message")
        sc.add(:trace , "-T, --trace", "trace"      , important: true)
        sc.add(:debug , "-D, --debug", "debug mode" , important: false)
        sc.add(:quiet , "-q, --quiet", "quiet mode")
        sc
      end

      spec "[!jrwb6] decorates help message according to `important:` value of option." do
        |schema_with_importance|
        sc = schema_with_importance
        ok {sc.option_help()} == <<END
  -h, --help     : help message
\e[1m  -T, --trace    : trace\e[0m
\e[2m  -D, --debug    : debug mode\e[0m
  -q, --quiet    : quiet mode
END
      end

      spec "[!9nlfb] not decorate help message when stdout is not a tty." do
        |schema_with_importance|
        sc = schema_with_importance
        output = nil
        capture_sio() {
          ok {$stdout}.NOT.tty?
          output = sc.option_help()
        }
        ok {output} == <<END
  -h, --help     : help message
  -T, --trace    : trace
  -D, --debug    : debug mode
  -q, --quiet    : quiet mode
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
        @schema = new_test_schema()
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
        @schema = new_test_schema()
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


end
