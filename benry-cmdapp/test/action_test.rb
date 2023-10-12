# -*- coding: utf-8 -*-


require 'oktest'

require 'benry/cmdapp'
require_relative './shared'


Oktest.scope do


  topic Benry::CmdApp::ActionMetadata do
    #include CommonTestingHelper         # not work. why?
    include ActionMetadataTestingHelper

    class MetadataTestAction < Benry::CmdApp::ActionScope

      @action.("print greeting message")
      @option.(:lang, "-l, --lang=<en|fr|it>", "language")
      def halo1(user="world", lang: "en")
        case lang
        when "en" ;  puts "Hello, #{user}!"
        when "fr" ;  puts "Bonjour, #{user}!"
        when "it" ;  puts "Ciao, #{user}!"
        else      ;  raise "#{lang}: unknown language."
        end
      end

      @action.("print greeting message")
      @option.(:lang, "-l, --lang=<en|fr|it>", "language")
      def halo2(user="world", *users, lang: "en")
        puts "user=#{user.inspect}, users=#{users.inspect}"
      end

      @action.("no arguments")
      @option.(:lang, "-l, --lang=<en|fr|it>", "language")
      def halo3(lang: "en")
        puts "lang=#{lang}"
      end

      def args1(aa, bb, xx: nil); end                   # required arg
      def args2(aa, bb=nil, cc=nil, xx: nil); end       # optional arg
      def args3(aa, bb=nil, cc=nil, *dd, xx: nil); end  # variable arg
      def args4(xx_or_yy_or_zz); end                    # xx|yy|zz
      def args5(_xx_yy_zz); end                         # _xx-yy-zz

    end


    before do
      schema = Benry::Cmdopt::Schema.new
      schema.add(:lang, "-l, --lang=<en|fr|it>", "language")
      @metadata = Benry::CmdApp::ActionMetadata.new("halo1", MetadataTestAction, :halo1, "greeting", schema)
    end


    topic '#hidden?()' do

      class HiddenTestAction < Benry::CmdApp::ActionScope
        @action.("public")
        def pphidden1(); puts __method__(); end
        #
        @action.("private")
        def pphidden2(); puts __method__(); end
        private :pphidden2
        #
        private
        @action.("private")
        def pphidden3(); puts __method__(); end
      end

      spec "[!kp10p] returns true when action method is private." do
        ameta = Benry::CmdApp::INDEX.get_action("pphidden3")
        ok {ameta.hidden?} == true
        ameta = Benry::CmdApp::INDEX.get_action("pphidden2")
        ok {ameta.hidden?} == true
      end

      spec "[!nw322] returns false when action method is not private." do
        ameta = Benry::CmdApp::INDEX.get_action("pphidden1")
        ok {ameta.hidden?} == false
      end

    end


    topic '#importance?()' do

      spec "[!52znh] returns true if `@important == true`." do
        ameta = @metadata
        ameta.instance_variable_set('@important', true)
        ok {ameta.important?} == true
      end

      spec "[!rlfac] returns false if `@important == false`." do
        ameta = @metadata
        ameta.instance_variable_set('@important', false)
        ok {ameta.important?} == false
      end

      spec "[!j3trl] returns false if `@important == nil`. and action is hidden." do
        ameta = @metadata
        def ameta.hidden?; true; end
        ok {ameta.important?} == false
      end

      spec "[!hhef8] returns nil if `@important == nil`." do
        ameta = @metadata
        ameta.instance_variable_set('@important', nil)
        ok {ameta.important?} == nil
      end

    end


    topic '#parse_options()' do

      spec "[!ab3j8] parses argv and returns options." do
        args = ["-l", "fr", "Alice"]
        opts = @metadata.parse_options(args)
        ok {opts} == {:lang => "fr"}
        ok {args} == ["Alice"]
        args = ["--lang=it", "Bob"]
        opts = @metadata.parse_options(args)
        ok {opts} == {:lang => "it"}
        ok {args} == ["Bob"]
      end

      spec "[!56da8] raises InvalidOptionError if option value is invalid." do
        args = ["-x", "fr", "Alice"]
        pr = proc { @metadata.parse_options(args) }
        ok {pr}.raise?(Benry::CmdApp::InvalidOptionError, "-x: Unknown option.")
      end

    end


    topic '#run_action()' do

      spec "[!veass] runs action with args and kwargs." do
        args = ["Alice"]; kwargs = {lang: "fr"}
        #
        sout, serr = capture_sio { @metadata.run_action() }
        ok {sout} == "Hello, world!\n"
        ok {serr} == ""
        #
        sout, serr = capture_sio { @metadata.run_action(*args) }
        ok {sout} == "Hello, Alice!\n"
        ok {serr} == ""
        #
        sout, serr = capture_sio { @metadata.run_action(**kwargs) }
        ok {sout} == "Bonjour, world!\n"
        ok {serr} == ""
        #
        sout, serr = capture_sio { @metadata.run_action(*args, **kwargs) }
        ok {sout} == "Bonjour, Alice!\n"
        ok {serr} == ""
      end

      def _trace_mode(flag, &block)
        bkup = $TRACE_MODE
        $TRACE_MODE = true
        begin
          return yield
        ensure
          $TRACE_MODE = bkup
        end
      end

      spec "[!tubhv] if $TRACE_MODE is on, prints tracing info." do
        args = ["Alice"]; kwargs = {lang: "it"}
        sout, serr = _trace_mode(true) do
          capture_sio {
            @metadata.run_action(*args, **kwargs)
          }
        end
        ok {serr} == ""
        ok {sout} == <<"END"
## enter: halo1
Ciao, Alice!
## exit:  halo1
END
      end

      spec "[!zgp14] tracing info is colored when stdout is a tty." do
        args = ["Alice"]; kwargs = {lang: "it"}
        sout, serr = _trace_mode(true) do
          capture_sio(tty: true) {
            @metadata.run_action(*args, **kwargs)
          }
        end
        ok {serr} == ""
        ok {sout} == <<"END"
\e[33m## enter: halo1\e[0m
Ciao, Alice!
\e[33m## exit:  halo1\e[0m
END
      end

    end


    topic '#method_arity()' do

      spec "[!7v4tp] returns min and max number of positional arguments." do
        ok {@metadata.method_arity()} == [0, 1]
      end

      spec "[!w3rer] max is nil if variable argument exists." do
        schema = Benry::Cmdopt::Schema.new
        metadata = Benry::CmdApp::ActionMetadata.new("halo2", MetadataTestAction, :halo2, "greeting", schema)
        ok {metadata.method_arity()} == [0, nil]
      end

    end


    topic '#validate_method_params()' do

      spec "[!plkhs] returns error message if keyword parameter for option not exist." do
        schema = Benry::Cmdopt::Schema.new
        schema.add(:foo, "--foo", "foo")
        metadata = Benry::CmdApp::ActionMetadata.new("halo1", MetadataTestAction, :halo1, "greeting", schema)
        msg = metadata.validate_method_params()
        ok {msg} == "Should have keyword parameter 'foo' for '@option.(:foo)', but not."
      end

      spec "[!1koi8] returns nil if all keyword parameters for option exist." do
        schema = Benry::Cmdopt::Schema.new
        schema.add(:lang, "-l, --lang=<lang>", "lang")
        metadata = Benry::CmdApp::ActionMetadata.new("halo1", MetadataTestAction, :halo1, "greeting", schema)
        msg = metadata.validate_method_params()
        ok {msg} == nil
      end

    end


    topic '#help_message()' do

      spec "[!i7siu] returns help message of action." do
        schema = new_schema()
        msg = without_tty { new_metadata(schema).help_message("testapp") }
        ok {uncolorize(msg)} == <<END
testapp halo1 -- greeting

Usage:
  $ testapp halo1 [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
END
      end

    end


  end


  topic Benry::CmdApp::ActionWithArgs do
    include ActionMetadataTestingHelper


    topic '#initialize()' do

      spec "[!6jklb] keeps ActionMetadata, args, and kwargs." do
        ameta = new_metadata(new_schema())
        wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, ["Alice"], {lang: "fr"})
        ok {wrapper.action_metadata} == ameta
        ok {wrapper.args}   == ["Alice"]
        ok {wrapper.kwargs} == {lang: "fr"}
      end

    end


    topic '#method_missing()' do

      spec "[!14li3] behaves as ActionMetadata." do
        ameta = new_metadata(new_schema())
        wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, ["Alice"], {lang: "fr"})
        ok {wrapper.name} == ameta.name
        ok {wrapper.klass} == ameta.klass
        ok {wrapper.schema} == ameta.schema
        ok {wrapper.method_arity()} == ameta.method_arity()
      end

    end


    topic '#run_action()' do

      class ActionWithArgsTest < Benry::CmdApp::ActionScope
        @action.("hello")
        @option.(:lang, "-l <lang>", "language")
        @option.(:repeat, "-r <N>", "repeat <N> times")
        def hellowithargs(user1="alice", user2="bob", lang: nil, repeat: nil)
          puts "user1=#{user1}, user2=#{user2}, lang=#{lang.inspect}, repeat=#{repeat.inspect}"
        end
      end

      spec "[!fl26i] invokes action with args and kwargs." do
        ameta = Benry::CmdApp::INDEX.get_action("hellowithargs")
        #
        wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, ["bill"], {repeat: 3})
        sout, serr = capture_sio() { wrapper.run_action() }
        ok {serr} == ""
        ok {sout} == "user1=bill, user2=bob, lang=nil, repeat=3\n"
        #
        wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, ["bill"], nil)
        sout, serr = capture_sio() { wrapper.run_action() }
        ok {serr} == ""
        ok {sout} == "user1=bill, user2=bob, lang=nil, repeat=nil\n"
        #
        wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, nil, {repeat: 3})
        sout, serr = capture_sio() { wrapper.run_action() }
        ok {serr} == ""
        ok {sout} == "user1=alice, user2=bob, lang=nil, repeat=3\n"
      end

    end


  end


  topic Benry::CmdApp::ActionScope do


    class InvokeTestAction < Benry::CmdApp::ActionScope
      prefix "test3:foo"
      #
      @action.("invoke once")
      @option.(:lang, "-l, --lang=<en|fr>", "language")
      def invoke1(user="world", lang: "en")
        puts(lang == "fr" ? "Bonjour, #{user}!" : "Hello, #{user}!")
      end
      #
      @action.("invoke twice")
      @option.(:lang, "-l, --lang=<en|fr>", "language")
      def invoke2(user="world", lang: "en")
        puts(lang == "fr" ? "Bonjour, #{user}!" : "Hello, #{user}!")
      end
      #
      @action.("invoke more")
      @option.(:lang, "-l, --lang=<en|fr>", "language")
      def invoke3(user="world", lang: "en")
        puts(lang == "fr" ? "Bonjour, #{user}!" : "Hello, #{user}!")
      end
    end

    class LoopedActionTest < Benry::CmdApp::ActionScope
      @action.("test")
      def loop1()
        run_action_once("loop2")
      end
      @action.("test")
      def loop2()
        run_action_once("loop3")
      end
      @action.("test")
      def loop3()
        run_action_once("loop1")
      end
    end

    before do
      @action = InvokeTestAction.new()
      Benry::CmdApp::INDEX.instance_variable_get('@done').clear()
    end


    topic '#run_action_once()' do

      spec "[!oh8dc] don't invoke action if already invoked." do
        sout, serr = capture_sio() do
          @action.run_action_once("test3:foo:invoke2", "Alice", lang: "fr")
        end
        ok {sout} == "Bonjour, Alice!\n"
        sout, serr = capture_sio() do
          @action.run_action_once("test3:foo:invoke2", "Alice", lang: "fr")
        end
        ok {sout} == ""
        ok {serr} == ""
      end

    end


    topic '#run_action!()' do

      spec "[!2yrc2] invokes action even if already invoked." do
        sout, serr = capture_sio() do
          @action.run_action!("test3:foo:invoke3", "Alice", lang: "fr")
        end
        ok {sout} == "Bonjour, Alice!\n"
        sout, serr = capture_sio() do
          @action.run_action!("test3:foo:invoke3", "Alice", lang: "fr")
        end
        ok {sout} == "Bonjour, Alice!\n"
        sout, serr = capture_sio() do
          @action.run_action!("test3:foo:invoke3", "Alice", lang: "en")
        end
        ok {sout} == "Hello, Alice!\n"
      end

    end


    topic '#__run_action()' do

      def __run_action(action_name, once, args, kwargs)
        @action.__send__(:__run_action, action_name, once, args, kwargs)
      end

      def __run_loop(action_name, once, args, kwargs)
        action = LoopedActionTest.new()
        action.__send__(:__run_action, action_name, once, args, kwargs)
      end

      spec "[!lbp9r] invokes action name with prefix if prefix defined." do
        sout, serr = capture_sio() do
          @action.run_action_once("invoke2", "Alice", lang: "fr")
        end
        ok {sout} == "Bonjour, Alice!\n"
      end

      spec "[!7vszf] raises error if action specified not found." do
        pr = proc { __run_action("loop9", nil, ["Alice"], {}) }
        ok {pr}.raise?(Benry::CmdApp::ActionNotFoundError, "loop9: Action not found.")
      end

      spec "[!u8mit] raises error if action flow is looped." do
        pr = proc { __run_loop("loop1", nil, [], {}) }
        ok {pr}.raise?(Benry::CmdApp::LoopedActionError, "loop1: Action loop detected.")
      end

      spec "[!vhdo9] don't invoke action twice if 'once' arg is true." do
        sout, serr = capture_sio() do
          __run_action("test3:foo:invoke2", true, ["Alice"], {lang: "fr"})
        end
        ok {sout} == "Bonjour, Alice!\n"
        sout, serr = capture_sio() do
          __run_action("test3:foo:invoke2", true, ["Alice"], {lang: "fr"})
        end
        ok {sout} == ""
        ok {serr} == ""
      end

      spec "[!r8fbn] invokes action." do
        sout, serr = capture_sio() do
          __run_action("test3:foo:invoke1", false, ["Alice"], {lang: "fr"})
        end
        ok {sout} == "Bonjour, Alice!\n"
      end

    end


    topic '.prefix()' do

      spec "[!1gwyv] converts symbol into string." do
        class PrefixTest1 < Benry::CmdApp::ActionScope
          prefix :foo
        end
        prefix = PrefixTest1.instance_variable_get('@__prefix__')
        ok {prefix} == "foo:"
      end

      spec "[!pz46w] error if prefix contains extra '_'." do
        pr = proc do
          class PrefixTest2 < Benry::CmdApp::ActionScope
            prefix "foo_bar"
          end
        end
        ok {pr}.raise?(Benry::CmdApp::ActionDefError,
                       "foo_bar: Invalid prefix name (please use ':' or '-' instead of '_' as word separator).")
      end

      spec "[!9pu01] adds ':' at end of prefix name if prefix not end with ':'." do
        class PrefixTest3 < Benry::CmdApp::ActionScope
          prefix "foo:bar"
        end
        prefix = PrefixTest3.instance_variable_get('@__prefix__')
        ok {prefix} == "foo:bar:"
      end

    end


    topic '.inherited()' do

      spec "[!f826w] registers all subclasses into 'ActionScope::SUBCLASSES'." do
        class InheritedTest0a < Benry::CmdApp::ActionScope
        end
        class InheritedTest0b < Benry::CmdApp::ActionScope
        end
        ok {Benry::CmdApp::ActionScope::SUBCLASSES}.include?(InheritedTest0a)
        ok {Benry::CmdApp::ActionScope::SUBCLASSES}.include?(InheritedTest0b)
      end

      spec "[!2imrb] sets class instance variables in subclass." do
        class InheritedTest1 < Benry::CmdApp::ActionScope
        end
        ivars = InheritedTest1.instance_variables().sort()
        ok {ivars} == [:@__action__, :@__aliasof__, :@__default__, :@__option__, :@__prefix__, :@action, :@copy_options, :@option]
      end

      spec "[!1qv12] @action is a Proc object and saves args." do
        class InheritedTest2 < Benry::CmdApp::ActionScope
          @action.("description", detail: "xxx", postamble: "yyy", important: true, tag: "zzz")
        end
        x = InheritedTest2.instance_variable_get('@__action__')
        ok {x} == ["description", {detail: "xxx", postamble: "yyy", important: true, tag: "zzz"}]
      end

      spec "[!33ma7] @option is a Proc object and saves args." do
        class InheritedTest3 < Benry::CmdApp::ActionScope
          @action.("description", detail: "xxx", postamble: "yyy")
          @option.(:xx, "-x, --xxx=<N>", "desc 1", type: Integer, rexp: /\A\d+\z/, enum: [2,4,8], range: (2..8))
          @option.(:yy, "-y, --yyy[=<on|off>]", "desc 2", type: TrueClass, value: false)
        end
        x = InheritedTest3.instance_variable_get('@__option__')
        ok {x}.is_a?(Benry::CmdOpt::Schema)
        items = x.each.to_a()
        ok {items.length}    == 2
        ok {items[0].key}    == :xx
        ok {items[0].optdef} == "-x, --xxx=<N>"
        ok {items[0].desc}   == "desc 1"
        ok {items[0].type}   == Integer
        ok {items[0].rexp}   == /\A\d+\z/
        ok {items[0].enum}   == [2, 4, 8]
        ok {items[0].range}  == (2..8)
        ok {items[0].value}  == nil
        ok {items[1].key}    == :yy
        ok {items[1].optdef} == "-y, --yyy[=<on|off>]"
        ok {items[1].desc}   == "desc 2"
        ok {items[1].type}   == TrueClass
        ok {items[1].rexp}   == nil
        ok {items[1].enum}   == nil
        ok {items[1].range}  == nil
        ok {items[1].value}  == false
      end

      spec "[!gxybo] '@option.()' raises error when '@action.()' not called." do
        pr = proc do
          class InheritedTest4 < Benry::CmdApp::ActionScope
            @option.(:xx, "-x, --xxx=<N>", "desc 1")
          end
        end
        ok {pr}.raise?(Benry::CmdApp::OptionDefError,
                       "@option.(:xx): `@action.()` Required but not called.")
      end

      spec "[!ga6zh] '@option.()' raises error when invalid option info specified." do
        pr = proc do
          class InheritedTest20 < Benry::CmdApp::ActionScope
            @action.("test")
            @option.(:xx, "-x, --xxx=<N>", "desc 1", range: (2..8))
            def hello(xx: nil)
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::OptionDefError,
                       "2..8: Range value should be String, but not.")
      end

      spec "[!yrkxn] @copy_options is a Proc object and copies options from other action." do
        class InheritedTest5 < Benry::CmdApp::ActionScope
          @action.("copy src")
          @option.(:xxx, "-x, --xxx=<arg>", "xxx #1")
          def optcopy1(xxx: nil)
          end
          #
          @action.("copy dst")
          @copy_options.("optcopy1")
          @option.(:yyy, "-y, --yyy=<on|off>", "yyy #2", type=TrueClass)
        end
        x = InheritedTest5.instance_variable_get('@__option__')
        ok {x}.is_a?(Benry::CmdOpt::Schema)
        items = x.each.to_a()
        ok {items.length}    == 2
        ok {items[0].key}    == :xxx
        ok {items[0].short}  == "x"
        ok {items[0].long}   == "xxx"
        ok {items[1].key}    == :yyy
        ok {items[1].short}  == "y"
        ok {items[1].long}   == "yyy"
      end

      spec "[!mhhn2] '@copy_options.()' raises error when action not found." do
        pr = proc do
          class InheritedTest6 < Benry::CmdApp::ActionScope
            @action.("copy")
            @copy_options.("optcopy99")
            def copytest2(yyy: nil)
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::OptionDefError,
                       "@copy_options.(\"optcopy99\"): Action not found.")
      end

    end


    topic '.method_added()' do

      def defined_actions()
        actions = Benry::CmdApp::INDEX.instance_variable_get('@actions')
        action_names = actions.keys()
        yield
        new_names = actions.keys() - action_names
        metadata = new_names.length > 0 ? Benry::CmdApp::INDEX.get_action(new_names[0]) : nil
        return new_names, metadata
      end

      spec "[!idh1j] do nothing if '@__action__' is nil." do
        new_names, x = defined_actions() do
          class Added1Test < Benry::CmdApp::ActionScope
            prefix "added1"
            def hello1(); end
          end
        end
        ok {new_names} == []
        ok {x} == nil
      end

      spec "[!ernnb] clears both '@__action__' and '@__option__'." do
        new_names, x = defined_actions() do
          class Added2Test < Benry::CmdApp::ActionScope
            @action.("test", detail: "XXX", postamble: "YYY")
            @option.(:foo, "--foo", "foo")
          end
          ok {Added2Test.instance_variable_get('@__action__')} != nil
          ok {Added2Test.instance_variable_get('@__option__')} != nil
          Added2Test.class_eval do
            def hello2(foo: nil); end
          end
          ok {Added2Test.instance_variable_get('@__action__')} == nil
          ok {Added2Test.instance_variable_get('@__option__')} == nil
        end
      end

      spec "[!n8tem] creates ActionMetadata object if '@__action__' is not nil." do
        new_names, x = defined_actions() do
          class Added3Test < Benry::CmdApp::ActionScope
            prefix "added3"
            @action.("test", detail: "XXX", postamble: "YYY")
            def hello3(); end
          end
        end
        ok {new_names} == ["added3:hello3"]
        ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
        ok {x.name}      == "added3:hello3"
        ok {x.klass}     == Added3Test
        ok {x.method}    == :hello3
        ok {x.hidden?}   == false
        ok {x.detail}    == "XXX"
        ok {x.postamble} == "YYY"
      end

      spec "[!4pbsc] raises error if keyword param for option not exist in method." do
        pr = proc do
          class Added4Test < Benry::CmdApp::ActionScope
            prefix "added4"
            @action.("test")
            @option.(:flag, "--flag=<on|off>", nil, type: TrueClass)
            def hello4(xx: nil); end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::ActionDefError,
                       "def hello4(): Should have keyword parameter 'flag' for '@option.(:flag)', but not.")
      end

      spec "[!t8vbf] raises error if action name duplicated." do
        pr = proc do
          class Added5Test < Benry::CmdApp::ActionScope
            prefix "added5"
            @action.("test")
            def hello5(xx: nil); end
            @action.("test")
            def hello5(xx: nil); end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::ActionDefError,
                       "def hello5(): Action 'added5:hello5' already exist.")
      end

      case_when '[!5e5o0] when method name is same as default action name...' do

        spec "[!myj3p] uses prefix name (expect last char ':') as action name." do
          new_names, x = defined_actions() do
            class Added6Test < Benry::CmdApp::ActionScope
              prefix "added6", action: :hello6
              @action.("test")
              def hello6(); end
            end
          end
          ok {new_names} == ["added6"]
          ok {x.klass} == Added6Test
          ok {x.method} == :hello6
        end

        spec "[!j5oto] clears '@__default__'." do
          class ClearDefaultTest1 < Benry::CmdApp::ActionScope
            prefix "cleardefault1", action: :test2_   # symbol
            @__default__ != nil  or
              raise MiniTest::Assertion, "@__default__ should NOT be nil"
            #
            @action.("test")
            def test1_(); end
            @__default__ != nil  or
              raise MiniTest::Assertion, "@__default__ should NOT be nil"
            #
            @action.("test")
            def test2_(); end
            @__default__ == nil  or
              raise MiniTest::Assertion, "@__default__ should be nil"
          end
        end

      end

      case_else '[!agpwh] else...' do

        spec "[!3icc4] uses method name as action name." do
          new_names, x = defined_actions() do
            class Added7Test < Benry::CmdApp::ActionScope
              @action.("test")
              def hello7xx(); end
            end
          end
          ok {new_names} == ["hello7xx"]
          ok {x.klass} == Added7Test
          ok {x.method} == :hello7xx
        end

        spec "[!c643b] converts action name 'aa_bb_cc_' into 'aa_bb_cc'." do
          new_names, x = defined_actions() do
            class Added8Test < Benry::CmdApp::ActionScope
              @action.("test")
              def hello8xx_(); end
            end
          end
          ok {new_names} == ["hello8xx"]
          ok {x.klass} == Added8Test
          ok {x.method} == :hello8xx_
        end

        spec "[!3fkb3] converts action name 'aa__bb__cc' into 'aa:bb:cc'." do
          new_names, x = defined_actions() do
            class Added9Test < Benry::CmdApp::ActionScope
              @action.("test")
              def hello9xx__yy__zz(); end
            end
          end
          ok {new_names} == ["hello9xx:yy:zz"]
          ok {x.klass} == Added9Test
          ok {x.method} == :hello9xx__yy__zz
        end

        spec "[!o9s9h] converts action name 'aa_bb:_cc_dd' into 'aa-bb:_cc-dd'." do
          new_names, x = defined_actions() do
            class Added10Test < Benry::CmdApp::ActionScope
              @action.("test")
              def _hello10xx_yy_zz(); end
            end
          end
          ok {new_names} == ["_hello10xx-yy-zz"]
          ok {x.klass} == Added10Test
          ok {x.method} == :_hello10xx_yy_zz
        end

        spec "[!8hlni] when action name is same as default name, uses prefix as action name." do
          new_names, x = defined_actions() do
            class Added11Test < Benry::CmdApp::ActionScope
              prefix "added11", action: "hello11"
              @action.("test")
              def hello11(); end
            end
          end
          ok {new_names} == ["added11"]
          ok {x.klass} == Added11Test
          ok {x.method} == :hello11
        end

        spec "[!q8oxi] clears '@__default__' when default name matched to action name." do
          class ClearDefaultTest2 < Benry::CmdApp::ActionScope
            prefix "cleardefault2", action: "test2"   # string
            @__default__ != nil  or
              raise MiniTest::Assertion, "@__default__ should NOT be nil"
            #
            @action.("test")
            def test1_(); end
            @__default__ != nil  or
              raise MiniTest::Assertion, "@__default__ should NOT be nil"
            #
            @action.("test")
            def test2_(); end
            @__default__ == nil  or
              raise MiniTest::Assertion, "@__default__ should be nil"
          end
        end

        spec "[!xfent] when prefix is provided, adds it to action name." do
          new_names, x = defined_actions() do
            class Added12Test < Benry::CmdApp::ActionScope
              prefix "added12"
              @action.("test")
              def hello12(); end
            end
          end
          ok {new_names} == ["added12:hello12"]
          ok {x.klass} == Added12Test
          ok {x.method} == :hello12
        end

      end

      spec "[!jpzbi] defines same name alias of action as prefix." do
        ## when symbol
        class AliasOfTest1 < Benry::CmdApp::ActionScope
          prefix "blabla1", alias_of: :bla1    # symbol
          @action.("test")
          def bla1(); end
        end
        ok {Benry::CmdApp::INDEX.get_alias("blabla1")} != nil
        ok {Benry::CmdApp::INDEX.get_alias("blabla1").action_name} == "blabla1:bla1"
        ## when string
        class AliasOfTest2 < Benry::CmdApp::ActionScope
          prefix "bla:bla2", alias_of: "blala"    # string
          @action.("test")
          def blala(); end
        end
        ok {Benry::CmdApp::INDEX.get_alias("bla:bla2")} != nil
        ok {Benry::CmdApp::INDEX.get_alias("bla:bla2").action_name} == "bla:bla2:blala"
      end

      spec "[!tvjb0] clears '@__aliasof__' only when alias created." do
        class AliasOfTest3 < Benry::CmdApp::ActionScope
          prefix "bla:bla3", alias_of: "bla3b"    # string
          @__aliasof__ != nil  or
            raise MiniTest::Assertion, "@__aliasof__ should NOT be nil"
          #
          @action.("test")
          def bla3a(); end
          @__aliasof__ != nil  or
            raise MiniTest::Assertion, "@__aliasof__ should NOT be nil"
          #
          @action.("test")
          def bla3b(); end
          @__aliasof__ == nil  or
            raise MiniTest::Assertion, "@__aliasof__ should be nil"
        end
        begin
          ok {AliasOfTest3.instance_variable_get('@__aliasof__')} == nil
        ensure
          AliasOfTest3.class_eval do
            @__aliasof__ = nil
          end
        end
      end

      spec "[!997gs] not raise error when action not found." do
        pr = proc do
          class AliasOfTest4 < Benry::CmdApp::ActionScope
            prefix "blabla4", alias_of: :bla99     # action not exist
            @action.("test")
            def bla3(); end
          end
        end
        begin
          ok {pr}.NOT.raise?(Exception)
        ensure
          AliasOfTest4.class_eval { @__aliasof__ = nil }
        end
      end

      spec "[!349nr] raises error when same name action or alias with prefix already exists." do
        pr = proc do
          class AliasOfTest5a < Benry::CmdApp::ActionScope
            @action.("test")
            def bla5(); end                    # define 'bla5' action
          end
          class AliasOfTest5b < Benry::CmdApp::ActionScope
            prefix "bla5", alias_of: :blala    # define 'bla5' action, too
            @action.("test")
            def blala(); end
          end
        end
        begin
          ok {pr}.raise?(Benry::CmdApp::AliasDefError,
                         'action_alias("bla5", "bla5:blala"): Not allowed to define same name alias as existing action.')
        ensure
          AliasOfTest5b.class_eval { @__aliasof__ = nil }
        end
      end

    end


  end


  topic Benry::CmdApp::BuiltInAction do
    include CommonTestingHelper

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.0.0")
      @config.app_name = "TestApp"
      @config.app_command = "testapp"
      @config.default_action = nil
      @app = Benry::CmdApp::Application.new(@config)
    end


    topic '#help()' do

      spec "[!jfgsy] prints help message of action if action name specified." do
        sout, serr = capture_sio { @app.run("help", "help") }
        ok {serr} == ""
        ok {uncolorize(sout)} == <<"END"
testapp help -- print help message (of action)

Usage:
  $ testapp help [<options>] [<action>]

Options:
  -a, --all          : show private (hidden) options, too
END
      end

      spec "[!fhpjg] prints help message of command if action name not specified." do
        sout, serr = capture_sio { @app.run("help") }
        ok {serr} == ""
        ok {sout}.start_with?(<<"END")
TestApp (1.0.0) -- test app

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message
  -V, --version      : print version

Actions:
END
      end

      spec "[!6g7jh] prints colorized help message when color mode is on." do
        sout, serr = capture_sio(tty: true) { @app.run("help") }
        ok {serr} == ""
        ok {sout}.start_with?(<<"END")
\e[1mTestApp\e[0m (1.0.0) -- test app

\e[34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] [<action> [<arguments>...]]

\e[34mOptions:\e[0m
  \e[1m-h, --help        \e[0m : print help message
  \e[1m-V, --version     \e[0m : print version

\e[34mActions:\e[0m
END
      end

      spec "[!ihr5u] prints non-colorized help message when color mode is off." do
        sout, serr = capture_sio(tty: false) { @app.run("help") }
        ok {serr} == ""
        ok {sout}.start_with?(<<"END")
TestApp (1.0.0) -- test app

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message
  -V, --version      : print version

Actions:
END
      end

    end


  end


  topic Benry::CmdApp::Alias do

    class Alias2Test < Benry::CmdApp::ActionScope
      prefix "alias2"
      #
      @action.("alias test")
      def a1(); end
      #
      @action.("alias test", important: true)
      def a2(); end
      #
      @action.("alias test", important: false)
      def a3(); end
      #
      private
      @action.("alias test")
      def a4(); end
    end


    topic '#important?()' do

      spec "[!5juwq] returns true if `@important == true`." do
        ali = Benry::CmdApp::Alias.new("a2-1", "alias2:a1", important: true)
        ok {ali.important?} == true
      end

      spec "[!1gnbc] returns false if `@important == false`." do
        ali = Benry::CmdApp::Alias.new("a2-2", "alias2:a1", important: false)
        ok {ali.important?} == false
      end

      spec "[!h3nm3] returns true or false according to action object if `@important == nil`." do
        ok {Benry::CmdApp::Alias.new("ali1", "alias2:a1").important?} == nil
        ok {Benry::CmdApp::Alias.new("ali1", "alias2:a2").important?} == true
        ok {Benry::CmdApp::Alias.new("ali1", "alias2:a3").important?} == false
        ok {Benry::CmdApp::Alias.new("ali1", "alias2:a4").important?} == false
      end

    end


  end


end
