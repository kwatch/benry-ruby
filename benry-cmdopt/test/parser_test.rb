# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  def new_sample_schema()
    sc = Benry::CmdOpt::Schema.new
    sc.add(:help   , "-h, --help"            , "show help message.")
    sc.add(:version, "--version"             , "print version")
    sc.add(:file   , "-f, --file=<FILE>"     , "filename")
    sc.add(:indent , "-i, --indent[=<WIDTH>]", "enable indent", type: Integer)
    sc.add(:mode   , "-m, --mode=<MODE>"     , "mode", enum: ['verbose', 'quiet'])
    sc.add(:include, "-I, --include=<PATH>"  , "include path (multiple ok)", multiple: true)
    sc.add(:libpath, "-L, --path=<PATH>"     , "library path (multiple ok)") do |optdef, key, val|
      File.directory?(val)  or raise "Directory not exist."
      arr = optdef[key] || []
      arr << val
      arr
    end
    sc
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

      spec "[!1m87b] supports multiple option." do
        argv = ["--include=/foo", "--include=/bar"]
        opts = @parser.parse(argv)
        ok {opts} == {:include=>["/foo", "/bar"]}
        ok {argv} == []
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
        argv = ["-L", "/foo/bar"]
        pr = proc { @parser.parse(argv) }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-L /foo/bar: Directory not exist.")
      end

      spec "[!187r2] supports multiple option." do
        argv = ["-I", "/foo", "-I/bar"]
        opts = @parser.parse(argv)
        ok {opts} == {:include=>["/foo", "/bar"]}
        ok {argv} == []
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


    topic '#store_option_value()' do

      spec "[!my86j] stores multiple values if multiple option item." do
        schema = Benry::CmdOpt::Schema.new()
        item = schema.add(:includes, "-I <path>", "include path", multiple: true)
        parser = Benry::CmdOpt::Parser.new(schema)
        optdict = {}
        parser.instance_eval do
          store_option_value(optdict, item, "/usr/include")
          store_option_value(optdict, item, "/usr/local/include")
        end
        ok {optdict} == {:includes => ["/usr/include", "/usr/local/include"]}
      end

      spec "[!tm7xw] stores singile value if not multiple option item." do
        schema = Benry::CmdOpt::Schema.new()
        item = schema.add(:include, "-I <path>", "include path")
        parser = Benry::CmdOpt::Parser.new(schema)
        optdict = {}
        parser.instance_eval do
          store_option_value(optdict, item, "/usr/include")
          store_option_value(optdict, item, "/usr/local/include")
        end
        ok {optdict} == {:include => "/usr/local/include"}
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


end
