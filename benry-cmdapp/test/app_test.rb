# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative 'shared'


Oktest.scope do


  topic Benry::CmdApp::Application do

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.2.3", app_command: "testapp")
      @app = Benry::CmdApp::Application.new(@config)
    end


    topic '.new_global_option_schema()' do

      spec "[!b8gj4] creates global option schema." do
        x = Benry::CmdApp::Application.new_global_option_schema(@config)
        ok {x}.is_a?(Benry::CmdApp::OPTION_SCHEMA_CLASS)
      end

    end


    topic '#main()' do

      spec "[!65e9n] returns `0` as status code." do
        ret = nil
        capture_sio { ret = @app.main(["help"]) }
        ok {ret} == 0
      end

      case_when "[!bkbb4] when error raised..." do

        spec "[!k4qov] not catch error if debug mode is enabled." do
          debug_mode = $DEBUG_MODE
          at_end { $DEBUG_MODE = debug_mode }
          pr = proc { @app.main(["--debug", "foobar"]) }
          ok {pr}.raise?(Benry::CmdApp::CommandError, "foobar: Action not found.")
        end

        spec "[!35x5p] prints error into stderr." do
          sout, serr = capture_sio(tty: true) { @app.main(["foobar"]) }
          ok {sout} == ""
          ok {serr} =~ /^\e\[31m\[ERROR\]\e\[0m foobar: Action not found.\n/
        end

        spec "[!z39bh] prints backtrace unless error is a CommandError." do
          sout, serr = capture_sio { @app.main(["testerr2"]) }
          ok {sout} == ""
          ok {serr} =~ /^\[ERROR\] testerr2: Looped action detected.\n/
          ok {serr} =~ /^    From .*:\d+:in /
        end

        spec "[!dzept] returns `1` as status code." do
          ret = nil
          capture_sio { ret = @app.main(["help", "foo"]) }
          ok {ret} == 1
        end

      end

    end


    topic '#run()' do

      spec "[!etbbc] calls setup method at beginning of this method." do
        r = recorder()
        r.record_method(@app, :setup)
        capture_sio { @app.run("help") }
        ok {r[0].name} == :setup
        ok {r[0].args} == []
      end

      spec "[!hguvb] handles global options." do
        sout, serr = capture_sio { @app.run("--version") }
        ok {sout} == "1.2.3\n"
        ok {serr} == ""
        sout, serr = capture_sio { @app.run("--help") }
        ok {sout} =~ /^Usage:\n/
        ok {serr} == ""
      end

      case_when "[!3qw3p] when no arguments specified..." do

        spec "[!zl9em] lists actions if default action is not set." do
          sout, serr = capture_sio { @app.run() }
          ok {sout} =~ /\AActions:\n/
          ok {sout} =~ /^  hello             : greeting message$/
          ok {serr} == ""
        end

        spec "[!89hqb] lists all actions including hidden ones if `-a` or `--all` specified." do
          sout, serr = capture_sio { @app.run() }
          ok {sout} !~ /^  debuginfo/
          sout, serr = capture_sio { @app.run("-a") }
          ok {sout} =~ /^  debuginfo         : hidden action$/
        end

        spec "[!k4xxp] runs default action if it is set." do
          @config.default_action = "hello"
          sout, serr = capture_sio { @app.run() }
          ok {sout} !~ /^\AActions:/
          ok {sout} == "Hello, world!\n"
        end

      end

      case_when "[!xaamy] when prefix specified..." do

        spec "[!7l3fh] lists actions starting with prefix." do
          sout, serr = capture_sio { @app.run("git:") }
          ok {sout} == <<END
Actions:
  git:stage         : same as `git add -p`
  git:staged        : same as `git diff --cached`
  git:unstage       : same as `git reset HEAD`
END
        end

        spec "[!g0k1g] lists all actions including hidden ones if `-a` or `--all` specified." do
          sout, serr = capture_sio { @app.run("-a", "git:") }
          ok {sout} == <<END
Actions:
  git:correct       : same as `git commit --amend`
  git:stage         : same as `git add -p`
  git:staged        : same as `git diff --cached`
  git:unstage       : same as `git reset HEAD`
END
        end

      end

      case_when "[!vphz3] else..." do

        spec "[!bq39a] runs action with arguments." do
          sout, serr = capture_sio { @app.run("hello", "Alice") }
          ok {sout} == "Hello, Alice!\n"
        end

        spec "[!5yd8x] returns 0 when action invoked successfully." do
          ret = nil
          capture_sio { ret = @app.run("hello", "Alice") }
          ok {ret} == 0
        end

        spec "[!pf1d2] calls teardown method at end of this method." do
          r = recorder()
          r.record_method(@app, :teardown)
          capture_sio { @app.run("hello", "Alice") }
          ok {r.length} == 1
          ok {r[0].name} == :teardown
          ok {r[0].args} == []
          #
          begin
            capture_sio { @app.run("testerr1") }
          rescue ZeroDivisionError
            nil
          end
          ok {r.length} == 2
          ok {r[0].name} == :teardown
          ok {r[0].args} == []
        end

      end

    end


    topic '#render_help_message()' do

      spec "[!2oax5] returns action help message if action name is specified." do
        ret = @app.render_help_message("hello")
        ok {ret} == <<"END"
\e[1mtestapp hello\e[0m --- greeting message

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp hello\e[0m [<options>] [<name>]

\e[1;34mOptions:\e[0m
  -l, --lang=<lang> : language name (en/fr/it)
END
      end

      spec "[!d6veb] returns application help message if action name is not specified." do
        ret = @app.render_help_message(nil)
        ok {ret} =~ /^\e\[1;34mUsage:\e\[0m$/
        ok {ret} =~ /^\e\[1;34mOptions:\e\[0m$/
        ok {ret} =~ /^\e\[1;34mActions:\e\[0m$/
      end

      spec "[!tf2wp] includes hidden actions and options into help message if `all: true` passed." do
        rexp1 = /^\e\[2m      --debug       : debug mode\e\[0m/
        rexp2 = /^\e\[2m  debuginfo         : hidden action\e\[0m/
        #
        s = @app.render_help_message(nil, all: true)
        ok {s} =~ rexp1
        ok {s} =~ rexp2
        #
        s = @app.render_help_message(nil, all: false)
        ok {s} !~ rexp1
        ok {s} !~ rexp2
      end

    end


    topic '#setup()' do

      spec "[!6hi1y] stores current application." do
        at_end { Benry::CmdApp._set_current_app(nil) }
        ok {Benry::CmdApp.current_app()} == nil
        @app.__send__(:setup)
        ok {Benry::CmdApp.current_app()} == @app
      end

    end


    topic '#teardown()' do

      spec "[!t44mv] removes current applicatin from data store." do
        at_end { Benry::CmdApp._set_current_app(nil) }
        ok {Benry::CmdApp.current_app()} == nil
        @app.__send__(:setup)
        ok {Benry::CmdApp.current_app()} == @app
      end

    end


    topic '#parse_global_options()' do

      spec "[!9c9r8] parses global options." do
        args = ["-hl", "foo"]
        opts = @app.instance_eval { parse_global_options(args) }
        ok {opts} == {help: true, list: true}
        ok {args} == ["foo"]
      end

    end


    topic '#toggle_global_options()' do

      spec "[!xwcyl] sets `$VERBOSE_MODE` and `$QUIET_MODE` according to global options." do
        at_end { $VERBOSE_MODE = nil; $QUIET_MODE = nil }
        #
        opts = {verbose: true}
        @app.instance_eval { toggle_global_options(opts) }
        ok {$VERBOSE_MODE} == true
        ok {$QUIET_MODE} == false
        #
        opts = {quiet: true}
        @app.instance_eval { toggle_global_options(opts) }
        ok {$VERBOSE_MODE} == false
        ok {$QUIET_MODE} == true
      end

      spec "[!sucqp] sets `$DEBUG_MODE` according to global options." do
        at_end { $DEBUG_MODE = nil }
        opts = {debug: true}
        @app.instance_eval { toggle_global_options(opts) }
        ok {$DEBUG_MODE} == true
      end

      spec "[!510eb] sets `config.color_mode` if global option specified." do
        opts = {color: true}
        @app.instance_eval { toggle_global_options(opts) }
        ok {@config.color_mode} == true
        #
        opts = {color: false}
        @app.instance_eval { toggle_global_options(opts) }
        ok {@config.color_mode} == false
      end

      spec "[!y9fow] sets `config.trace_mode` if global option specified." do
        opts = {trace: true}
        @app.instance_eval { toggle_global_options(opts) }
        ok {@config.trace_mode} == true
        #
        opts = {trace: false}
        @app.instance_eval { toggle_global_options(opts) }
        ok {@config.trace_mode} == false
      end

    end


    topic '#perform_global_options()' do

      spec "[!dkjw8] prints help message if global option `-h, --help` specified." do
        opts = {help: true}
        sout, serr = capture_sio do
          @app.instance_eval { perform_global_options(opts, []) }
        end
        ok {sout} =~ /^Usage:/
        ok {sout} =~ /^Options:/
        ok {sout} =~ /^Actions:/
      end

      spec "[!7mapy] includes hidden actions into help message if `-a, --all` specified." do
        rexp1 = /^      --debug       : debug mode$/
        rexp2 = /^  debuginfo         : hidden action$/
        #
        opts = {help: true}
        sout, serr = capture_sio do
          @app.instance_eval { perform_global_options(opts, []) }
        end
        ok {sout} !~ rexp1
        ok {sout} !~ rexp2
        #
        opts = {help: true, all: true}
        sout, serr = capture_sio do
          @app.instance_eval { perform_global_options(opts, []) }
        end
        ok {sout} =~ rexp1
        ok {sout} =~ rexp2
      end

      spec "[!dkjw8] prints version number if global option `-V, --version` specified." do
        opts = {version: true}
        sout, serr = capture_sio do
          @app.instance_eval { perform_global_options(opts, []) }
        end
        ok {sout} == "1.2.3\n"
      end

      spec "[!hj4hf] prints action list if global option `-l, --list` specified." do
        opts = {list: true}
        sout, serr = capture_sio do
          @app.instance_eval { perform_global_options(opts, []) }
        end
        ok {sout} =~ /\AActions:$/
      end

      spec "[!tyxwo] includes hidden actions into action list if `-a, --all` specified." do
        rexp = /^  debuginfo         : hidden action$/
        #
        opts = {list: true}
        sout, serr = capture_sio do
          @app.instance_eval { perform_global_options(opts, []) }
        end
        ok {sout} !~ rexp
        #
        opts = {list: true, all: true}
        sout, serr = capture_sio do
          @app.instance_eval { perform_global_options(opts, []) }
        end
        ok {sout} =~ rexp
      end

      spec "[!k31ry] returns `0` if help or version or actions printed." do
        keys = [:help, :version, :list]
        keys.each do |key|
          ret = nil
          opts = {key => true}
          capture_sio do
            ret = @app.instance_eval { perform_global_options(opts, []) }
          end
          ok {ret} == 0
        end
      end

      spec "[!9agnb] returns `nil` if do nothing." do
        ret = nil
        opts = {color: true, debug: true}
        capture_sio do
          ret = @app.instance_eval { perform_global_options(opts, []) }
        end
        ok {ret} == nil
      end

    end


    topic '#render_action_help()' do

      spec "[!c510c] returns action help message." do
        s = @app.instance_eval { render_action_help("hello") }
        ok {s} == <<"END"
\e[1mtestapp hello\e[0m --- greeting message

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp hello\e[0m [<options>] [<name>]

\e[1;34mOptions:\e[0m
  -l, --lang=<lang> : language name (en/fr/it)
END
      end

    end


    topic '#render_application_help()' do

      spec "[!iyxxb] returns application help message." do
        actual = @app.instance_eval { render_application_help() }
        expected = <<"END"
\e[1mtestapp\e[0m --- test app

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] <action> [<arguments>...]

\e[1;34mOptions:\e[0m
  -h, --help        : show help message
  -V, --version     : output version
  -l, --list        : list actions
  -a, --all         : list all actions/options including hidden ones

\e[1;34mActions:\e[0m
END
        ok {actual}.start_with?(expected)
        ok {actual} =~ /^  hello             : greeting message$/
        ok {actual} =~ /^  git:stage         : same as `git add -p`$/
      end

    end


    topic '#render_version()' do

      spec "[!bcp2g] returns version number string." do
        s = @app.instance_eval { render_version() }
        ok {s} == "1.2.3\n"
      end

    end


    topic '#render_action_list()' do

      class FakeActionListBuilder < Benry::CmdApp::ActionListBuilder
        def build_action_list(all: false); return nil; end
        def build_action_list_filtered_by(prefix, all: false); return nil; end
        def build_top_prefix_list(all: false); return nil; end
      end

      def fake_action_list_builder(&b)
        Benry::CmdApp.module_eval do
          remove_const :ACTION_LIST_BUILDER_CLASS
          const_set    :ACTION_LIST_BUILDER_CLASS, FakeActionListBuilder
        end
        yield
      ensure
        Benry::CmdApp.module_eval do
          remove_const :ACTION_LIST_BUILDER_CLASS
          const_set    :ACTION_LIST_BUILDER_CLASS, Benry::CmdApp::ActionListBuilder
        end
      end

      case_when "[!tftl5] when prefix is not specified..." do

        spec "[!36vz6] returns action list string if any actions defined." do
          s = @app.instance_eval { render_action_list(nil) }
          ok {s} !~ /\A\e\[1;34mUsage:\e\[0m$/
          ok {s} !~ /\A\e\[1;34mOptions:\e\[0m$/
          ok {s} =~ /\A\e\[1;34mActions:\e\[0m$/
        end

        spec "[!znuy4] raises CommandError if no actions defined." do
          fake_action_list_builder() do
            pr = proc { @app.instance_eval { render_action_list(nil) } }
            ok {pr}.raise?(Benry::CmdApp::CommandError,
                           "No actions defined.")
          end
        end

      end

      case_when "[!jcq4z] when ':' is specified as prefix..." do

        spec "[!w1j1e] returns top prefix list if ':' specified." do
          s = @app.instance_eval { render_action_list(":") }
          ok {s} !~ /\A\e\[1;34mUsage:\e\[0m$/
          ok {s} !~ /\A\e\[1;34mOptions:\e\[0m$/
          ok {s} !~ /\A\e\[1;34mActions:\e\[0m$/
          ok {s} =~ /\A\e\[1;34mTop Prefixes:\e\[0m$/
        end

        spec "[!tiihg] raises CommandError if no actions found having prefix." do
          fake_action_list_builder() do
            pr = proc { @app.instance_eval { render_action_list(":") } }
            ok {pr}.raise?(Benry::CmdApp::CommandError,
                           "Prefix of actions not found.")
          end
        end

      end

      case_when "[!xut9o] when prefix is specified..." do

        spec "[!z4dqn] filters action list by prefix if specified." do
          s = @app.instance_eval { render_action_list("git:") }
          ok {s} == <<"END"
\e[1;34mActions:\e[0m
  git:stage         : same as `git add -p`
  git:staged        : same as `git diff --cached`
  git:unstage       : same as `git reset HEAD`
END
        end

        spec "[!1834c] raises CommandError if no actions found with names starting with that prefix." do
          fake_action_list_builder() do
            pr = proc { @app.instance_eval { render_action_list("git:") } }
            ok {pr}.raise?(Benry::CmdApp::CommandError,
                           "No actions found with names starting with 'git:'.")
          end
        end

      end

      case_else "[!xjdrm] else..." do

        spec "[!9r4w9] raises ArgumentError." do
          pr = proc { @app.instance_eval { render_action_list("git") } }
          ok {pr}.raise?(ArgumentError,
                         "\"git\": Invalid value as a prefix.")
        end

      end

    end


    topic '#handle_blank_action()' do

      spec "[!seba7] prints action list and returns `0`." do
        ret = nil
        sout, serr = capture_sio do
          ret = @app.instance_eval { handle_blank_action() }
        end
        ok {sout} !~ /\AUsage:$/
        ok {sout} !~ /\AOptions:$/
        ok {sout} =~ /\AActions:$/
        ok {ret} == 0
      end

    end


    topic '#handle_prefix()' do

      spec "[!8w301] prints action list starting with prefix and returns `0`." do
        ret = nil
        sout, serr = capture_sio do
          ret = @app.instance_eval { handle_prefix("git:") }
        end
        ok {ret} == 0
        ok {sout} == <<"END"
Actions:
  git:stage         : same as `git add -p`
  git:staged        : same as `git diff --cached`
  git:unstage       : same as `git reset HEAD`
END
      end

    end


    topic '#handle_action()' do

      spec "[!vbymd] runs action with args and returns `0`." do
        ret = nil
        sout, serr = capture_sio do
          ret = @app.instance_eval { handle_action("hello", ["-l", "it", "Alice"]) }
        end
        ok {ret} == 0
        ok {sout} == "Chao, Alice!\n"
      end

    end


    topic '#new_context()' do

      spec "[!9ddcl] creates new context object with config object." do
        x = @app.instance_eval { new_context() }
        ok {x}.is_a?(Benry::CmdApp::ActionContext)
        ok {x.instance_variable_get(:@config)} == @config
      end

    end


    topic '#print_str()' do

      spec "[!6kyv9] prints string as is if color mode is enabled." do
        @config.color_mode = true
        sout, serr = capture_sio do
          @app.instance_eval { print_str("\e[1mHello\e[0m") }
        end
        ok {sout} == "\e[1mHello\e[0m"
      end

      spec "[!lxhvq] deletes escape characters from string and prints it if color mode is disabled." do
        @config.color_mode = false
        sout, serr = capture_sio do
          @app.instance_eval { print_str("\e[1mHello\e[0m") }
        end
        ok {sout} == "Hello"
      end

    end


    topic '#print_error()' do

      fixture(:err) {
        begin
          1/0
        rescue ZeroDivisionError => err
        end
        err
      }

      spec "[!sdbj8] prints exception as error message." do |err|
        sout, serr = capture_sio(tty: true) do
          @app.instance_eval { print_error(err) }
        end
        ok {sout} == ""
        ok {serr} == "\e[31m[ERROR]\e[0m divided by 0\n"
      end

      spec "[!6z0mu] prints colored error message if stderr is a tty." do |err|
        sout, serr = capture_sio(tty: true) do
          @app.instance_eval { print_error(err) }
        end
        ok {sout} == ""
        ok {serr} == "\e[31m[ERROR]\e[0m divided by 0\n"
      end

      spec "[!k1s3o] prints non-colored error message if stderr is not a tty." do |err|
        sout, serr = capture_sio(tty: false) do
          @app.instance_eval { print_error(err) }
        end
        ok {sout} == ""
        ok {serr} == "[ERROR] divided by 0\n"
      end

    end


    topic '#print_backtrace()' do

      fixture(:err) {
        begin
          1/0
        rescue ZeroDivisionError => err
        end
        err
      }

      spec "[!i010e] skips backtrace in `benry/cmdapp.rb`." do |err|
        sout, serr = capture_sio() do
          @app.instance_eval { print_backtrace(err) }
        end
        ok {sout} == ""
        ok {serr} !~ /benry\/cmdapp\.rb/
        ok {serr} =~ /app_test\.rb/
      end

      spec "[!ilaxg] skips backtrace if `#skip_backtrace?()` returns truthy value." do |err|
        sout1, serr1 = capture_sio() do
          @app.instance_eval { print_backtrace(err) }
        end
        ok {serr1} =~ /app_test\.rb/
        #
        r = recorder()
        r.fake_method(@app, :'skip_backtrace?' => true)
        sout2, serr2 = capture_sio() do
          @app.instance_eval { print_backtrace(err) }
        end
        ok {serr2} == ""
      end

      spec "[!5sa5k] prints filename and line number in slant format if stdout is a tty." do |err|
        sout, serr = capture_sio(tty: true) do
          @app.instance_eval { print_backtrace(err) }
        end
        ok {sout} == ""
        ok {serr} =~ /\A    \e\[3mFrom test\/app_test\.rb:\d+:in `\/'\e\[0m/
      end

      spec "[!2sg9r] not to try to read file content if file not found." do |err|
        newbt = [
          "#{__FILE__}:#{__LINE__}:in `foo`",
          "-e:#{__LINE__}:in `bar`",
          "#{__FILE__}:#{__LINE__}:in `baz`",
        ]
        n = __LINE__ - 4   # base lineno
        err.set_backtrace(newbt)
        sout, serr = capture_sio(tty: true) do
          @app.instance_eval { print_backtrace(err) }
        end
        ok {sout} == ""
        ok {serr} == <<"END"
    \e[3mFrom test/app_test.rb:#{n+0}:in `foo`\e[0m
        "\#{__FILE__}:\#{__LINE__}:in `foo`",
    \e[3mFrom -e:#{n+1}:in `bar`\e[0m
    \e[3mFrom test/app_test.rb:#{n+2}:in `baz`\e[0m
        "\#{__FILE__}:\#{__LINE__}:in `baz`",
END
      end

      spec "[!ihizf] prints lines of each backtrace entry." do |err|
        sout, serr = capture_sio(tty: true) do
          @app.instance_eval { print_backtrace(err) }
        end
        ok {sout} == ""
        ok {serr} =~ /^        1\/0\n/
      end

      spec "[!8wzxg] prints backtrace of exception." do |err|
        sout, serr = capture_sio() do
          @app.instance_eval { print_backtrace(err) }
        end
        ok {sout} == ""
        ok {serr} =~ /\A    From test\/app_test\.rb:\d+:in `\/'\n        1\/0\n/
      end

    end


    topic '#read_file_as_lines()' do

      spec "[!e9c74] reads file content as an array of line." do
        lines = @app.instance_eval { read_file_as_lines(__FILE__) }
        ok {lines}.is_a?(Array)
        ok {lines[__LINE__ - 2]} == "        ok {lines}.is_a?(Array)\n"
      end

    end


  end


end
