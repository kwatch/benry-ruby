# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::TaskOptionParser do

    fixture :parser1 do
      schema = Benry::MicroRake::TaskOptionSchema.new()
      schema.add(:quiet , "-q, --quiet"       , "quiet mode")
      schema.add(:lang  , "-l, --lang=<LANG>" , "language", ["en", "fr", "it"])
      schema.add(:indent, "-i, --indent[=<N>]", "indent width", Integer)
      Benry::MicroRake::TaskOptionParser.new(schema)
    end

    fixture :parser2 do
      block = proc {|name, lang_: nil, color: false, opt_i_: nil, opt_q: false| nil }
      schema = Benry::MicroRake::TaskOptionSchema.create_from(block)
      Benry::MicroRake::TaskOptionParser.new(schema)
    end


    topic '#parse()' do

      spec "[!dnywk] parses command options according to option schema." do
        |parser1, parser2|
        args = ["-ql", "fr", "--help", "-i10", "Alice", "Bob"]
        opts = parser1.parse(args)
        ok {opts} == {quiet: true, lang: "fr", help: true, indent: 10}
        ok {args} == ["Alice", "Bob"]
        #
        args = ["-qh", "--lang=fr", "-i", "10", "Alice", "Bob"]
        opts = parser2.parse(args)
        ok {opts} == {opt_q: true, lang_: "fr", help: true, opt_i_: 10}
        ok {args} == ["Alice", "Bob"]
      end

      spec "[!nmbje] can convert option values such as `\"1\"`->`1`." do
        |parser1, parser2|
        args = ["-i10"]
        opts = parser1.parse(args)
        ok {opts} == {indent: 10}
        #
        args = ["-i", "10"]
        opts = parser2.parse(args)
        ok {opts} == {opt_i_: 10}
      end

    end


    topic '#parse_long_option()' do

      spec "[!oj9l8] raises error when short option specified in long option style." do
        |parser2|
        args = nil
        pr = proc do
          parser2.parse(args)
        end
        args = ["--opt_q"]
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--opt_q: Unknown long option.")
        args = ["--opt-q"]
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--opt-q: Unknown long option.")
        args = ["--opt_i_=10"]
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--opt_i_=10: Unknown long option.")
        args = ["--opt-i-=10"]
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "--opt-i-=10: Unknown long option.")
      end

    end


    topic '#_convert_value()' do

      spec "[!xu992] converts `\"123\"` to `123`." do
        |parser2|
        parser2.instance_exec(self) do |_|
          _.ok {_convert_value("123")} == 123
          _.ok {_convert_value("-123")} == -123
        end
      end

      spec "[!9bt0s] converts `\"3.14\"` to `3.14`." do
        |parser2|
        parser2.instance_exec(self) do |_|
          _.ok {_convert_value("3.14")} == 3.14
          _.ok {_convert_value("-3.14")} == -3.14
        end
      end

      spec "[!wtzal] converts `\"true\"` and `\"false\"` to `true` and `false` respectively." do
        |parser2|
        parser2.instance_exec(self) do |_|
          _.ok {_convert_value("true")} == true
          _.ok {_convert_value("false")} == false
        end
      end

      spec "[!d64un] converts `\"[1,2,3]\"` to `[1,2,3]`." do
        |parser2|
        parser2.instance_exec(self) do |_|
          _.ok {_convert_value("[1,2,3]")} == [1,2,3]
        end
      end

      spec "[!6v2yu] converts `'{\"a\":1, \"b\":2}'` to `{\"a\"=>1, \"b\"=>2}`." do
        |parser2|
        parser2.instance_exec(self) do |_|
          _.ok {_convert_value('{"a":1, "b":2}')} == {"a"=>1, "b"=>2}
        end
      end

      spec "[!35cvp] returns the value as is if failed to convert it." do
        |parser2|
        parser2.instance_exec(self) do |_|
          _.ok {_convert_value("foo")} == "foo"
          _.ok {_convert_value("+123")} == "+123"
          _.ok {_convert_value("nil")} == "nil"
        end
      end

    end

  end


end
