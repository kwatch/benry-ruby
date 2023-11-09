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


  topic Benry::CmdApp::OptionSet do

    before do
      @optset = Benry::CmdApp::OptionSet.new
      @schema = Benry::CmdApp::OptionSchema.new
      @schema.add(:user , "-u, --user=<user>"  , "user name")
      @schema.add(:email, "-e, --email=<email>", "email address")
      @schema.add(:port , "-p, --port=<number>", "port number", type: Integer)
    end


    topic '#copy_from()' do

      spec "[!d9udc] copy option items from schema." do
        items = []
        @schema.each {|item| items << item }
        #
        @optset.copy_from(@schema)
        new_items = @optset.instance_variable_get(:@items)
        ok {new_items}.length(3)
        ok {new_items[0]} == items[0]
        ok {new_items[1]} == items[1]
        ok {new_items[2]} == items[2]
      end

      spec "[!v1ok3] returns self." do
        ok {@optset.copy_from(@schema)}.same?(@optset)
      end

    end


    topic '#copy_into()' do

      spec "[!n00r1] copy option items into schema." do
        @optset.copy_from(@schema)
        new_schema = Benry::CmdApp::OptionSchema.new
        @optset.copy_into(new_schema)
        new_items = []
        new_schema.each {|item| new_items << item }
        items = @optset.instance_variable_get(:@items)
        ok {new_items}.length(3)
        ok {new_items[0]} == items[0]
        ok {new_items[1]} == items[1]
        ok {new_items[2]} == items[2]
      end

      spec "[!ynn1m] returns self." do
        @optset.copy_from(@schema)
        new_schema = Benry::CmdApp::OptionSchema.new
        ok {@optset.copy_into(new_schema)}.same?(@optset)
      end

    end


    topic '#select()' do

      spec "[!mqkzf] creates new OptionSet object with filtered options." do
        @optset.copy_from(@schema)
        newone = @optset.select(:user, :email)
        ok {newone}.is_a?(Benry::CmdApp::OptionSet)
        items = newone.instance_variable_get(:@items)
        ok {items}.length(2)
        ok {items.collect(&:key).sort} == [:email, :user]
      end

    end


    topic '#exclude()' do

      spec "[!oey0q] creates new OptionSet object with remained options." do
        @optset.copy_from(@schema)
        newone = @optset.exclude(:user, :email)
        ok {newone}.is_a?(Benry::CmdApp::OptionSet)
        items = newone.instance_variable_get(:@items)
        ok {items}.length(1)
        ok {items.collect(&:key).sort} == [:port]
      end

    end


  end


end
