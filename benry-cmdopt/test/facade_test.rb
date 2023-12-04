# -*- coding: utf-8 -*-
# frozen_string_literal: true

require_relative './shared'


Oktest.scope do


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
