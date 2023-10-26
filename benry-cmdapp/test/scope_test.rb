# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative 'shared'



class ScopeTestAction < Benry::CmdApp::Action

  @action.("test")
  def scope9392()
  end

end


class OverrideTestAction1 < Benry::CmdApp::Action
  def foo1__bar1()
  end
end

class OverrideTestAction2 < OverrideTestAction1
  #prefix "foo1:"
  #@action.("foo1")
  #def bar1()
  #end
end


Oktest.scope do


  topic Benry::CmdApp::ActionScope do

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.2.3",
                                          app_name: "TestApp", app_command: "testapp",
                                          option_verbose: true, option_quiet: true,
                                          option_color: true, #option_debug: true,
                                          option_trace: true)
    end


    topic '#__clear_recursive_reference()' do

      spec "[!i68z0] clears instance var which refers context object." do
        scope = Benry::CmdApp::ActionScope.new(@config)
        ctx = scope.instance_eval { @__context__ }
        ok {ctx} != nil
        scope.__clear_recursive_reference()
        ctx = scope.instance_eval { @__context__ }
        ok {ctx} == nil
      end

    end


    topic '.inherited()' do

      spec "[!8cck9] sets Proc object to `@action` in subclass." do
        x = ScopeTestAction.class_eval { @action }
        ok {x}.is_a?(Proc)
        ok {x}.lambda?
      end

      spec "[!r07i7] `@action.()` raises DefinitionError if called consectively." do
        pr = proc do
          ScopeTestAction.class_eval do
            @action.("foo")
            @action.("bar")
            def dummy4922()
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "`@action.()` called without method definition (please define method for this action).")
      end

      spec "[!34psw] `@action.()` stores arguments into `@__actiondef__`." do
        x = nil
        ScopeTestAction.class_eval do
          @__actiondef__ = nil
          #
          @action.("test")
          x = @__actiondef__
          def dummy2321()
          end
        end
        ok {x} == ["test", nil, {:usage=>nil, :detail=>nil, :postamble=>nil, :tag=>nil, :important=>nil, :hidden=>nil}]
      end

      spec "[!en6n0] sets Proc object ot `@option` in subclass." do
        x = ScopeTestAction.class_eval { @option }
        ok {x}.is_a?(Proc)
        ok {x}.lambda?
      end

      spec "[!68hf8] raises DefinitionError if `@option.()` called without `@action.()`." do
        pr = proc do
          ScopeTestAction.class_eval do
            @__actiondef__ = nil
            @option.(:help, "-", "help")
          end
        end
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "`@option.()` called without `@action.()`.")
      end

      spec "[!2p98r] `@option.()` stores arguments into option schema object." do
        tuple = nil
        ScopeTestAction.class_eval do
          @action.("foobar")
          @option.(:lang, "-l <lang>", "language", detail: "blabla", hidden: true) {|val| val }
          @option.(:color, "--color[=<on|off>]", "color mode", type: TrueClass)
          tuple = @__actiondef__
          def s2055(help: false)
          end
        end
        schema = tuple[1]
        ok {schema}.is_a?(Benry::CmdApp::OPTION_SCHEMA_CLASS)
        #
        x = schema.get(:lang)
        ok {x.key} == :lang
        ok {x.short} == "l"
        ok {x.long} == nil
        ok {x.desc} == "language"
        ok {x.type} == nil
        ok {x.detail} == "blabla"
        ok {x.hidden?} == true
        ok {x.callback}.is_a?(Proc)
        #
        x = schema.get(:color)
        ok {x.key} == :color
        ok {x.short} == nil
        ok {x.long} == "color"
        ok {x.desc} == "color mode"
        ok {x.type} == TrueClass
        ok {x.detail} == nil
        ok {x.hidden?} == false
        ok {x.callback} == nil
      end

      spec "[!aiwns] `@copy_options.()` copies options from other action." do
        MyAction.class_eval do
          @action.("hello 1291")
          @option.(:lang, "-l <lang>", "language")
          @option.(:color, "--color[=<on|off>]", "color mode", type: TrueClass)
          @option.(:debug, "-D", "debug mode")
          @option.(:trace, "-T", "trace mode")
          @option.(:indent, "-i[<N>]", "indent", type: Integer)
          def hello1291(lang: nil, color: false, debug: false, trace: false, indent: 0)
          end
          #
          @action.("hello 3942")
          @copy_options.("hello1291", except: [:debug, :trace])
          @option.(:silent, "--silent", "silent mode")
          def hello3942(lang: "en", color: false, indent: 0, silent: false)
          end
        end
        at_end { Benry::CmdApp.undef_action("hello3942") }
        #
        md = Benry::CmdApp::INDEX.metadata_get("hello3942")
        ok {md.schema.option_help()} == <<"END"
  -l <lang>            : language
  --color[=<on|off>]   : color mode
  -i[<N>]              : indent
  --silent             : silent mode
END
      end

      spec "[!mhhn2] `@copy_options.()` raises DefinitionError when action not found." do
        pr = proc do
          MyAction.class_eval do
            @action.("hello 4691")
            @copy_options.("hello469100")
            def hello4691()
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|@copy_options.("hello469100"): Action not found.|)
      end

      spec "[!0slo8] raises DefinitionError if `@copy_options.()` called without `@action.()`." do
        pr = proc do
          MyAction.class_eval do
            @__actiondef__ = nil
            @copy_options.("hello")
            def hello8420()
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|@copy_options.("hello"): Called without `@action.()`.|)
      end

      spec "[!0qz0q] `@copy_options.()` stores arguments into option schema object." do
        x1 = x2 = nil
        MyAction.class_eval do
          @action.("hello")
          x1 = @__actiondef__[1]
          @copy_options.("hello")
          x2 = @__actiondef__[1]
          @__actiondef__ = nil
        end
        ok {x1} == nil
        ok {x2} != nil
        ok {x2}.is_a?(Benry::CmdApp::OPTION_SCHEMA_CLASS)
        ok {x2.to_s()} == <<"END"
  -l, --lang=<lang>    : language name (en/fr/it)
END
      end

    end


    topic '.method_added()' do

      spec "[!6frgx] do nothing if `@action.()` is not called." do
        ScopeTestAction.class_eval { @__actiondef__ = nil }
        x = ScopeTestAction.__send__(:method_added, :foo)
        ok {x} == false
        #
        ScopeTestAction.class_eval do
          def s6732()
          end
          @__actiondef__ = ["test", nil, {}]
        end
        x = ScopeTestAction.__send__(:method_added, :s6732)
        ok {x} == true
      end

      spec "[!e3yjo] clears `@__actiondef__`." do
        x1 = nil
        x2 = nil
        ScopeTestAction.class_eval do
          @action.("test")
          x1 = @__actiondef__
          def s4643()
          end
          x2 = @__actiondef__
        end
        ok {x1} != nil
        ok {x2} == nil
      end

      spec "[!ejdlo] converts method name to action name." do
        ScopeTestAction.class_eval do
          @action.("test")
          def s9321__aa_bb__cc_dd_()
          end
        end
        md = Benry::CmdApp::INDEX.metadata_each.find {|x| x.name =~ /s9321/ }
        ok {md} != nil
        ok {md.name} == "s9321:aa-bb:cc-dd"
      end

      case_when "[!w9qat] when `prefix()` called before defining action method..." do

        spec "[!3pl1r] renames method name to new name with prefix." do
          ScopeTestAction.class_eval do
            prefix "p3442:" do
              prefix "foo:" do
                prefix "bar:" do
                  @action.("test")
                  def s9192()
                  end
                end
              end
            end
          end
          ok {ScopeTestAction.method_defined?(:s9192)} == false
          ok {ScopeTestAction.method_defined?(:p3442__foo__bar__s9192)} == true
        end

        case_when "[!mil2g] when action name matched to 'action:' kwarg of `prefix()`..." do

          spec "[!hztpp] uses pefix name as action name." do
            ScopeTestAction.class_eval do
              prefix "p9782:", action: "s3867" do
                @action.("test")
                def s3867()
                end
              end
            end
            ok {Benry::CmdApp::INDEX.metadata_get("p9782:s3867")} == nil
            ok {Benry::CmdApp::INDEX.metadata_get("p9782")} != nil
            ok {Benry::CmdApp::INDEX.metadata_get("p9782").meth} == :p9782__s3867
          end

          spec "[!cydex] clears `action:` kwarg." do
            x1 = x2 = x3 = nil
            ScopeTestAction.class_eval do
              prefix "p3503:", action: "s5319" do
                x1 = @__prefixdef__[1]
                #
                @action.("test")
                def s1767()
                end
                x2 = @__prefixdef__[1]
                #
                @action.("test")
                def s5319()
                end
                x3 = @__prefixdef__[1]
              end
            end
            ok {x1} == "s5319"
            ok {x2} == "s5319"
            ok {x3} == nil
          end

        end

        case_when "[!8xsnw] when action name matched to `alias_of:` kwarg of `prefix()`..." do

          spec "[!iguvp] adds prefix name to action name." do
            ScopeTestAction.class_eval do
              prefix "p8134:", alias_of: "s6368" do
                @action.("test")
                def s6368()
                end
              end
            end
            md = Benry::CmdApp::INDEX.metadata_each.find {|x| x.name =~ /s6368/ }
            ok {md.name} == "p8134:s6368"
            ok {md}.NOT.alias?
            md = Benry::CmdApp::INDEX.metadata_get("p8134")
            ok {md.name} == "p8134"
            ok {md}.alias?
          end

        end

        case_when "[!wmevh] else..." do

          spec "[!9cyc2] adds prefix name to action name." do
            ScopeTestAction.class_eval do
              prefix "p9986:", alias_of: "s4711" do
                @action.("test")
                def s0629()
                end
                @action.("test")
                def s4711()
                end
              end
            end
            md = Benry::CmdApp::INDEX.metadata_each.find {|x| x.name =~ /s0629/ }
            ok {md.name} == "p9986:s0629"
            ok {md}.NOT.alias?
          end

        end

      end

      case_when "[!y8lh0] else..." do

        spec "[!0ki5g] not add prefix to action name." do
          ScopeTestAction.class_eval do
            prefix "p2592:", action: "s2619" do
              @action.("test")
              def s4487()
              end
              @action.("test")
              def s2619()
              end
            end
          end
          md = Benry::CmdApp::INDEX.metadata_get("p2592:s4487")
          ok {md.name} == "p2592:s4487"
          ok {md}.NOT.alias?
          md = Benry::CmdApp::INDEX.metadata_get("p2592")
          ok {md.name} == "p2592"
          ok {md}.NOT.alias?
        end

      end

      spec "[!dad1q] raises DefinitionError if action with same name already defined." do
        pr = proc do
          ScopeTestAction.class_eval do
            @action.("duplicate")
            def hello()
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "def hello(): Action 'hello' already defined (to redefine it, delete it beforehand by `undef_action()`).")
        #
        pr = proc do
          ScopeTestAction.class_eval do
            prefix "git:" do
              @action.("duplicate")
              def stage()
              end
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "def stage(): Action 'git:stage' already defined (to redefine it, delete it beforehand by `undef_action()`).")
      end

      spec "[!ur8lp] raises DefinitionError if method already defined in parent or ancestor class." do
        pr = proc do
          ScopeTestAction.class_eval do
            @action.("print")
            def print()
            end
          end
        end
        at_end { ScopeTestAction.class_eval { @__actiondef__ = nil } }
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "def print(): Please rename it to `print_()` because same method defined in parent or ancestor class.")
      end

      spec "[!dj0ql] method override check is done with new method name (= prefixed name)." do
        pr = proc do
          ScopeTestAction.class_eval do
            prefix "p2946:" do
              @action.("print")
              def print()
              end
            end
          end
        end
        ok {pr}.NOT.raise?(Exception)
        metadata = Benry::CmdApp::INDEX.metadata_get("p2946:print")
        ok {metadata} != nil
        ok {metadata.meth} == :p2946__print
        #
        pr = proc do
          OverrideTestAction2.class_eval do
            prefix "foo1:"
            @action.("foo1")
            def bar1()
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "def bar1(): Please rename it to `bar1_()` because same method defined in parent or ancestor class.")
      end

      spec "[!7fnh4] registers action metadata." do
        ScopeTestAction.class_eval do
          prefix "p7966:" do
            @action.("test")
            def s3198()
            end
          end
        end
        md = Benry::CmdApp::INDEX.metadata_get("p7966:s3198")
        ok {md} != nil
        ok {md.name} == "p7966:s3198"
        ok {md}.NOT.alias?
      end

      spec "[!lyn0z] registers alias metadata if necessary." do
        ScopeTestAction.class_eval do
          prefix "p0692:", alias_of: "s8075" do
            @action.("test")
            def s8075()
            end
          end
        end
        md = Benry::CmdApp::INDEX.metadata_get("p0692")
        ok {md} != nil
        ok {md}.alias?
        ok {md.action} == "p0692:s8075"
        md = Benry::CmdApp::INDEX.metadata_get("p0692:s8075")
        ok {md} != nil
        ok {md}.NOT.alias?
      end

      spec "[!4402s] clears `alias_of:` kwarg." do
        x1 = x2 = x3 = nil
        ScopeTestAction.class_eval do
          prefix "p7506:", alias_of: "s3449" do
            x1 = @__prefixdef__[2]
            #
            @action.("test")
            def s8075()
            end
            x2 = @__prefixdef__[2]
            #
            @action.("test")
            def s3449()
            end
            x3 = @__prefixdef__[2]
          end
        end
        x1 == "s3449"
        x2 == "s3449"
        x3 == nil
      end

    end


    topic '.__validate_action_method()' do

      spec "[!5a4d3] returns error message if action with same name already defined." do
        x = nil
        ScopeTestAction.class_eval do
          x = __validate_action_method("hello", :tmp__helo, :hello)
        end
        ok {x} == "Action 'hello' already defined (to redefine it, delete it beforehand by `undef_action()`)."
      end

      spec "[!uxsx3] returns error message if method already defined in parent or ancestor class." do
        x = nil
        ScopeTestAction.class_eval do
          x = __validate_action_method("print", :print, :print)
        end
        ok {x} == "Please rename it to `print_()` because same method defined in parent or ancestor class."
      end

      spec "[!3fmpo] method override check is done with new method name (= prefixed name)." do
        x = nil
        ScopeTestAction.class_eval do
          x = __validate_action_method("p3159:print", :print, :xprint)
        end
        ok {x} == "Please rename it to `xprint_()` because same method defined in parent or ancestor class."
      end

    end


    topic '.current_prefix()' do

      spec "[!2zt0f] returns current prefix name such as 'foo:bar:'." do
        x1 = x2 = x3 = x4 = x5 = nil
        ScopeTestAction.class_eval do
          x1 = current_prefix()
          prefix "p9912:" do
            x2 = current_prefix()
            prefix "p3138:" do
              x3 = current_prefix()
            end
            x4 = current_prefix()
          end
          x5 = current_prefix()
        end
        ok {x1} == nil
        ok {x2} == "p9912:"
        ok {x3} == "p9912:p3138:"
        ok {x4} == "p9912:"
        ok {x5} == nil
      end

    end


    topic '.prefix()' do

      spec "[!ermv8] raises DefinitionError if both `action:` and `alias_of:` kwargs are specified." do
        at_end { ScopeTestAction.class_eval { @__prefixdef__ = nil } }
        pr = proc do
          ScopeTestAction.class_eval do
            prefix "p7549:", action: "s0573", alias_of: "s0573"
            @action.("test")
            def s0573()
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       %q|prefix("p7549:", action: "s0573", alias_of: s0573): `action:` and `alias:` are exclusive.|)
      end

      spec "[!mp1p5] raises DefinitionError if prefix is invalid." do
        at_end { ScopeTestAction.class_eval { @__prefixdef__ = nil } }
        pr = proc do
          ScopeTestAction.class_eval do
            prefix "p2737"
            @action.("test")
            def s4393()
            end
          end
        end
        ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                       "prefix(\"p2737\"): Prefix name should be end with ':'.")
      end

      case_when "[!kwst6] if block given..." do

        spec "[!t8wwm] saves previous prefix data and restore them at end of block." do
          x1 = x2 = x3 = nil
          ScopeTestAction.class_eval do
            x1 = @__prefixdef__
            prefix "p4929:" do
              x2 = @__prefixdef__
              @action.("test")
              def s0997()
              end
            end
            x3 = @__prefixdef__
          end
          ok {x1} == nil
          ok {x2} != nil
          ok {x3} == nil
        end

        spec "[!w52y5] raises DefinitionError if `action:` specified but target action not defined." do
          at_end { ScopeTestAction.class_eval { @__prefixdef__ = nil } }
          pr = proc do
            ScopeTestAction.class_eval do
              prefix "p4929:", action: "s7832" do
                @action.("test")
                def s2649()
                end
              end
            end
          end
          ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                         %q|prefx("p4929:", action: "s7832"): Target action not defined.|)
        end

        spec "[!zs3b5] raises DefinitionError if `alias_of:` specified but target action not defined." do
          at_end { ScopeTestAction.class_eval { @__prefixdef__ = nil } }
          pr = proc do
            ScopeTestAction.class_eval do
              prefix "p2476:", alias_of: "s6678" do
                @action.("test")
                def s1452()
                end
              end
            end
          end
          ok {pr}.raise?(Benry::CmdApp::DefinitionError,
                         %q|prefx("p2476:", alias_of: "s6678"): Target action of alias not defined.|)
        end

      end

      case_when "[!yqhm8] else..." do

        spec "[!tgux9] just stores arguments into class." do
          ScopeTestAction.class_eval do
            @__prefixdef__ = nil
            prefix "p6062:"
          end
          x = ScopeTestAction.class_eval { @__prefixdef__ }
          ok {x} == ["p6062:", nil, nil]
        end

      end

    end


    topic '.__validate_prefix()' do

      spec "[!bac19] returns error message if prefix is not a string." do
        errmsg = ScopeTestAction.__validate_prefix(:foo)
        ok {errmsg} == "String expected, but got Symbol."
      end

      spec "[!608fc] returns error message if prefix doesn't end with ':'." do
        errmsg = ScopeTestAction.__validate_prefix("foo")
        ok {errmsg} == "Prefix name should be end with ':'."
      end

      spec "[!vupza] returns error message if prefix contains '_'." do
        errmsg = ScopeTestAction.__validate_prefix("foo_bar:")
        ok {errmsg} == "Prefix name should not contain '_' (use '-' instead)."
      end

      spec "[!5vgn3] returns error message if prefix is invalid." do
        errmsg = ScopeTestAction.__validate_prefix("123:")
        ok {errmsg} == "Invalid prefix name."
      end

      spec "[!7rphu] returns nil if prefix is valid." do
        errmsg = ScopeTestAction.__validate_prefix("foo-bar:")
        ok {errmsg} == nil
      end

    end


    topic '#run_action_once()' do

      spec "[!nqjxk] runs action and returns true if not runned ever." do
        scope = MyAction.new(@config)
        capture_sio do
          ok {scope.run_action_once("hello")} == true
        end
      end

      spec "[!wcyut] not run action and returns false if already runned." do
        scope = MyAction.new(@config)
        sout, serr = capture_sio do
          ok {scope.run_action_once("hello")} == true
          ok {scope.run_action_once("hello")} == false
          ok {scope.run_action_once("hello")} == false
        end
        ok {sout} == "Hello, world!\n"
      end

    end


    topic '#run_action_anyway()' do

      spec "[!uwi68] runs action and returns true." do
        scope = MyAction.new(@config)
        sout, serr = capture_sio do
          ok {scope.run_action_anyway("hello")} == true
          ok {scope.run_action_anyway("hello")} == true
          ok {scope.run_action_anyway("hello")} == true
        end
        ok {sout} == "Hello, world!\n" * 3
      end

    end


  end


  topic Benry::CmdApp::BuiltInAction do

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.2.3",
                                          app_name: "TestApp", app_command: "testapp",
                                          option_verbose: true, option_quiet: true,
                                          option_color: true, #option_debug: true,
                                          option_trace: true)
    end

    topic '#help()' do

      spec "[!2n99u] raises ActionError if current application is not nil." do
        scope = Benry::CmdApp::BuiltInAction.new(@config)
        pr = proc { scope.help() }
        ok {pr}.raise?(Benry::CmdApp::ActionError,
                       "'help' aciton is available only when invoked from application.")
      end

      spec "[!g0n06] prints application help message if action name not specified." do
        app = Benry::CmdApp::Application.new(@config)
        Benry::CmdApp._set_current_app(app)
        at_end { Benry::CmdApp._set_current_app(nil) }
        scope = Benry::CmdApp::BuiltInAction.new(@config)
        sout, serr = capture_sio { scope.help() }
        ok {sout} =~ /\A\e\[1mTestApp\e\[0m \(1\.2\.3\) --- test app$/
        ok {sout} =~ /^\e\[1;34mUsage:\e\[0m$/
        ok {sout} =~ /^\e\[1;34mOptions:\e\[0m$/
        ok {sout} =~ /^\e\[1;34mActions:\e\[0m$/
      end

      spec "[!epj74] prints action help message if action name specified." do
        app = Benry::CmdApp::Application.new(@config)
        Benry::CmdApp._set_current_app(app)
        at_end { Benry::CmdApp._set_current_app(nil) }
        scope = Benry::CmdApp::BuiltInAction.new(@config)
        sout, serr = capture_sio { scope.help("hello") }
        ok {sout} =~ /\A\e\[1mtestapp hello\e\[0m --- greeting message$/
        ok {sout} =~ /^\e\[1;34mUsage:\e\[0m$/
        ok {sout} =~ /^\e\[1;34mOptions:\e\[0m$/
        ok {sout} !~ /^\e\[1;34mActions:\e\[0m$/
      end

    end


  end


end