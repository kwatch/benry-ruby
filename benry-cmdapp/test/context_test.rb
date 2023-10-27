# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative "shared"



class FooBarAction < Benry::CmdApp::Action
  prefix "foo:"

  @action.("prep for foo")
  def prep; puts "foo:prep"; end

  prefix "bar:" do

    @action.("prep for foo:bar")
    def prep; puts "foo:bar:prep"; end

    prefix "baz:" do

      @action.("prep for foo:bar:baz")
      def prep; puts "foo:bar:baz:prep"; end

      @action.("aaa")
      def aaa(); run_action("prep"); puts "foo:bar:baz:aaa"; end

    end

    @action.("bbb")
    def bbb(); run_action("prep"); puts "foo:bar:bbb"; end

  end

  @action.("ccc")
  def ccc(); run_action("prep"); puts "foo:ccc"; end

  @action.("ddd")
  def ddd(); run_action("prep"); puts "foo:ddd"; end

  ### looped action

  @action.("looped")
  def loop1()
    run_once("loop2")
  end

  @action.("looped")
  def loop2()
    run_once("loop3")
  end

  @action.("looped")
  def loop3()
    run_once("loop1")
  end

  ##

  @action.("err1")
  @option.(:z, "-z", "option z")
  def err1(x, y=0, z: nil)
    puts "x=#{x.inspect}, y=#{y.inspect}, z=#{z.inspect}"
  end

  ##

  @action.("nest1")
  def nest1(); run_action("nest2"); end

  @action.("nest2")
  def nest2(); run_action("nest3"); end

  @action.("nest3")
  def nest3(); puts "nest3"; end

  ##

  @action.("takes any arguments")
  def anyargs(*args, **kwargs)
    puts "args=#{args.inspect}, kwargs=#{kwargs.inspect}"
  end

end


Oktest.scope do


  topic Benry::CmdApp::ApplicationContext do


    before do
      @config  = Benry::CmdApp::Config.new("test app", "1.2.3", app_command: "testapp")
      @context = Benry::CmdApp::ApplicationContext.new(@config)
    end


    topic '#start_action()' do

      spec "[!2mnh7] looks up action metadata with action or alias name." do
        metadata = Benry::CmdApp::INDEX.metadata_get("foo:anyargs")
        ok {metadata} != nil
        Benry::CmdApp.define_alias("ali21", "foo:anyargs")
        Benry::CmdApp.define_alias("ali22", "ali21")
        Benry::CmdApp.define_alias("ali23", "ali22")
        #
        sout, serr = capture_sio() { @context.start_action("ali23", []) }
        ok {sout} == "args=[], kwargs={}\n"
        #
        r = recorder()
        r.fake_method(@context, :_invoke_action => nil)
        @context.start_action("ali23", [])
        ok {r[0].args} == [metadata, [], {}, {:once=>false}]
      end

      spec "[!0ukvb] raises CommandError if action nor alias not found." do
        pr = proc { @context.start_action("hello99", []) }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "hello99: Action nor alias not found.")
      end

      spec "[!9n46s] if alias has its own args, combines them with command-line args." do
        metadata = Benry::CmdApp::INDEX.metadata_get("foo:anyargs")
        ok {metadata} != nil
        Benry::CmdApp.define_alias("ali31", ["foo:anyargs", "aa"])
        Benry::CmdApp.define_alias("ali32", "ali31")
        Benry::CmdApp.define_alias("ali33", ["ali32"      , "bb", "cc"])
        #
        sout, serr = capture_sio() { @context.start_action("ali33", ["xx", "yy"]) }
        ok {sout} == "args=[\"aa\", \"bb\", \"cc\", \"xx\", \"yy\"], kwargs={}\n"
        #
        r = recorder()
        r.fake_method(@context, :_invoke_action => nil)
        @context.start_action("ali33", [])
        ok {r[0].args} == [metadata, ["aa", "bb", "cc"], {}, {:once=>false}]
      end

      spec "[!5ru31] options in alias args are also parsed as well as command-line options." do
        metadata = Benry::CmdApp::INDEX.metadata_get("hello")
        ok {metadata} != nil
        Benry::CmdApp.define_alias("ali41", ["hello", "-l", "it"])
        Benry::CmdApp.define_alias("ali42", ["ali41"])
        #
        sout, serr = capture_sio() { @context.start_action("ali42", ["-l", "fr", "Alice"]) }
        ok {sout} == "Bonjour, Alice!\n"
        #
        r = recorder()
        r.fake_method(@context, :_invoke_action => nil)
        @context.start_action("ali42", ["Alice"])
        ok {r[0].args} == [metadata, ["Alice"], {:lang=>"it"}, {:once=>false}]
      end

      spec "[!r3gfv] raises OptionError if invalid action options specified." do
        pr = proc { @context.start_action("hello", ["-x"]) }
        ok {pr}.raise?(Benry::CmdApp::OptionError,
                       "-x: Unknown option.")
      end

      spec "[!lg6br] runs action with command-line arguments." do
        sout, serr = capture_sio do
          @context.start_action("hello", ["-lit", "Alice"])
        end
        ok {sout} == "Chao, Alice!\n"
        ok {serr} == ""
      end

      spec "[!jcguj] clears instance variables." do
        @context.instance_eval { @status_dict[:x] = :done }
        ok {@context.instance_eval { @status_dict } }.NOT.empty?
        r = recorder()
        r.record_method(@context, :teardown)
        sout, serr = capture_sio do
          @context.start_action("hello", ["-lit", "Alice"])
        end
        ok {r[0].name} == :teardown
        ok {r[0].args} == []
        ok {@context.instance_eval { @status_dict } }.empty?
      end

    end


    topic '#invoke_action()' do

      spec "[!dri6e] if called from other action containing prefix, looks up action with the prefix firstly." do
        sout, serr = capture_sio { @context.invoke_action("foo:ccc", [], {}) }
        ok {sout} == "foo:prep\nfoo:ccc\n"
        #
        sout, serr = capture_sio { @context.invoke_action("foo:bar:bbb", [], {}) }
        ok {sout} == "foo:bar:prep\nfoo:bar:bbb\n"
        #
        sout, serr = capture_sio { @context.invoke_action("foo:bar:baz:aaa", [], {}) }
        ok {sout} == "foo:bar:baz:prep\nfoo:bar:baz:aaa\n"
      end

      spec "[!ygpsw] raises ActionError if action not found." do
        pr = proc { @context.invoke_action("foo:xxx", [], {}) }
        ok {pr}.raise?(Benry::CmdApp::ActionError,
                       "foo:xxx: Action not found.")
      end

      spec "[!de6a9] raises ActionError if alias name specified." do
        Benry::CmdApp.define_alias("a0469", "hello")
        pr = proc { @context.invoke_action("a0469", [], {}) }
        ok {pr}.raise?(Benry::CmdApp::ActionError,
                       "a0469: Action expected, but it is an alias.")
      end

      spec "[!ev3qh] handles help option firstly if specified." do
        config = Benry::CmdApp::Config.new("x", app_command: "testapp")
        app = Benry::CmdApp::Application.new(config)
        Benry::CmdApp._set_current_app(app)
        at_end { Benry::CmdApp._set_current_app(nil) }
        #
        expected = <<"END"
\e[1mtestapp hello\e[0m --- greeting message

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp hello\e[0m [<options>] [<name>]

\e[1;34mOptions:\e[0m
  -l, --lang=<lang>  : language name (en/fr/it)
END
        #
        sout, serr = capture_sio do
          @context.invoke_action("hello", [], {:help=>true})
        end
        ok {sout} == expected
        #
        sout, serr = capture_sio { app.run("hello", "--help", "--lang=en") }
        ok {sout} == expected
        #
        sout, serr = capture_sio { app.run("hello", "-h", "-lfr") }
        ok {sout} == expected
      end

      spec "[!6hoir] don't run action and returns false if `once: true` specified and the action already done." do
        ret1 = ret2 = ret3 = nil
        sout, serr = capture_sio do
          ret1 = @context.invoke_action("foo:prep", [], {}, once: true)
          ret2 = @context.invoke_action("foo:prep", [], {}, once: true)
          ret3 = @context.invoke_action("foo:prep", [], {}, once: true)
        end
        ok {sout} == "foo:prep\n"
        ok {ret1} == true
        ok {ret2} == false
        ok {ret3} == false
        #
        sout, serr = capture_sio do
          ret1 = @context.invoke_action("foo:prep", [], {}, once: false)
          ret2 = @context.invoke_action("foo:prep", [], {}, once: false)
          ret3 = @context.invoke_action("foo:prep", [], {}, once: false)
        end
        ok {sout} == "foo:prep\n" * 3
        ok {ret1} == true
        ok {ret2} == true
        ok {ret3} == true
      end

      spec "[!xwlou] raises ActionError if looped aciton detected." do
        pr = proc { @context.invoke_action("foo:loop1", [], {}) }
        ok {pr}.raise?(Benry::CmdApp::ActionError,
                       "foo:loop1: Looped action detected.")
      end

      spec "[!peqk8] raises ActionError if args and opts not matched to action method." do
        pr = proc { @context.invoke_action("foo:err1", [], {}) }
        ok {pr}.raise?(Benry::CmdApp::ActionError,
                       "foo:err1: Argument required (but nothing specified).")
        pr = proc { @context.invoke_action("foo:err1", ["X", "Y", "Z"], {}) }
        ok {pr}.raise?(Benry::CmdApp::ActionError,
                       "foo:err1: Too much arguments (at most 2 args).")
      end

      spec "[!kao97] action invocation is nestable." do
        sout, serr = capture_sio do
          @context.invoke_action("foo:nest1", [], {})
        end
        ok {sout} == "nest3\n"
      end

      spec "[!5jdlh] runs action method with scope object." do
        sout, serr = capture_sio do
          @context.invoke_action("foo:prep", [], {})
        end
        ok {sout} == "foo:prep\n"
      end

      spec "[!9uue9] reports enter into and exit from action if global '-T' option specified." do
        @config.trace_mode = true
        sout, serr = capture_sio(tty: true) do
          @context.invoke_action("foo:nest1", [], {})
        end
        ok {sout} == <<"END"
\e[33m### enter: foo:nest1\e[0m
\e[33m### enter: foo:nest2\e[0m
\e[33m### enter: foo:nest3\e[0m
nest3
\e[33m### exit:  foo:nest3\e[0m
\e[33m### exit:  foo:nest2\e[0m
\e[33m### exit:  foo:nest1\e[0m
END
        #
        sout, serr = capture_sio(tty: false) do
          @context.invoke_action("foo:nest1", [], {})
        end
        ok {sout} == <<"END"
### enter: foo:nest1
### enter: foo:nest2
### enter: foo:nest3
nest3
### exit:  foo:nest3
### exit:  foo:nest2
### exit:  foo:nest1
END
      end

      spec "[!ndxc3] returns true if action invoked." do
        ret = nil
        capture_sio() do
          ret = @context.invoke_action("foo:bar:prep", [], {})
        end
        ok {ret} == true
      end

    end


    topic '#new_scope_object()' do

      spec "[!1uzs3] creates new scope object." do
        md = Benry::CmdApp::INDEX.metadata_get("hello")
        x = @context.__send__(:new_scope_object, md)
        ok {x}.is_a?(md.klass)
        ok {x}.is_a?(MyAction)
        ok {x.instance_variable_get(:@__context__)} == @context
      end

    end

  end


end
