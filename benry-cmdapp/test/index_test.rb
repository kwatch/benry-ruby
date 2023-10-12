# -*- coding: utf-8 -*-

require 'oktest'

require 'benry/cmdapp'
require_relative './shared'


Oktest.scope do


  topic Benry::CmdApp::ActionIndex do
    include CommonTestingHelper

    class IndexTestAction < Benry::CmdApp::ActionScope
      @action.("lookup test #1")
      @option.(:repeat, "-r <N>", "repeat", type: Integer)
      def lookup1(user="world", repeat: nil); end
      #
      @action.("lookup test #2")
      def lookup2(); end
      #
      private
      @action.("lookup test #3")   # hidden
      def lookup3(); end
    end

    Benry::CmdApp.action_alias("findxx", "lookup2")


    topic '.lookup_action()' do

      spec "[!vivoa] returns action metadata object." do
        x = Benry::CmdApp::INDEX.lookup_action("lookup1")
        ok {x} != nil
        ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
        ok {x.name} == "lookup1"
        ok {x.klass} == IndexTestAction
        ok {x.method} == :lookup1
      end

      spec "[!tnwq0] supports alias name." do
        x = Benry::CmdApp::INDEX.lookup_action("findxx")
        ok {x} != nil
        ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
        ok {x.name} == "lookup2"
        ok {x.klass} == IndexTestAction
        ok {x.method} == :lookup2
      end

      spec "[!z15vu] returns ActionWithArgs object if alias has args and/or kwargs." do
        Benry::CmdApp.action_alias("findyy1", "lookup1", "Alice", "-r3")
        x = Benry::CmdApp::INDEX.lookup_action("findyy1")
        ok {x} != nil
        ok {x}.is_a?(Benry::CmdApp::ActionWithArgs)
        ok {x.args} == ["Alice"]
        ok {x.kwargs} == {repeat: 3}
        ok {x.name} == "lookup1"
        ok {x.klass} == IndexTestAction
        ok {x.method} == :lookup1
      end

    end


    topic '.each_action_name_and_desc()' do

      before do
        clear_index_except(IndexTestAction)
      end

      after do
        restore_index()
      end

      spec "[!5lahm] yields action name, description, and important flag." do
        arr = []
        Benry::CmdApp::INDEX.each_action_name_and_desc(false) {|a| arr << a }
        ok {arr} == [
          ["lookup1", "lookup test #1", nil],
          ["lookup2", "lookup test #2", nil],
        ]
        #
        with_important("lookup1"=>true, "lookup2"=>false) do
          arr = []
          Benry::CmdApp::INDEX.each_action_name_and_desc(false) {|a| arr << a }
          ok {arr} == [
            ["lookup1", "lookup test #1", true],
            ["lookup2", "lookup test #2", false],
          ]
        end
      end

      spec "[!27j8b] includes alias names when the first arg is true." do
        arr = []
        Benry::CmdApp::INDEX.each_action_name_and_desc(true) {|a| arr << a }
        ok {arr} == [
          ["findxx", "alias of 'lookup2' action", nil],
          ["findyy1", "alias of 'lookup1 Alice -r3'", nil],
          ["lookup1", "lookup test #1", nil],
          ["lookup2", "lookup test #2", nil],
        ]
      end

      spec "[!8xt8s] rejects hidden actions if 'all: false' kwarg specified." do
        arr = []
        Benry::CmdApp::INDEX.each_action_name_and_desc(false, all: false) {|a| arr << a }
        ok {arr} == [
          ["lookup1", "lookup test #1", nil],
          ["lookup2", "lookup test #2", nil],
        ]
      end

      spec "[!5h7s5] includes hidden actions if 'all: true' kwarg specified." do
        arr = []
        Benry::CmdApp::INDEX.each_action_name_and_desc(false, all: true) {|a| arr << a }
        ok {arr} == [
          ["lookup1", "lookup test #1", nil],
          ["lookup2", "lookup test #2", nil],
          ["lookup3", "lookup test #3", false],   # hidden action
        ]
      end

      spec "[!arcia] action names are sorted." do
        arr = []
        Benry::CmdApp::INDEX.each_action_name_and_desc(true) {|a| arr << a }
        ok {arr} == arr.sort_by(&:first)
      end

    end


    topic '#delete_action()' do

      spec "[!08e1s] unregisters action." do
        class DeleteActionTest < Benry::CmdApp::ActionScope
          @action.("test")
          def delaction1(); end
        end
        name = "delaction1"
        ok {Benry::CmdApp::INDEX.action_exist?(name)} == true
        Benry::CmdApp::INDEX.delete_action(name)
        ok {Benry::CmdApp::INDEX.action_exist?(name)} == false
      end

      spec "[!zjpq0] raises error if action not registered." do
        name = "delaction99"
        ok {Benry::CmdApp::INDEX.action_exist?(name)} == false
        pr = proc { Benry::CmdApp::INDEX.delete_action(name) }
        ok {pr}.raise?(Benry::CmdApp::ActionNotFoundError,
                       "delete_action(\"delaction99\"): Action not found.")
      end

    end


    topic '#delete_alias()' do

      spec "[!8ls45] unregisters alias." do
        class DeleteAliasTest < Benry::CmdApp::ActionScope
          @action.("test")
          def delalias1(); end
        end
        Benry::CmdApp.action_alias("delali1", "delalias1")
        name = "delali1"
        ok {Benry::CmdApp::INDEX.alias_exist?(name)} == true
        Benry::CmdApp::INDEX.delete_alias(name)
        ok {Benry::CmdApp::INDEX.alias_exist?(name)} == false
      end

      spec "[!fdfyq] raises error if alias not registered." do
        name = "delalias99"
        ok {Benry::CmdApp::INDEX.alias_exist?(name)} == false
        pr = proc { Benry::CmdApp::INDEX.delete_alias(name) }
        ok {pr}.raise?(Benry::CmdApp::ActionNotFoundError,
                       "delete_alias(\"delalias99\"): Alias not found.")
      end

    end


  end


end
