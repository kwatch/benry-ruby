# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative 'shared'


class UtilTestObject
  def foo0(aa, bb, cc=0, dd=nil, *rest, xx: nil, yy: nil); end
  def foo1(x); end
  def foo2(x=0); end
  def foo3(*x); end
  def foo4(x, y=0, *z); end
  def foo5(x: 0, y: nil); end
end


Oktest.scope do


  topic Benry::CmdApp::Util do


    topic '.#method2action()' do

      spec "[!bt77a] converts method name (Symbol) to action name (String)." do
        ok {Benry::CmdApp::Util.method2action(:foo)} == "foo"
      end

      spec "[!o5822] converts `:foo_` into `'foo'`." do
        ok {Benry::CmdApp::Util.method2action(:foo_)} == "foo"
      end

      spec "[!msgjc] converts `:aa__bb____cc` into `'aa:bb:cc'`." do
        ok {Benry::CmdApp::Util.method2action(:aa__bb__cc)}     == "aa:bb:cc"
        ok {Benry::CmdApp::Util.method2action(:aa____bb____cc)} == "aa:bb:cc"
        ok {Benry::CmdApp::Util.method2action(:aa__bb____cc)}   == "aa:bb:cc"
      end

      spec "[!qmkfv] converts `:aa_bb_cc` into `'aa-bb-cc'`." do
        ok {Benry::CmdApp::Util.method2action(:aa__bb__cc)} == "aa:bb:cc"
      end

      spec "[!tvczb] converts `:_aa_bb:_cc_dd:_ee` into `'_aa-bb:_cc-dd:_ee'`." do
        ok {Benry::CmdApp::Util.method2action("_aa_bb:_cc_dd:_ee")} == "_aa-bb:_cc-dd:_ee"
      end

    end


    topic '.#method2help()' do

      before do
        @obj = UtilTestObject.new
      end

      spec "[!q3y3a] returns command argument string which represents method parameters." do
        ok {Benry::CmdApp::Util.method2help(@obj, :foo0)} == " <aa> <bb> [<cc> [<dd> [<rest>...]]]"
      end

      spec "[!r6u58] converts `.foo(x)` into `' <x>'`." do
        ok {Benry::CmdApp::Util.method2help(@obj, :foo1)} == " <x>"
      end

      spec "[!r6u58] converts `.foo(x=0)` into `' [<x>]'`." do
        ok {Benry::CmdApp::Util.method2help(@obj, :foo2)} == " [<x>]"
      end

      spec "[!r6u58] converts `.foo(*x)` into `' [<x>...]'`." do
        ok {Benry::CmdApp::Util.method2help(@obj, :foo3)} == " [<x>...]"
      end

      spec "[!61xy6] converts `.foo(x, y=0, *z)` into `' <x> [<y> [<z>...]]'`." do
        ok {Benry::CmdApp::Util.method2help(@obj, :foo4)} == " <x> [<y> [<z>...]]"
      end

      spec "[!0342t] ignores keyword parameters." do
        ok {Benry::CmdApp::Util.method2help(@obj, :foo5)} == ""
      end

    end


    topic '.#param2arg()' do

      spec "[!ahvsn] converts parameter name (Symbol) into argument name (String)." do
        ok {Benry::CmdApp::Util.param2arg(:foo)} == "foo"
      end

      spec "[!27dpw] converts `:aa_or_bb_or_cc` into `'aa|bb|cc'`." do
        ok {Benry::CmdApp::Util.param2arg(:aa_or_bb_or_cc)} == "aa|bb|cc"
      end

      spec "[!to41h] converts `:aa__bb__cc` into `'aa.bb.cc'`." do
        ok {Benry::CmdApp::Util.param2arg(:aa__bb__cc)} == "aa.bb.cc"
      end

      spec "[!2ma08] converts `:aa_bb_cc` into `'aa-bb-cc'`." do
        ok {Benry::CmdApp::Util.param2arg(:aa_bb_cc)} == "aa-bb-cc"
      end

    end


    topic '.#validate_args_and_kwargs()' do

      spec "[!jalnr] returns error message if argument required but no args specified." do
        def g1(x); end
        errmsg = Benry::CmdApp::Util.validate_args_and_kwargs(self, :g1, [], {})
        ok {errmsg} == "Argument required (but nothing specified)."
      end

      spec "[!gv6ow] returns error message if too less arguments." do
        def g2(x, y); end
        errmsg = Benry::CmdApp::Util.validate_args_and_kwargs(self, :g2, ["A"], {})
        ok {errmsg} == "Too less arguments (at least 2 args)."
      end

      spec "[!q5rp3] returns error message if argument specified but no args expected." do
        def g3(); end
        errmsg = Benry::CmdApp::Util.validate_args_and_kwargs(self, :g3, ["A"], {})
        ok {errmsg} == %q|"A": Unexpected argument (expected no args).|
      end

      spec "[!dewkt] returns error message if too much arguments specified." do
        def g4(x); end
        errmsg = Benry::CmdApp::Util.validate_args_and_kwargs(self, :g4, ["A", "B"], {})
        ok {errmsg} == "Too much arguments (at most 1 args)."
      end

      spec "[!u7wgm] returns error message if unknown keyword argument specified." do
        def g5(x: 0); end
        errmsg = Benry::CmdApp::Util.validate_args_and_kwargs(self, :g5, [], {y: "abc"})
        ok {errmsg} == "y: Unknown keyword argument."
      end

      spec "[!2ep76] returns nil if no error found." do
        def g6(x, y=nil, z: 0); end
        errmsg = Benry::CmdApp::Util.validate_args_and_kwargs(self, :g6, ["A", "B"], {z: "abc"})
        ok {errmsg} == nil
      end

    end


    topic '.#delete_escape_chars()' do

      spec "[!snl3e] removes escape chars from string." do
        s = "\e[1;34mUsage:\e[0m (default: help)"
        x = Benry::CmdApp::Util.delete_escape_chars(s)
        ok {x} == "Usage: (default: help)"
      end

    end


    topic '.#color_mode?()' do

      spec "[!xyta1] returns value of $COLOR_MODE if it is not nil." do
        bkup = $COLOR_MODE
        at_end { $COLOR_MODE = bkup }
        #
        $COLOR_MODE = true
        ok {Benry::CmdApp::Util.color_mode?} == true
        $COLOR_MODE = false
        ok {Benry::CmdApp::Util.color_mode?} == false
      end

      spec "[!8xufh] returns value of $stdout.tty? if $COLOR_MODE is nil." do
        bkup = $COLOR_MODE
        at_end { $COLOR_MODE = bkup }
        #
        $COLOR_MODE = nil
        x = nil
        capture_sio(tty: true) { x = Benry::CmdApp::Util.color_mode? }
        ok {x} == true
        capture_sio(tty: false) { x = Benry::CmdApp::Util.color_mode? }
        ok {x} == false
      end

    end


    topic '.#method_override?()' do

      class DummyA
        def f1(); end
      end
      module DummyB
        def f2(); end
      end
      class DummyC < DummyA
        include DummyB
        def f3(); end
      end

      spec "[!ldd1x] returns true if method defined in parent or ancestor classes." do
        ok {Benry::CmdApp::Util.method_override?(DummyC, :f1)} == true
        ok {Benry::CmdApp::Util.method_override?(DummyC, :f2)} == true
        ok {Benry::CmdApp::Util.method_override?(DummyC, :print)} == true
      end

      spec "[!bc65v] returns false if meethod not defined in parent nor ancestor classes." do
        ok {Benry::CmdApp::Util.method_override?(DummyC, :f3)} == false
        ok {Benry::CmdApp::Util.method_override?(DummyC, :hoge)} == false
      end

    end


    topic '.#name_should_be_a_string()' do

      spec "[!9j4d0] do nothing if name is a string." do
        x = Benry::CmdApp::Util.name_should_be_a_string("hello", "Action", Benry::CmdApp::DefinitionError)
        ok {x} == nil
      end

      spec "[!a2n8y] raises error if name is not a string." do
        pr = proc { Benry::CmdApp::Util.name_should_be_a_string(:hello, "Action", Benry::CmdApp::DefinitionError) }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "`:hello`: Action name should be a string, but got Symbol object.")
      end

    end


  end


end
