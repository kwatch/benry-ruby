# -*- coding: utf-8 -*-

require 'oktest'

require 'benry/cmdapp'
require_relative './shared'


Oktest.scope do


  topic Benry::CmdApp do


    topic '.delete_action()' do

      spec "[!era7d] deletes action." do
        class DeleteAction2Test < Benry::CmdApp::Action
          @action.("test")
          def delaction2(); end
        end
        #
        pr = proc {
          class DeleteAction2Test
            @action.("test")
            def delaction2(); end
          end
        }
        ok {pr}.raise?(Benry::CmdApp::ActionDefError,
                       "def delaction2(): Action 'delaction2' already exist.")
        #
        Benry::CmdApp.delete_action("delaction2")
        ok {pr}.NOT.raise?(Exception)
      end

      spec "[!ifaj1] raises error if action not exist." do
        pr = proc { Benry::CmdApp.delete_action("delaction91") }
        ok {pr}.raise?(Benry::CmdApp::ActionNotFoundError,
                      "delete_action(\"delaction91\"): Action not found.")
      end

    end


    topic '.delete_alias()' do

      spec "[!9g0x9] deletes alias." do
        class DeleteAlias2Test < Benry::CmdApp::Action
          @action.("test")
          def delalias2(); end
        end
        Benry::CmdApp.action_alias("delali2", "delalias2")
        #
        pr = proc {
          Benry::CmdApp.action_alias("delali2", "delalias2")
        }
        ok {pr}.raise?(Benry::CmdApp::AliasDefError,
                       "action_alias(\"delali2\", \"delalias2\"): Alias name duplicated.")
        #
        Benry::CmdApp.delete_alias("delali2")
        ok {pr}.NOT.raise?(Exception)
      end

      spec "[!r49vi] raises error if alias not exist." do
        pr = proc { Benry::CmdApp.delete_alias("delalias91") }
        ok {pr}.raise?(Benry::CmdApp::ActionNotFoundError,
                      "delete_alias(\"delalias91\"): Alias not found.")
      end

    end


    topic '.action_alias()' do

      class Alias1Test < Benry::CmdApp::Action
        prefix "alias1"
        @action.("alias test")
        def a1(); end
        @action.("alias test")
        def a2(); end
      end

      spec "[!vzlrb] registers alias name with action name." do
        Benry::CmdApp.action_alias("a4", "alias1:a1")
        ok {Benry::CmdApp::INDEX.alias_exist?("a4")} == true
        ok {Benry::CmdApp::INDEX.get_alias("a4").alias_name} == "a4"
        ok {Benry::CmdApp::INDEX.get_alias("a4").action_name} == "alias1:a1"
      end

      spec "[!0cq6o] supports args." do
        Benry::CmdApp.action_alias("a8", "alias1:a1", "Alice", "-l", "it")
        ok {Benry::CmdApp::INDEX.alias_exist?("a8")} == true
        ok {Benry::CmdApp::INDEX.get_alias("a8").alias_name} == "a8"
        ok {Benry::CmdApp::INDEX.get_alias("a8").action_name} == "alias1:a1"
        ok {Benry::CmdApp::INDEX.get_alias("a8").args} == ["Alice", "-l", "it"]
      end

      spec "[!4wtxj] supports 'tag:' keyword arg." do
        Benry::CmdApp.action_alias("a7", "alias1:a1", tag: :important)
        ok {Benry::CmdApp::INDEX.alias_exist?("a7")} == true
        ok {Benry::CmdApp::INDEX.get_alias("a7").action_name} == "alias1:a1"
        ok {Benry::CmdApp::INDEX.get_alias("a7").tag} == :important
      end

      spec "[!5immb] convers both alias name and action name into string." do
        Benry::CmdApp.action_alias(:a5, :'alias1:a2')
        ok {Benry::CmdApp::INDEX.alias_exist?("a5")} == true
        ok {Benry::CmdApp::INDEX.get_alias("a5").alias_name} == "a5"
        ok {Benry::CmdApp::INDEX.get_alias("a5").action_name} == "alias1:a2"
      end

      spec "[!nrz3d] error if action not found." do
        pr = proc { Benry::CmdApp.action_alias(:a5, :'alias1:a5') }
        ok {pr}.raise?(Benry::CmdApp::AliasDefError,
                       "action_alias(:a5, :\"alias1:a5\"): Action not found.")
      end

      spec "[!vvmwd] error when action with same name as alias exists." do
        pr = proc { Benry::CmdApp.action_alias(:'alias1:a2', :'alias1:a1') }
        ok {pr}.raise?(Benry::CmdApp::AliasDefError,
                       "action_alias(:\"alias1:a2\", :\"alias1:a1\"): Not allowed to define same name alias as existing action.")
      end

      spec "[!i9726] error if alias already defined." do
        pr1 = proc { Benry::CmdApp.action_alias(:'a6', :'alias1:a1') }
        pr2 = proc { Benry::CmdApp.action_alias(:'a6', :'alias1:a2') }
        ok {pr1}.NOT.raise?(Exception)
        ok {pr2}.raise?(Benry::CmdApp::AliasDefError,
                        "action_alias(:a6, :\"alias1:a2\"): Alias name duplicated.")
      end

    end

  end


end
