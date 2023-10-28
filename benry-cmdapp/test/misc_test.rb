# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative 'shared'


Oktest.scope do


  topic Benry::CmdApp::BaseError do


    topic '#should_report_backtrace?()' do

      spec "[!oj9x3] returns true in base exception class to report backtrace." do
        exc = Benry::CmdApp::BaseError.new("")
        ok {exc.should_report_backtrace?()} == true
      end

    end


  end


  topic Benry::CmdApp::OptionError do


    topic '#should_report_backtrace?()' do

      spec "[!6qvnc] returns false in OptionError class because no need to report backtrace." do
        exc = Benry::CmdApp::OptionError.new("")
        ok {exc.should_report_backtrace?()} == false
      end

    end


  end


  topic Benry::CmdApp::CommandError do


    topic '#should_report_backtrace?()' do

      spec "[!o9xu2] returns false in ComamndError class because no need to report backtrace." do
        exc = Benry::CmdApp::CommandError.new("")
        ok {exc.should_report_backtrace?()} == false
      end

    end


  end


  topic Benry::CmdApp::ActionOptionSchema do


    topic '#initialize()' do

    end

  end


  topic Benry::CmdApp::OptionParser do


    topic '#parse()' do

      spec "[!iaawe] raises OptionError if option error found." do
        schema = Benry::CmdApp::ActionOptionSchema.new()
        schema.add(:help, "-h, --help", "help message")
        parser = Benry::CmdApp::OptionParser.new(schema)
        pr = proc { parser.parse(["-x", "foo"]) }
        ok {pr}.raise?(Benry::CmdApp::OptionError,
                       "-x: Unknown option.")
      end

    end

  end


end
