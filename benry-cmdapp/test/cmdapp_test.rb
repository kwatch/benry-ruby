# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative "shared"


Oktest.scope do


  topic Benry::CmdApp do


    topic '.define_alias()' do

      spec "[!zawcd] action arg can be a string or an array of string." do
        pr = proc { Benry::CmdApp.define_alias("a4983-1", "hello") }
        ok {pr}.NOT.raise?(Exception)
        pr = proc { Benry::CmdApp.define_alias("a4983-2", ["hello", "-l", "it"]) }
        ok {pr}.NOT.raise?(Exception)
        md = Benry::CmdApp.define_alias("a4983-3", ["hello", "-l", "it"])
        ok {md.name}   == "a4983-3"
        ok {md.action} == "hello"
        ok {md.args}   == ["-l", "it"]
      end

      spec "[!hqc27] raises DefinitionError if something error exists in alias or action." do
        pr = proc { Benry::CmdApp.define_alias("hello2", "hello1") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q=define_alias("hello2", "hello1"): Action 'hello1' not found.=)
      end

      spec "[!oo91b] registers new metadata of alias." do
        metadata = Benry::CmdApp::INDEX.metadata_get("tmphello1")
        ok {metadata} == nil
        Benry::CmdApp.define_alias("tmphello1", "hello")
        metadata = Benry::CmdApp::INDEX.metadata_get("tmphello1")
        ok {metadata} != nil
        ok {metadata}.is_a?(Benry::CmdApp::AliasMetadata)
        ok {metadata.name} == "tmphello1"
        ok {metadata.action} == "hello"
        ok {metadata.args} == []
        #
        Benry::CmdApp.define_alias("tmphello2", ["hello", "aa", "bb", "cc"])
        metadata = Benry::CmdApp::INDEX.metadata_get("tmphello2")
        ok {metadata.args} == ["aa", "bb", "cc"]
      end

      spec "[!wfbqu] returns alias metadata." do
        ret = Benry::CmdApp.define_alias("tmphello3", "hello")
        ok {ret}.is_a?(Benry::CmdApp::AliasMetadata)
        ok {ret.name} == "tmphello3"
        ok {ret.action} == "hello"
      end

    end


    topic '.__validate_alias_and_action()' do

      spec "[!2x1ew] returns error message if alias name is not a string." do
        pr = proc { Benry::CmdApp.define_alias(:a4869, "hello") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|define_alias(:a4869, "hello"): Alias name should be a string, but got Symbol object.|)
      end

      spec "[!galce] returns error message if action name is not a string." do
        pr = proc { Benry::CmdApp.define_alias("a8680", :hello) }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|define_alias("a8680", :hello): Action name should be a string, but got Symbol object.|)
      end

      spec "[!zh0a9] returns error message if other alias already exists." do
        pr = proc { Benry::CmdApp.define_alias("tmphello4", "hello") }
        ok {pr}.NOT.raise?(Exception)
        pr = proc { Benry::CmdApp.define_alias("tmphello4", "hello") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|define_alias("tmphello4", "hello"): Alias 'tmphello4' already defined.|)
      end

      spec "[!ohow0] returns error message if other action exists with the same name as alias." do
        pr = proc { Benry::CmdApp.define_alias("testerr1", "hello") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|define_alias("testerr1", "hello"): Can't define new alias 'testerr1' because already defined as an action.|)
      end

      spec "[!r24qn] returns error message if action doesn't exist." do
        pr = proc { Benry::CmdApp.define_alias("tmphello6", "hello99") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|define_alias("tmphello6", "hello99"): Action 'hello99' not found.|)
      end

      spec "[!9phlr] returns no error message if other alias exists with the same name as action." do
        pr = proc { Benry::CmdApp.define_alias("tmphello6", "hello99") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|define_alias("tmphello6", "hello99"): Action 'hello99' not found.|)
      end

      spec "[!b6my2] returns nil if no errors found." do
        x = Benry::CmdApp.__validate_alias_and_action("tmphello7", "hello")
        ok {x} == nil
        #
        pr = proc { Benry::CmdApp.define_alias("tmphello7", "hello") }
        ok {pr}.NOT.raise?(Exception)
      end

    end


    topic '.undef_alias()' do

      spec "[!pk3ya] raises DefinitionError if alias name is not a string." do
        pr = proc { Benry::CmdApp.undef_alias(:hello) }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|`:hello`: Alias name should be a string, but got Symbol object.|)
      end

      spec "[!krdkt] raises DefinitionError if alias not exist." do
        pr = proc { Benry::CmdApp.undef_alias("tmphello8") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|undef_alias("tmphello8"): Alias not exist.|)
      end

      spec "[!juykx] raises DefinitionError if action specified instead of alias." do
        pr = proc { Benry::CmdApp.undef_alias("hello") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|undef_alias("hello"): Alias expected but action name specified.|)
      end

      spec "[!ocyso] deletes existing alias." do
        Benry::CmdApp.define_alias("tmphello9", "hello")
        Benry::CmdApp.undef_alias("tmphello9")
      end

    end


    topic '.undef_action()' do

      spec "[!bcyn3] raises DefinitionError if action name is not a string." do
        pr = proc { Benry::CmdApp.undef_action(:hello) }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "`:hello`: Action name should be a string, but got Symbol object.")
      end

      spec "[!bvu95] raises error if action not exist." do
        pr = proc { Benry::CmdApp.undef_action("hello99") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "undef_action(\"hello99\"): Action not exist.")
      end

      spec "[!717fw] raises error if alias specified instead of action." do
        Benry::CmdApp.define_alias("tmphello21", "hello")
        pr = proc { Benry::CmdApp.undef_action("tmphello21") }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "undef_action(\"tmphello21\"): Action expected but alias name specified.")
      end

      spec "[!01sx1] deletes existing action." do
        MyAction.class_eval do
          @action.("dummy")
          def dummy2049()
          end
        end
        ok {Benry::CmdApp::INDEX.metadata_get("dummy2049")} != nil
        Benry::CmdApp.undef_action("dummy2049")
        ok {Benry::CmdApp::INDEX.metadata_get("dummy2049")} == nil
      end

      spec "[!op8z5] deletes action method from action class." do
        MyAction.class_eval do
          @action.("dummy")
          def dummy4290()
          end
        end
        ok {MyAction.method_defined?(:dummy4290)} == true
        Benry::CmdApp.undef_action("dummy4290")
        ok {MyAction.method_defined?(:dummy4290)} == false
        #
        MyAction.class_eval do
          private
          prefix "p8902:" do
            @action.("dummy")
            def dummy9024()
            end
          end
        end
        ok {MyAction.private_method_defined?(:p8902__dummy9024)} == true
        Benry::CmdApp.undef_action("p8902:dummy9024")
        ok {MyAction.private_method_defined?(:p8902__dummy9024)} == false
      end

    end


    topic '.current_app()' do

      spec "[!xdjce] returns current application." do
        app = Benry::CmdApp::Application.new(Benry::CmdApp::Config.new(""))
        Benry::CmdApp._set_current_app(app)
        ok {Benry::CmdApp.current_app()}.same?(app)
      end

    end


    topic '._set_current_app()' do

      spec "[!1yqwl] sets current application." do
        app = Benry::CmdApp::Application.new(Benry::CmdApp::Config.new(""))
        Benry::CmdApp._set_current_app(app)
        ok {Benry::CmdApp.current_app()}.same?(app)
        Benry::CmdApp._set_current_app(nil)
        ok {Benry::CmdApp.current_app()} == nil
      end

    end


  end


end
