# -*- coding: utf-8 -*-

require 'oktest'

require 'benry/cmdapp'
require_relative './shared'


Oktest.scope do



  topic Benry::CmdApp::Config do


    topic '#initialize()' do

      spec "[!uve4e] sets command name automatically if not provided." do
        config = Benry::CmdApp::Config.new("test")
        ok {config.app_command} != nil
        ok {config.app_command} == File.basename($0)
      end

    end


  end


  topic Benry::CmdApp::AppOptionSchema do


    topic '#initialize()' do

      def new_gschema(desc="", version=nil, **kwargs)
        config = Benry::CmdApp::Config.new(desc, version, **kwargs)
        x = Benry::CmdApp::AppOptionSchema.new(config)
        return x
      end

      spec "[!3ihzx] do nothing when config is nil." do
        x = nil
        pr = proc { x = Benry::CmdApp::AppOptionSchema.new(nil) }
        ok {pr}.NOT.raise?(Exception)
        ok {x}.is_a?(Benry::CmdApp::AppOptionSchema)
      end

      spec "[!tq2ol] adds '-h, --help' option if 'config.option_help' is set." do
        x = new_gschema(option_help: true)
        ok {x.find_long_option("help")} != nil
        ok {x.find_short_option("h")}   != nil
        x = new_gschema(option_help: false)
        ok {x.find_long_option("help")} == nil
        ok {x.find_short_option("h")}   == nil
      end

      spec "[!mbtw0] adds '-V, --version' option if 'config.app_version' is set." do
        x = new_gschema("", "0.0.0")
        ok {x.find_long_option("version")} != nil
        ok {x.find_short_option("V")}      != nil
        x = new_gschema("", nil)
        ok {x.find_long_option("version")} == nil
        ok {x.find_short_option("V")}      == nil
      end

      spec "[!f5do6] adds '-a, --all' option if 'config.option_all' is set." do
        x = new_gschema(option_all: true)
        ok {x.find_long_option("all")} != nil
        ok {x.find_short_option("a")}  != nil
        x = new_gschema(option_all: false)
        ok {x.find_long_option("all")} == nil
        ok {x.find_short_option("a")}  == nil
      end

      spec "[!cracf] adds '-v, --verbose' option if 'config.option_verbose' is set." do
        x = new_gschema(option_verbose: true)
        ok {x.find_long_option("verbose")} != nil
        ok {x.find_short_option("v")}  != nil
        x = new_gschema(option_verbose: false)
        ok {x.find_long_option("verbose")} == nil
        ok {x.find_short_option("v")}  == nil
      end

      spec "[!2vil6] adds '-q, --quiet' option if 'config.option_quiet' is set." do
        x = new_gschema(option_quiet: true)
        ok {x.find_long_option("quiet")} != nil
        ok {x.find_short_option("q")}  != nil
        x = new_gschema(option_quiet: false)
        ok {x.find_long_option("quiet")} == nil
        ok {x.find_short_option("q")}  == nil
      end

      spec "[!6zw3j] adds '--color=<on|off>' option if 'config.option_color' is set." do
        x = new_gschema(option_color: true)
        ok {x.find_long_option("color")} != nil
        x = new_gschema(option_quiet: false)
        ok {x.find_long_option("color")} == nil
      end

      spec "[!29wfy] adds '-D, --debug' option if 'config.option_debug' is set." do
        x = new_gschema(option_debug: true)
        ok {x.find_long_option("debug")} != nil
        ok {x.find_short_option("D")}    != nil
        x = new_gschema(option_debug: false)
        ok {x.find_long_option("debug")} == nil
        ok {x.find_short_option("D")}    == nil
      end

      spec "[!s97go] adds '-T, --trace' option if 'config.option_trace' is set." do
        x = new_gschema(option_trace: true)
        ok {x.find_long_option("trace")} != nil
        ok {x.find_short_option("T")}    != nil
        x = new_gschema(option_debug: false)
        ok {x.find_long_option("trace")} == nil
        ok {x.find_short_option("T")}    == nil
      end

    end


    topic '#sort_options_in_this_order()' do

      def new_gschema(desc="app test", version="1.0.0")
        config = Benry::CmdApp::Config.new(desc, version)
        config.option_all = true
        config.option_verbose = true
        config.option_quiet = true
        config.option_debug = true
        return Benry::CmdApp::AppOptionSchema.new(config)
      end

      spec "[!6udxr] sorts options in order of keys specified." do
        x = new_gschema()
        keys1 = x.each.collect(&:key)
        ok {keys1} == [:help, :version, :all, :verbose, :quiet, :debug]
        x.sort_options_in_this_order(:help, :quiet, :verbose, :all, :trace, :debug, :version)
        keys2 = x.each.collect(&:key)
        ok {keys2} == [:help, :quiet, :verbose, :all, :debug, :version]
      end

      spec "[!8hhuf] options which key doesn't appear in keys are moved at end of options." do
        x = new_gschema()
        x.sort_options_in_this_order(:quiet, :verbose, :all, :debug)  # missing :help and :version
        keys = x.each.collect(&:key)
        ok {keys[-2]} == :help
        ok {keys[-1]} == :version
        ok {keys} == [:quiet, :verbose, :all, :debug, :help, :version]
      end

    end


  end


  topic Benry::CmdApp::Application do
    include CommonTestingHelper

    class AppTest < Benry::CmdApp::ActionScope
      @action.("print greeting message")
      @option.(:lang, "-l, --lang=<en|fr|it>", "language")
      def sayhello(user="world", lang: "en")
        case lang
        when "en" ;  puts "Hello, #{user}!"
        when "fr" ;  puts "Bonjour, #{user}!"
        when "it" ;  puts "Ciao, #{user}!"
        else      ;  raise "#{lang}: unknown language."
        end
      end
    end

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                          app_name: "TestApp", app_command: "testapp",
                                          default_action: nil,
                                          option_all: true, option_debug: true)
      @app = Benry::CmdApp::Application.new(@config)
    end

    def _run_app(*args)
      sout, serr = capture_sio { @app.run(*args) }
      ok {serr} == ""
      return sout
    end


    topic '#initialize()' do

      spec "[!jkprn] creates option schema object according to config." do
        c = Benry::CmdApp::Config.new("test", "1.0.0", option_debug: true)
        app = Benry::CmdApp::Application.new(c)
        schema = app.instance_variable_get('@schema')
        ok {schema}.is_a?(Benry::CmdOpt::Schema)
        items = schema.each.to_a()
        ok {items[0].key} == :help
        ok {items[1].key} == :version
        ok {items[2].key} == :debug
        ok {schema.option_help()} == <<END
  -h, --help     : print help message
  -V, --version  : print version
  -D, --debug    : debug mode (set $DEBUG_MODE to true)
END
      end

      spec "[!h786g] acceps callback block." do
        config = Benry::CmdApp::Config.new("test app")
        n = 0
        app = Benry::CmdApp::Application.new(config) do |args|
          n += 1
        end
        ok {app.callback}.is_a?(Proc)
        ok {n} == 0
        app.callback.call([])
        ok {n} == 1
        app.callback.call([])
        ok {n} == 2
      end

    end


    topic '#main()' do

      after do
        $cmdapp_config = nil
      end

      spec "[!y6q9z] runs action with options." do
        sout, serr = capture_sio { @app.main(["sayhello", "-l", "it", "Alice"]) }
        ok {serr} == ""
        ok {sout} == "Ciao, Alice!\n"
      end

      spec "[!a7d4w] prints error message with '[ERROR]' prompt." do
        sout, serr = capture_sio { @app.main(["sayhello", "Alice", "Bob"]) }
        ok {serr} == "\e[0;31m[ERROR]\e[0m sayhello: Too much arguments (at most 1).\n"
        ok {sout} == ""
      end

      spec "[!r7opi] prints filename and line number on where error raised if DefinitionError." do
        class MainTest1 < Benry::CmdApp::ActionScope
          prefix "main1"
          @action.("test")
          def err1
            MainTest1.class_eval do
              @action.("test")
              @option.(:foo, "--foo", "foo")
              def err2(bar: nil)   # should have keyword parameter 'foo'
              end
            end
          end
        end
        lineno = __LINE__ - 5
        sout, serr = capture_sio { @app.main(["main1:err1"]) }
        ok {sout} == ""
        serr = serr.sub(/file: \/.*?test\//, 'file: test/')
        ok {serr} == <<"END"
\e[0;31m[ERROR]\e[0m def err2(): Should have keyword parameter 'foo' for '@option.(:foo)', but not.
\t\(file: test\/app_test\.rb, line: #{lineno})
END
      end

      spec "[!v0zrf] error location can be filtered by block." do
        class MainTest2 < Benry::CmdApp::ActionScope
          prefix "main2"
          @action.("test")
          def err2
            _err2()
          end
          def _err2()
            MainTest2.class_eval do  # == lineno2
              @action.("test")
              @option.(:foo, "--foo", "foo")
              def err2x(bar: nil)    # == lineno1
              end
            end
          end
        end
        lineno1 = __LINE__ - 5
        lineno2 = lineno1 - 3
        ## no filter
        sout, serr = capture_sio { @app.main(["main2:err2"]) }
        ok {sout} == ""
        ok {serr} =~ /\t\(file: .*\/app_test\.rb, line: #{lineno1}\)\n/
        ## filter by block
        sout, serr = capture_sio {
          @app.main(["main2:err2"]) {|exc| exc.lineno == lineno2 }
        }
        ok {sout} == ""
        ok {serr} =~ /\t\(file: .*\/app_test\.rb, line: #{lineno2}\)\n/
      end

      spec "[!6ro6n] not catch error when $DEBUG_MODE is on." do
        bkup = $DEBUG_MODE
        begin
          pr = proc { @app.main(["-D", "sayhello", "Alice", "Bob"]) }
          ok {pr}.raise?(Benry::CmdApp::CommandError,
                         "sayhello: Too much arguments (at most 1).")
        ensure
          $DEBUG_MODE = bkup
        end
      end

      spec "[!5oypr] returns 0 as exit code when no errors occurred." do
        ret = nil
        sout, serr = capture_sio do
          ret = @app.main(["sayhello", "Alice", "-l", "it"])
        end
        ok {ret} == 0
        ok {serr} == ""
        ok {sout} == "Ciao, Alice!\n"
      end

      spec "[!qk5q5] returns 1 as exit code when error occurred." do
        ret = nil
        sout, serr = capture_sio do
          ret = @app.main(["sayhello", "Alice", "Bob"])
        end
        ok {ret} == 1
        ok {serr} == "\e[0;31m[ERROR]\e[0m sayhello: Too much arguments (at most 1).\n"
        ok {sout} == ""
      end

    end


    topic '#run()' do

      class AppRunTest < Benry::CmdApp::ActionScope
        #
        @action.("test config")
        def check_config()
          puts "$cmdapp_config.class=#{$cmdapp_config.class.name}"
        end
        #
        @action.("test global option parseing")
        @option.(:help, "-h, --help", "print help")
        def test_globalopt(help: false)
          puts "help=#{help}"
        end
        #
        @action.("test debug option")
        def test_debugopt(help: false)
          puts "$DEBUG_MODE=#{$DEBUG_MODE}"
        end
        #
        @action.("arity test")
        def test_arity1(xx, yy, zz=nil)
        end
        #
        @action.("arity test with variable args")
        def test_arity2(xx, yy, zz=nil, *rest)
        end
        #
        @action.("raises exception")
        def test_exception1()
          1/0
        end
        #
        @action.("loop test")
        def test_loop1()
          run_action_once("test-loop2")
        end
        @action.("loop test")
        def test_loop2()
          run_action_once("test-loop1")
        end
      end

      spec "[!t4ypg] sets $cmdapp_config at beginning." do
        sout, serr = capture_sio { @app.run("check-config") }
        ok {serr} == ""
        ok {sout} == "$cmdapp_config.class=Benry::CmdApp::Config\n"
      end

      spec "[!pyotc] sets global options to '@global_options'." do
        ok {@app.instance_variable_get('@global_options')} == nil
        capture_sio { @app.run("--help") }
        ok {@app.instance_variable_get('@global_options')} == {:help=>true}
      end

      spec "[!go9kk] sets global variables according to global options." do
        config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                           option_verbose: true,
                                           option_quiet: true,
                                           option_debug: true,
                                           option_color: true)
        app = Benry::CmdApp::Application.new(config)
        bkup = [$QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]
        begin
          ['-v', '--verbose'].each do |x|
            $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil
            capture_sio { app.run(x, '-h') }
            ok {[$QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [false, nil, nil]
          end
          #
          ['-q', '--quiet'].each do |x|
            $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil
            capture_sio { app.run(x, '-h') }
            ok {[$QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [true, nil, nil]
          end
          #
          ['-D', '--debug'].each do |x|
            $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil
            capture_sio { app.run(x, '-h') }
            ok {[$QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [nil, true, nil]
          end
          #
          ['--color', '--color=on'].each do |x|
            $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil
            capture_sio { app.run(x, '-h') }
            ok {[$QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [nil, nil, true]
          end
          ['--color=off'].each do |x|
            $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil
            capture_sio { app.run(x, '-h') }
            ok {[$QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [nil, nil, false]
          end
        ensure
          $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = bkup
        end
      end

      spec "[!5iczl] skip actions if help option or version option specified." do
        def @app.do_callback(args, global_opts)
          @_called_ = args.dup
        end
        capture_sio { @app.run("--help") }
        ok {@app.instance_variable_get('@_called_')} == nil
        capture_sio { @app.run("--version") }
        ok {@app.instance_variable_get('@_called_')} == nil
        capture_sio { @app.run("sayhello") }
        ok {@app.instance_variable_get('@_called_')} == ["sayhello"]
      end

      spec "[!w584g] calls callback method." do
        def @app.do_callback(args, global_opts)
          @_called_ = args.dup
        end
        ok {@app.instance_variable_get('@_called_')} == nil
        capture_sio { @app.run("sayhello") }
        ok {@app.instance_variable_get('@_called_')} == ["sayhello"]
      end

      spec "[!pbug7] skip actions if callback method throws `:SKIP`." do
        def @app.do_callback(args, global_opts)
          @_called1 = args.dup
          throw :SKIP
        end
        def @app.do_find_action(args, global_opts)
          super
          @_called2 = args.dup
        end
        ok {@app.instance_variable_get('@_called1')} == nil
        ok {@app.instance_variable_get('@_called2')} == nil
        capture_sio { @app.run("sayhello") }
        ok {@app.instance_variable_get('@_called1')} == ["sayhello"]
        ok {@app.instance_variable_get('@_called2')} == nil
      end

      spec "[!avxos] prints candidate actions if action name ends with ':'." do
        class CandidateTest1 < Benry::CmdApp::ActionScope
          prefix "candi:date1"
          @action.("test")
          def bbb(); end
          @action.("test")
          def aaa(); end
        end
        ## without tty
        sout, serr = capture_sio(tty: false) { @app.run("candi:date1:") }
        ok {serr} == ""
        ok {sout} == <<"END"
Actions:
  candi:date1:aaa    : test
  candi:date1:bbb    : test
END
        ## with tty
        sout, serr = capture_sio(tty: true) { @app.run("candi:date1:") }
        ok {serr} == ""
        ok {sout} == <<"END"
\e[34mActions:\e[0m
  \e[1mcandi:date1:aaa   \e[0m : test
  \e[1mcandi:date1:bbb   \e[0m : test
END
      end

      spec "[!eeh0y] candidates are not printed if 'config.feat_candidate' is false." do
        class CandidateTest5 < Benry::CmdApp::ActionScope
          prefix "candi:date5"
          @action.("test b")
          def bbb(); end
          @action.("test a")
          def aaa(); end
        end
        ## flag is on
        @app.config.feat_candidate = false
        pr = proc { @app.run("candi:date5:") }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "candi:date5:: Unknown action.")
        ## flag is off
        @app.config.feat_candidate = true
        sout, serr = capture_sio(tty: false) { @app.run("candi:date5:") }
        ok {serr} == ""
        ok {sout} == <<"END"
Actions:
  candi:date5:aaa    : test a
  candi:date5:bbb    : test b
END
      end

      spec "[!l0g1l] skip actions if no action specified and 'config.default_help' is set." do
        def @app.do_find_action(args, global_opts)
          ret = super
          @_args1 = args.dup
          @_result = ret
          ret
        end
        def @app.do_run_action(metadata, args, global_opts)
          ret = super
          @_args2 = args.dup
          ret
        end
        @app.config.default_help = true
        capture_sio { @app.run() }
        ok {@app.instance_variable_get('@_args1')} == []
        ok {@app.instance_variable_get('@_result')} == nil
        ok {@app.instance_variable_get('@_args2')} == nil
      end

      spec "[!x1xgc] run action with options and arguments." do
        sout, serr = capture_sio { @app.run("sayhello", "Alice", "-l", "it") }
        ok {serr} == ""
        ok {sout} == "Ciao, Alice!\n"
      end

      spec "[!agfdi] reports error when action not found." do
        pr = proc { @app.run("xxx-yyy") }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "xxx-yyy: Unknown action.")
      end

      spec "[!v5k56] runs default action if action not specified." do
        @config.default_action = "sayhello"
        sout, serr = capture_sio { @app.run() }
        ok {serr} == ""
        ok {sout} == "Hello, world!\n"
      end

      spec "[!o5i3w] reports error when default action not found." do
        @config.default_action = "xxx-zzz"
        pr = proc { @app.run() }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "xxx-zzz: Unknown default action.")
      end

      spec "[!7h0ku] prints help if no action but 'config.default_help' is true." do
        expected, serr = capture_sio { @app.run("-h") }
        ok {serr} == ""
        ok {expected} =~ /^Usage:/
        #
        @config.default_help = true
        sout, serr = capture_sio { @app.run() }
        ok {serr} == ""
        ok {sout} == expected
      end

      spec "[!n60o0] reports error when action nor default action not specified." do
        @config.default_action = nil
        pr = proc { @app.run() }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "testapp: Action name required (run `testapp -h` for details).")
      end

      spec "[!hk6iu] unsets $cmdapp_config at end." do
        bkup = $cmdapp_config
        $cmdapp_config = nil
        begin
          sout, serr = capture_sio { @app.run("check-config") }
          ok {sout} == "$cmdapp_config.class=Benry::CmdApp::Config\n"
          ok {$cmdapp_config} == nil
        ensure
          $cmdapp_config = bkup
        end
      end

      spec "[!wv22u] calls teardown method at end of running action." do
        def @app.do_teardown(*args)
          @_args = args
        end
        ok {@app.instance_variable_get('@_args')} == nil
        sout, serr = capture_sio { @app.run("check-config") }
        ok {@app.instance_variable_get('@_args')} == [nil]
      end

      spec "[!dhba4] calls teardown method even if exception raised." do
        def @app.do_teardown(*args)
          @_args = args
        end
        ok {@app.instance_variable_get('@_args')} == nil
        pr = proc { @app.run("test-exception1") }
        ok {pr}.raise?(ZeroDivisionError) do |exc|
          ok {@app.instance_variable_get('@_args')} == [exc]
        end
      end

    end


    topic '#help_message()' do

      spec "[!owg9y] returns help message." do
        msg = @app.help_message()
        msg = uncolorize(msg)
        ok {msg}.start_with?(<<END)
TestApp (1.0.0) -- test app

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message
  -V, --version      : print version
  -a, --all          : list all actions including private (hidden) ones
  -D, --debug        : debug mode (set $DEBUG_MODE to true)

Actions:
END
      end

    end


    topic '#do_create_global_option_schema()' do

      spec "[!u3zdg] creates global option schema object according to config." do
        config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                           option_all: true, option_quiet: true)
        app = Benry::CmdApp::Application.new(config)
        x = app.__send__(:do_create_global_option_schema, config)
        ok {x}.is_a?(Benry::CmdApp::AppOptionSchema)
        ok {x.find_long_option("all")}     != nil
        ok {x.find_long_option("quiet")}   != nil
        ok {x.find_long_option("verbose")} == nil
        ok {x.find_long_option("debug")}   == nil
      end

    end


    topic '#do_create_help_message_builder()' do

      spec "[!pk5da] creates help message builder object." do
        config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                           option_all: true, option_quiet: true)
        app = Benry::CmdApp::Application.new(config)
        x = app.__send__(:do_create_help_message_builder, config, app.schema)
        ok {x}.is_a?(Benry::CmdApp::AppHelpBuilder)
      end

    end


    topic '#do_parse_global_options()' do

      spec "[!5br6t] parses only global options and not parse action options." do
        sout, serr = capture_sio { @app.run("test-globalopt", "--help") }
        ok {serr} == ""
        ok {sout} == "help=true\n"
      end

      spec "[!kklah] raises InvalidOptionError if global option value is invalid." do
        pr = proc { @app.run("-hoge", "test-globalopt") }
        ok {pr}.raise?(Benry::CmdApp::InvalidOptionError, "-o: Unknown option.")
      end

    end


    topic '#do_toggle_global_switches()' do

      before do
        @config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                            option_verbose: true,
                                            option_quiet: true,
                                            option_debug: true,
                                            option_color: true,
                                            option_trace: true)
        @app = Benry::CmdApp::Application.new(@config)
      end

      spec "[!j6u5x] sets $QUIET_MODE to false if '-v' or '--verbose' specified." do
        bkup = $QUIET_MODE
        begin
          ["-v", "--verbose"].each do |opt|
            $QUIET_MODE = true
            sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
            ok {serr} == ""
            ok {$QUIET_MODE} == false
          end
        ensure
          $QUIET_MODE = bkup
        end
      end

      spec "[!p1l1i] sets $QUIET_MODE to true if '-q' or '--quiet' specified." do
        bkup = $QUIET_MODE
        begin
          ["-q", "--quiet"].each do |opt|
            $QUIET_MODE = nil
            sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
            ok {serr} == ""
            ok {$QUIET_MODE} == true
          end
        ensure
          $QUIET_MODE = bkup
        end
      end

      spec "[!2zvf9] sets $COLOR_MODE to true/false according to '--color' option." do
        bkup = $COLOR_MODE
        begin
          [["--color", true], ["--color=on", true], ["--color=off", false]].each do |opt, val|
            $COLOR_MODE = !val
            sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
            ok {serr} == ""
            ok {$COLOR_MODE} == val
          end
        ensure
          $COLOR_MODE = bkup
        end
      end

      spec "[!ywl1a] sets $DEBUG_MODE to true if '-D' or '--debug' specified." do
        bkup = $DEBUG_MODE
        begin
          ["-D", "--debug"].each do |opt|
            $DEBUG_MODE = false
            sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
            ok {serr} == ""
            ok {sout} == "$DEBUG_MODE=true\n"
            ok {$DEBUG_MODE} == true
          end
        ensure
          $DEBUG_MODE = bkup
        end
      end

      spec "[!8trmz] sets $TRACE_MODE to true if '-T' or '--trace' specified." do
        bkup = $TRACE_MODE
        begin
          ["-T", "--trace"].each do |opt|
            $TRACE_MODE = false
            sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
            ok {serr} == ""
            ok {$TRACE_MODE} == true
          end
        ensure
          $TRACE_MODE = bkup
        end
      end

    end


    topic '#do_handle_global_options()' do

      def new_app()
        kws = {
          app_name:       "TestApp",
          app_command:    "testapp",
          option_all:     true,
          option_verbose: true,
          option_quiet:   true,
          option_color:   true,
          option_debug:   true,
          default_action: nil,
        }
        config = Benry::CmdApp::Config.new("test app", "1.0.0", **kws)
        return Benry::CmdApp::Application.new(config)
      end

      spec "[!xvj6s] prints help message if '-h' or '--help' specified." do
        expected = <<"END"
TestApp (1.0.0) -- test app

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message
  -V, --version      : print version
  -a, --all          : list all actions including private (hidden) ones
  -v, --verbose      : verbose mode
  -q, --quiet        : quiet mode
  --color[=<on|off>] : enable/disable color
  -D, --debug        : debug mode (set $DEBUG_MODE to true)

Actions:
END
        app = new_app()
        ["-h", "--help"].each do |opt|
          sout, serr = capture_sio { app.run(opt) }
          ok {serr} == ""
          ok {sout}.start_with?(expected)
        end
      end

      spec "[!lpoz7] prints help message of action if action name specified with help option." do
        expected = <<"END"
testapp sayhello -- print greeting message

Usage:
  $ testapp sayhello [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
END
        app = new_app()
        ["-h", "--help"].each do |opt|
          sout, serr = capture_sio { app.run(opt, "sayhello") }
          ok {serr} == ""
          ok {sout} == expected
        end
      end

      spec "[!fslsy] prints version if '-V' or '--version' specified." do
        app = new_app()
        ["-V", "--version"].each do |opt|
          sout, serr = capture_sio { app.run(opt, "xxx") }
          ok {serr} == ""
          ok {sout} == "1.0.0\n"
        end
      end

    end


    topic '#do_callback()' do

      def new_app(&block)
        @config = Benry::CmdApp::Config.new("test app", "1.0.0")
        return Benry::CmdApp::Application.new(@config, &block)
      end

      spec "[!xwo0v] calls callback if provided." do
        called = nil
        app = new_app do |args, global_opts, config|
          called = [args.dup, global_opts, config]
        end
        ok {called} == nil
        without_tty { app.run("sayhello") }
        ok {called} != nil
        ok {called[0]} == ["sayhello"]
        ok {called[1]} == {}
        ok {called[2]} == @config
      end

      spec "[!lljs1] calls callback only once." do
        n = 0
        app = new_app do |args, global_opts, config|
          n += 1
        end
        ok {n} == 0
        without_tty { app.run("sayhello") }
        ok {n} == 1
        without_tty { app.run("sayhello") }
        ok {n} == 1
        without_tty { app.run("sayhello") }
        ok {n} == 1
      end

    end


    topic '#do_find_action()' do

      spec "[!bm8np] returns action metadata." do
        x = @app.__send__(:do_find_action, ["sayhello"], {})
        ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
        ok {x.name} == "sayhello"
      end

      spec "[!vl0zr] error when action not found." do
        pr = proc { @app.__send__(:do_find_action, ["hiyo"], {}) }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "hiyo: Unknown action.")
      end

      spec "[!gucj7] if no action specified, finds default action instead." do
        @app.config.default_action = "sayhello"
        x = @app.__send__(:do_find_action, [], {})
        ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
        ok {x.name} == "sayhello"
      end

      spec "[!388rs] error when default action not found." do
        @app.config.default_action = "hiyo"
        pr = proc { @app.__send__(:do_find_action, [], {}) }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "hiyo: Unknown default action.")
      end

      spec "[!drmls] returns nil if no action specified but 'config.default_help' is set." do
        @app.config.default_action = nil
        @app.config.default_help = true
        x = @app.__send__(:do_find_action, [], {})
        ok {x} == nil
      end

      spec "[!hs589] error when action nor default action not specified." do
        @app.config.default_action = nil
        @app.config.default_help = false
        pr = proc { @app.__send__(:do_find_action, [], {}) }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "testapp: Action name required (run `testapp -h` for details).")
      end

    end


    topic '#do_run_action()' do

      spec "[!62gv9] parses action options even if specified after args." do
        sout, serr = capture_sio { @app.run("sayhello", "Alice", "-l", "it") }
        ok {serr} == ""
        ok {sout} == "Ciao, Alice!\n"
      end

      spec "[!6mlol] reports error if action requries argument but nothing specified." do
        pr = proc { @app.run("test-arity1") }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "test-arity1: Argument required.")
      end

      spec "[!72jla] reports error if action requires N args but specified less than N args." do
        pr = proc { @app.run("test-arity1", "foo") }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "test-arity1: Too less arguments (at least 2).")
      end

      spec "[!zawxe] reports error if action requires N args but specified over than N args." do
        pr = proc { @app.run("test-arity1", "foo", "bar", "baz", "boo") }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "test-arity1: Too much arguments (at most 3).")
      end

      spec "[!y97o3] action can take any much args if action has variable arg." do
        pr = proc {
          capture_sio { @app.run("test-arity2", "foo", "bar", "baz", "boo") }
        }
        ok {pr}.NOT.raise?(Exception)
      end

      spec "[!cf45e] runs action with arguments and options." do
        sout, serr = capture_sio { @app.run("sayhello", "-l", "it", "Bob") }
        ok {serr} == ""
        ok {sout} == "Ciao, Bob!\n"
      end

      spec "[!tsal4] detects looped action." do
        pr = proc { @app.run("test-loop1") }
        ok {pr}.raise?(Benry::CmdApp::LoopedActionError,
                       "test-loop1: Action loop detected.")
      end

    end


    topic '#do_print_help_message()' do

      spec "[!eabis] prints help message of action if action name provided." do
        sout, serr = capture_sio { @app.run("-h", "sayhello") }
        ok {serr} == ""
        ok {sout} == <<'END'
testapp sayhello -- print greeting message

Usage:
  $ testapp sayhello [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
END
      end

      spec "[!cgxkb] error if action for help option not found." do
        ["-h", "--help"].each do |opt|
          pr = proc { @app.run(opt, "xhello") }
          ok {pr}.raise?(Benry::CmdApp::CommandError,
                         "xhello: Action not found.")
        end
      end

      spec "[!nv0x3] prints help message of command if action name not provided." do
        sout, serr = capture_sio { @app.run("-h") }
        ok {serr} == ""
        ok {sout}.start_with?(<<'END')
TestApp (1.0.0) -- test app

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message
  -V, --version      : print version
  -a, --all          : list all actions including private (hidden) ones
  -D, --debug        : debug mode (set $DEBUG_MODE to true)

Actions:
END
      end

      spec "[!4qs7y] shows private (hidden) actions if '--all' option specified." do
        class HiddenTest < Benry::CmdApp::ActionScope
          private
          @action.("hidden test")
          @option.(:_trace, "-T", "enable tracing")
          def hidden1(_trace: false)
          end
        end
        #
        ok {_run_app("-h", "--all")}  =~ /^  hidden1 +: hidden test$/
        ok {_run_app("--help", "-a")} =~ /^  hidden1 +: hidden test$/
        ok {_run_app("-h")}           !~ /^  hidden1 +: hidden test$/
        #
        ok {_run_app("-ha", "hidden1")}         =~ /^  -T +: enable tracing$/
        ok {_run_app("-h", "--all", "hidden1")} =~ /^  -T +: enable tracing$/
        ok {_run_app("--help", "hidden1")}      !~ /^  -T +: enable tracing$/
      end

      spec "[!l4d6n] `all` flag should be true or false, not nil." do
        config = Benry::CmdApp::Config.new("test app", "1.0.0", option_all: true)
        app = Benry::CmdApp::Application.new(config)
        def app.help_message(all)
          @_all_ = all
          super
        end
        msg = without_tty { app.run("-h") }
        ok {app.instance_variable_get('@_all_')} != nil
        ok {app.instance_variable_get('@_all_')} == false
        #
        msg = without_tty { app.run("-ha") }
        ok {app.instance_variable_get('@_all_')} != nil
        ok {app.instance_variable_get('@_all_')} == true
      end

      spec "[!efaws] prints colorized help message when stdout is a tty." do
        sout, serr = capture_sio(tty: true) { @app.run("-h") }
        ok {serr} == ""
        ok {sout}.include?(<<"END")
\e[34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] [<action> [<arguments>...]]
END
      ok {sout}.include?(<<"END")
\e[34mOptions:\e[0m
  \e[1m-h, --help        \e[0m : print help message
  \e[1m-V, --version     \e[0m : print version
END
      ok {sout}.include?(<<"END")
\e[34mActions:\e[0m
END
      end

      spec "[!9vdy1] prints non-colorized help message when stdout is not a tty." do
        sout, serr = capture_sio(tty: false) { @app.run("-h") }
        ok {serr} == ""
        ok {sout}.include?(<<"END")
Usage:
  $ testapp [<options>] [<action> [<arguments>...]]
END
      ok {sout}.include?(<<"END")
Options:
  -h, --help         : print help message
  -V, --version      : print version
END
      ok {sout}.include?(<<"END")
Actions:
END
      end

      spec "[!gsdcu] prints colorized help message when '--color[=on]' specified." do
        @config.option_color = true
        app = Benry::CmdApp::Application.new(@config)
        bkup = $COLOR_MODE
        begin
          sout, serr = capture_sio(tty: false) { app.run("-h", "--color") }
          ok {serr} == ""
          ok {sout}.include?(<<"END")
\e[34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] [<action> [<arguments>...]]
END
          ok {sout}.include?(<<"END")
\e[34mOptions:\e[0m
  \e[1m-h, --help        \e[0m : print help message
  \e[1m-V, --version     \e[0m : print version
END
          ok {sout}.include?(<<"END")
\e[34mActions:\e[0m
END
        ensure
          $COLOR_MODE = bkup
        end
      end

      spec "[!be8y2] prints non-colorized help message when '--color=off' specified." do
        @config.option_color = true
        app = Benry::CmdApp::Application.new(@config)
        bkup = $COLOR_MODE
        begin
          sout, serr = capture_sio(tty: true) { app.run("-h", "--color=off") }
          ok {serr} == ""
          ok {sout}.include?(<<"END")
Usage:
  $ testapp [<options>] [<action> [<arguments>...]]
END
          ok {sout}.include?(<<"END")
Options:
  -h, --help         : print help message
  -V, --version      : print version
END
          ok {sout}.include?(<<"END")
Actions:
END
        ensure
          $COLOR_MODE = bkup
        end
      end

    end


    topic '#do_validate_actions()' do

      spec "[!6xhvt] reports warning at end of help message." do
        class ValidateActionTest1 < Benry::CmdApp::ActionScope
          prefix "validate1", alias_of: :test
          @action.("test")
          def test1(); end
        end
        @app.config.default_help = true
        begin
          [["-h"], []].each do |args|
            sout, serr = capture_sio { @app.run(*args) }
            ok {serr} == <<'END'

** [warning] in 'ValidateActionTest1' class, `alias_of: :test` specified but corresponding action not exist.
END
          end
        ensure
          ValidateActionTest1.class_eval { @__aliasof__ = nil }
        end
      end

      spec "[!iy241] reports warning if `alias_of:` specified in action class but corresponding action not exist." do
        class ValidateActionTest2 < Benry::CmdApp::ActionScope
          prefix "validate2", alias_of: :test2
          @action.("test")
          def test(); end
        end
        begin
          sout, serr = capture_sio { @app.__send__(:do_validate_actions, [], {}) }
          ok {serr} == <<'END'

** [warning] in 'ValidateActionTest2' class, `alias_of: :test2` specified but corresponding action not exist.
END
        ensure
          ValidateActionTest2.class_eval { @__aliasof__ = nil }
        end
      end

      spec "[!h7lon] reports warning if `action:` specified in action class but corresponding action not exist." do
        class ValidateActionTest3 < Benry::CmdApp::ActionScope
          prefix "validate3", action: :test3
          @action.("test")
          def test(); end
        end
        begin
          sout, serr = capture_sio { @app.__send__(:do_validate_actions, [], {}) }
          ok {serr} == <<'END'

** [warning] in 'ValidateActionTest3' class, `action: :test3` specified but corresponding action not exist.
END
        ensure
          ValidateActionTest3.class_eval { @__default__ = nil }
        end
      end

    end


    topic '#do_print_candidates()' do

      spec "[!0e8vt] prints candidate action names including prefix name without tailing ':'." do
        class CandidateTest2 < Benry::CmdApp::ActionScope
          prefix "candi:date2", action: :eee
          @action.("test1")
          def ddd(); end
          @action.("test2")
          def ccc(); end
          @action.("test3")
          def eee(); end
        end
        sout, serr = capture_sio do
          @app.__send__(:do_print_candidates, ["candi:date2:"], {})
        end
        ok {serr} == ""
        ok {sout} == <<"END"
Actions:
  candi:date2        : test3
  candi:date2:ccc    : test2
  candi:date2:ddd    : test1
END
      end

      spec "[!85i5m] candidate actions should include alias names." do
        class CandidateTest3 < Benry::CmdApp::ActionScope
          prefix "candi:date3", action: :ggg
          @action.("test1")
          def hhh(); end
          @action.("test2")
          def fff(); end
          @action.("test3")
          def ggg(); end
        end
        Benry::CmdApp.action_alias("pupu", "candi:date3:fff")
        Benry::CmdApp.action_alias("popo", "candi:date3:fff")
        Benry::CmdApp.action_alias("candi:date3:xxx", "candi:date3:hhh")
        sout, serr = capture_sio do
          @app.__send__(:do_print_candidates, ["candi:date3:"], {})
        end
        ok {serr} == ""
        ok {sout} == <<"END"
Actions:
  candi:date3        : test3
  candi:date3:fff    : test2
                       (alias: pupu, popo)
  candi:date3:hhh    : test1
                       (alias: candi:date3:xxx)
  candi:date3:xxx    : alias of 'candi:date3:hhh' action
END
      end

      spec "[!i2azi] raises error when no candidate actions found." do
        pr = proc do
          @app.__send__(:do_print_candidates, ["candi:date9:"], {})
        end
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "No actions starting with 'candi:date9:'.")
      end

      spec "[!k3lw0] private (hidden) action should not be printed as candidates." do
        class CandidateTest4 < Benry::CmdApp::ActionScope
          prefix "candi:date4"
          @action.("test1")
          def kkk(); end
          private
          @action.("test2")
          def iii(); end
          public
          @action.("test3")
          def jjj(); end
        end
        sout, serr = capture_sio do
          @app.__send__(:do_print_candidates, ["candi:date4:"], {})
        end
        ok {serr} == ""
        ok {sout} == <<"END"
Actions:
  candi:date4:jjj    : test3
  candi:date4:kkk    : test1
END
      end

      spec "[!j4b54] shows candidates in strong format if important." do
        class CandidateTest6 < Benry::CmdApp::ActionScope
          prefix "candi:date6"
          @action.("test1")
          def t1(); end
          @action.("test2", important: true)
          def t2(); end
        end
        Benry::CmdApp.action_alias("candi:date6", "candi:date6:t2")
        sout, serr = capture_sio(tty: true) do
          @app.__send__(:do_print_candidates, ["candi:date6:"], {})
        end
        ok {serr} == ""
        ok {sout} == <<END
\e[34mActions:\e[0m
  \e[1m\e[4mcandi:date6\e[0m       \e[0m : alias of 'candi:date6:t2' action
  \e[1mcandi:date6:t1    \e[0m : test1
  \e[1m\e[4mcandi:date6:t2\e[0m    \e[0m : test2
                       (alias: candi:date6)
END
      end

      spec "[!q3819] shows candidates in weak format if not important." do
        class CandidateTest7 < Benry::CmdApp::ActionScope
          prefix "candi:date7"
          @action.("test1")
          def t1(); end
          @action.("test2", important: false)
          def t2(); end
        end
        Benry::CmdApp.action_alias("candi:date7", "candi:date7:t2")
        sout, serr = capture_sio(tty: true) do
          @app.__send__(:do_print_candidates, ["candi:date7:"], {})
        end
        ok {serr} == ""
        ok {sout} == <<END
\e[34mActions:\e[0m
  \e[1m\e[2mcandi:date7\e[0m       \e[0m : alias of 'candi:date7:t2' action
  \e[1mcandi:date7:t1    \e[0m : test1
  \e[1m\e[2mcandi:date7:t2\e[0m    \e[0m : test2
                       (alias: candi:date7)
END
      end

    end


    topic '#do_setup()' do

      spec "[!pkio4] sets config object to '$cmdapp_config'." do
        $cmdapp_config = nil
        @app.__send__(:do_setup,)
        ok {$cmdapp_config} != nil
        ok {$cmdapp_config} == @app.config
      end

      spec "[!qwjjv] sets application object to '$cmdapp_application'." do
        $cmdapp_application = nil
        @app.__send__(:do_setup,)
        ok {$cmdapp_application} != nil
        ok {$cmdapp_application} == @app
      end

      spec "[!kqfn1] remove built-in 'help' action if `config.help_action == false`." do
        ameta = Benry::CmdApp::INDEX.get_action("help")
        ok {Benry::CmdApp::INDEX.action_exist?("help")} == true
        begin
          @config.help_action = false
          @app.__send__(:do_setup,)
          ok {Benry::CmdApp::INDEX.action_exist?("help")} == false
        ensure
          Benry::CmdApp::INDEX.register_action("help", ameta)
        end
      end

    end


    topic '#do_teardown()' do

      spec "[!zxeo7] clears '$cmdapp_config'." do
        $cmdapp_config = "AAA"
        @app.__send__(:do_teardown, nil)
        ok {$cmdapp_config} == nil
      end

      spec "[!ufm1d] clears '$cmdapp_application'." do
        $cmdapp_application = @app
        @app.__send__(:do_teardown, nil)
        ok {$cmdapp_application} == nil
      end

    end


  end


end
