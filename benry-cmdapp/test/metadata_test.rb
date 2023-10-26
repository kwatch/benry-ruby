# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative 'shared'


Oktest.scope do


  topic Benry::CmdApp::BaseMetadata do

  end


  topic Benry::CmdApp::ActionMetadata do

    topic '#hidden?()' do

      spec "[!stied] returns true/false if `hidden:` kwarg provided." do
        args = ["hello", "Hello", nil, MyAction, :hello]
        md = Benry::CmdApp::ActionMetadata.new(*args, hidden: true)
        ok {md.hidden?} == true
        md = Benry::CmdApp::ActionMetadata.new(*args, hidden: false)
        ok {md.hidden?} == false
      end

      spec "[!eumhz] returns true/false if method is private or not." do
        args = ["hello", "Hello", nil, MyAction, :hello]
        md = Benry::CmdApp::ActionMetadata.new(*args)
        ok {md.hidden?} == false
        MyAction.class_eval { private :hello }
        at_end { MyAction.class_eval { public :hello } }
        ok {md.hidden?} == true
      end

    end


    topic '#option_empty?()' do

      spec "[!14xgg] returns true if the action has no options." do
        schema = Benry::CmdApp::OPTION_SCHEMA_CLASS.new
        args = ["hello", "Hello", schema, MyAction, :hello]
        md = Benry::CmdApp::ActionMetadata.new(*args)
        ok {md.option_empty?} == true
      end

      spec "[!dbtht] returns false if the action has at least one option." do
        schema = Benry::CmdApp::OPTION_SCHEMA_CLASS.new
        schema.add(:verbose, "-v", "verbose")
        args = ["hello", "Hello", schema, MyAction, :hello]
        md = Benry::CmdApp::ActionMetadata.new(*args)
        ok {md.option_empty?} == false
      end

      spec "[!wa315] considers hidden options if `all: true` passed." do
        schema = Benry::CmdApp::OPTION_SCHEMA_CLASS.new
        schema.add(:debug, "-D", "debug", hidden: true)
        args = ["hello", "Hello", schema, MyAction, :hello]
        md = Benry::CmdApp::ActionMetadata.new(*args)
        ok {md.option_empty?(all: false)} == true
        ok {md.option_empty?(all: true)} == false
      end

    end


    topic '#option_help()' do

      before do
        schema = Benry::CmdApp::OPTION_SCHEMA_CLASS.new
        schema.add(:lang, "-l <lang>", "language")
        schema.add(:color, "--color[=<on|off>]", "color mode", type: TrueClass)
        schema.add(:debug, "--debug", "debug mode", hidden: true)
        args = ["hello", "Hello", schema, MyAction, :hello]
        @metadata = Benry::CmdApp::ActionMetadata.new(*args)
      end

      spec "[!bpkwn] returns help message string of the action." do
        ok {@metadata.option_help("  %-15s : %s")} == <<"END"
  -l <lang>       : language
  --color[=<on|off>] : color mode
END
      end

      spec "[!76hni] includes hidden options in help message if `all:` is truthy." do
        ok {@metadata.option_help("  %-15s : %s", all: true)} == <<"END"
  -l <lang>       : language
  --color[=<on|off>] : color mode
  --debug         : debug mode
END
      end

    end


    topic '#parse_options()' do

      before do
        schema = Benry::CmdApp::OPTION_SCHEMA_CLASS.new
        schema.add(:lang, "-l <lang>", "language")
        schema.add(:color, "--color[=<on|off>]", "color mode", type: TrueClass)
        schema.add(:debug, "--debug", "debug mode", hidden: true)
        args = ["hello", "Hello", schema, MyAction, :hello]
        @metadata = Benry::CmdApp::ActionMetadata.new(*args)
      end

      spec "[!gilca] returns parsed options." do
        args = ["-len", "--color=on", "Alice"]
        opts = @metadata.parse_options(args)
        ok {opts} == {:lang=>"en", :color=>true}
        ok {args} == ["Alice"]
      end

      spec "[!v34yk] raises OptionError if option has error." do
        args = ["--lang=en", "--color=on", "Alice"]
        pr = proc { @metadata.parse_options(args) }
        ok {pr}.raise?(Benry::CmdApp::OptionError,
                       "--lang=en: Unknown long option.")
      end

    end


    topic '#alias?()' do

      spec "[!c1eq3] returns false which means that this is not an alias metadata." do
        schema = Benry::CmdApp::OPTION_SCHEMA_CLASS.new
        args = ["hello", "Hello", schema, MyAction, :hello]
        metadata = Benry::CmdApp::ActionMetadata.new(*args)
        ok {metadata.alias?} == false
      end

    end


  end


  topic Benry::CmdApp::AliasMetadata do


    topic '#initialize()' do

      spec "[!qtb61] sets description string automatically." do
        metadata = Benry::CmdApp::AliasMetadata.new("a9344", "hello", nil)
        ok {metadata.desc} == "alias of 'hello'"
      end

      spec "[!kgic6] includes args value into description if provided." do
        metadata = Benry::CmdApp::AliasMetadata.new("a1312", "hello", ["aa", "bb"])
        ok {metadata.desc} == "alias of 'hello aa bb'"
      end

    end


    topic '#alias?()' do

      spec "[!c798o] returns true which means that this is an alias metadata." do
        metadata = Benry::CmdApp::AliasMetadata.new("a2041", "hello", nil)
        ok {metadata.alias?} == true
      end

    end


  end


end
