# -*- coding: utf-8 -*-
# frozen_string_literal: true

require 'oktest'

require 'benry/cmdopt'


Oktest.scope do


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


end
