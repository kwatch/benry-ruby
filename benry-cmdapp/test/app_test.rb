# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative 'shared'


Oktest.scope do


  topic Benry::CmdApp::Application do

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.2.3", app_command: "testapp")
      @app = Benry::CmdApp::Application.new(@config)
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

        spec "[!lhlff] catches error if BaseError raised or `should_rescue?()` returns true." do
          pr = proc { @app.main(["testerr1"]) }
          ok {pr}.raise?(ZeroDivisionError)
          #
          r = recorder()
          r.fake_method(@app, :should_rescue? => true)
          sout, serr = capture_sio(tty: true) do
            pr = proc { @app.main(["testerr1"]) }
            ok {pr}.NOT.raise?(ZeroDivisionError)
          end
          ok {sout} == ""
          ok {serr} =~ /\A\e\[31m\[ERROR\]\e\[0m divided by 0$/
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


    topic '#handle_action()' do

      case_when "[!3qw3p] when no arguments specified..." do

        spec "[!zl9em] lists actions if default action is not set." do
          sout, serr = capture_sio { @app.run() }
          ok {sout} =~ /\AActions:\n/
          ok {sout} =~ /^  hello +: greeting message$/
          ok {serr} == ""
        end

        spec "[!89hqb] lists all actions including hidden ones if `-a` or `--all` specified." do
          sout, serr = capture_sio { @app.run() }
          ok {sout} !~ /^  debuginfo/
          sout, serr = capture_sio { @app.run("-a") }
          ok {sout} =~ /^  debuginfo +: hidden action$/
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
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`
END
        end

        spec "[!g0k1g] lists all actions including hidden ones if `-a` or `--all` specified." do
          sout, serr = capture_sio { @app.run("-a", "git:") }
          ok {sout} == <<END
Actions:
  git:correct        : same as `git commit --amend`
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`
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
  -l, --lang=<lang>  : language name (en/fr/it)
END
      end

      spec "[!d6veb] returns application help message if action name is not specified." do
        ret = @app.render_help_message(nil)
        ok {ret} =~ /^\e\[1;34mUsage:\e\[0m$/
        ok {ret} =~ /^\e\[1;34mOptions:\e\[0m$/
        ok {ret} =~ /^\e\[1;34mActions:\e\[0m$/
      end

      spec "[!tf2wp] includes hidden actions and options into help message if `all: true` passed." do
        rexp1 = /^\e\[2m      --debug        : debug mode\e\[0m/
        rexp2 = /^\e\[2m  debuginfo          : hidden action\e\[0m/
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

      spec "[!510eb] sets `$COLOR_MODE` according to global option." do
        bkup = $COLOR_MODE
        at_end { $COLOR_MODE = bkup }
        $COLOR_MODE = nil
        #
        opts = {color: true}
        @app.instance_eval { toggle_global_options(opts) }
        ok {$COLOR_MODE} == true
        #
        opts = {color: false}
        @app.instance_eval { toggle_global_options(opts) }
        ok {$COLOR_MODE} == false
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

      spec "[!dply7] sets `$DRYRUN_MODE` according to global option." do
        ok {$DRYRUN_MODE} == nil
        at_end { $DRYRUN_MODE = nil }
        #
        opts = {dryrun: true}
        @app.instance_eval { toggle_global_options(opts) }
        ok {$DRYRUN_MODE} == true
      end

    end


    topic '#handle_global_options()' do

      spec "[!366kv] prints help message if global option `-h, --help` specified." do
        opts = {help: true}
        sout, serr = capture_sio do
          @app.instance_eval { handle_global_options(opts, []) }
        end
        ok {sout} =~ /^Usage:/
        ok {sout} =~ /^Options:/
        ok {sout} =~ /^Actions:/
      end

      spec "[!7mapy] includes hidden actions into help message if `-a, --all` specified." do
        rexp1 = /^      --debug        : debug mode$/
        rexp2 = /^  debuginfo          : hidden action$/
        #
        opts = {help: true}
        sout, serr = capture_sio do
          @app.instance_eval { handle_global_options(opts, []) }
        end
        ok {sout} !~ rexp1
        ok {sout} !~ rexp2
        #
        opts = {help: true, all: true}
        sout, serr = capture_sio do
          @app.instance_eval { handle_global_options(opts, []) }
        end
        ok {sout} =~ rexp1
        ok {sout} =~ rexp2
      end

      spec "[!dkjw8] prints version number if global option `-V, --version` specified." do
        opts = {version: true}
        sout, serr = capture_sio do
          @app.instance_eval { handle_global_options(opts, []) }
        end
        ok {sout} == "1.2.3\n"
      end

      spec "[!hj4hf] prints action and alias list if global option `-l, --list` specified." do
        opts = {list: true}
        sout, serr = capture_sio(tty: true) do
          @app.instance_eval { handle_global_options(opts, []) }
        end
        ok {sout} =~ /\A\e\[1;34mActions:\e\[0m$/
        ok {sout} =~ /\n\n\e\[1;34mAliases:\e\[0m$/
      end

      spec "[!tyxwo] includes hidden actions into action list if `-a, --all` specified." do
        rexp = /^  debuginfo +: hidden action$/
        #
        opts = {list: true}
        sout, serr = capture_sio do
          @app.instance_eval { handle_global_options(opts, []) }
        end
        ok {sout} !~ rexp
        #
        opts = {list: true, all: true}
        sout, serr = capture_sio do
          @app.instance_eval { handle_global_options(opts, []) }
        end
        ok {sout} =~ rexp
      end

      spec "[!ooiaf] prints topic list if global option '-L <topic>' specified." do
        chead = '\e\[1;34mCategories:\e\[0m'
        data = [
          [/\A\e\[1;34mActions:\e\[0m$/            , ["action" , "actions"  ]],
          [/\A\e\[1;34mAliases:\e\[0m$/            , ["alias"  , "aliases"  ]],
          [/\A\e\[1;34mAbbreviations:\e\[0m$/      , ["abbrev" , "abbrevs"  ]],
          [/\A#{chead} \e\[2m\(depth=0\)\e\[0m$/, ["category" , "categories" ]],
          [/\A#{chead} \e\[2m\(depth=1\)\e\[0m$/, ["category1", "categories1"]],
          [/\A#{chead} \e\[2m\(depth=2\)\e\[0m$/, ["category2", "categories2"]],
          [/\A#{chead} \e\[2m\(depth=3\)\e\[0m$/, ["category3", "categories3"]],
        ]
        data.each do |rexp, topics|
          topics.each do |topic|
            g_opts = {topic: topic}
            sout, serr = capture_sio(tty: true) do
              @app.instance_eval { handle_global_options(g_opts, []) }
            end
            ok {sout} =~ rexp
          end
        end
      end

      spec "[!ymifi] includes hidden actions into topic list if `-a, --all` specified." do
        g_opts = {topic: "action", all: true}
        sout, serr = capture_sio do
          @app.instance_eval { handle_global_options(g_opts, []) }
        end
        ok {sout} =~ /\AActions:$/
        ok {sout} =~ /^  debuginfo          : hidden action$/
      end

      spec "[!k31ry] returns `0` if help or version or actions printed." do
        keys = [:help, :version, :list]
        keys.each do |key|
          ret = nil
          opts = {key => true}
          capture_sio do
            ret = @app.instance_eval { handle_global_options(opts, []) }
          end
          ok {ret} == 0
        end
      end

      spec "[!9agnb] returns `nil` if do nothing." do
        ret = nil
        opts = {color: true, debug: true}
        capture_sio do
          ret = @app.instance_eval { handle_global_options(opts, []) }
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
  -l, --lang=<lang>  : language name (en/fr/it)
END
      end

    end


    topic '#render_application_help()' do

      spec "[!iyxxb] returns application help message." do
        actual = @app.instance_eval { render_application_help() }
        expected = <<"END"
\e[1mtestapp\e[0m \e[2m(1.2.3)\e[0m --- test app

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] <action> [<arguments>...]

\e[1;34mOptions:\e[0m
  -h, --help         : print help message (of action if specified)
  -V, --version      : print version
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too

\e[1;34mActions:\e[0m
END
        ok {actual}.start_with?(expected)
        ok {actual} =~ /^  hello              : greeting message$/
        ok {actual} =~ /^  git:stage          : same as `git add -p`$/
      end

    end


    topic '#render_version()' do

      spec "[!bcp2g] returns version number string." do
        s = @app.instance_eval { render_version() }
        ok {s} == "1.2.3\n"
      end

    end


    topic '#render_item_list()' do

      class FakeAppHelpBuilder < Benry::CmdApp::ApplicationHelpBuilder
        def render_availables_section(include=true, all: false); return nil; end
        def render_candidates_section(prefix, all: false); return nil; end
        def render_categories_section(depth=1, all: false); return nil; end
      end

      def fake_app_help_builder(&b)
        Benry::CmdApp.module_eval do
          remove_const :APPLICATION_HELP_BUILDER_CLASS
          const_set    :APPLICATION_HELP_BUILDER_CLASS, FakeAppHelpBuilder
        end
        yield
      ensure
        Benry::CmdApp.module_eval do
          remove_const :APPLICATION_HELP_BUILDER_CLASS
          const_set    :APPLICATION_HELP_BUILDER_CLASS, Benry::CmdApp::ApplicationHelpBuilder
        end
      end

      case_when "[!tftl5] when prefix is not specified..." do

        spec "[!36vz6] returns action list string if any actions defined." do
          s = @app.instance_eval { render_item_list(nil) }
          ok {s} !~ /\A\e\[1;34mUsage:\e\[0m$/
          ok {s} !~ /\A\e\[1;34mOptions:\e\[0m$/
          ok {s} =~ /\A\e\[1;34mActions:\e\[0m$/
        end

        spec "[!znuy4] raises CommandError if no actions defined." do
          fake_app_help_builder() do
            pr = proc { @app.instance_eval { render_item_list(nil) } }
            ok {pr}.raise?(Benry::CmdApp::CommandError,
                           "No actions defined.")
          end
        end

      end

      case_when "[!jcq4z] when separator is specified..." do

        spec "[!w1j1e] returns top prefix list if ':' specified." do
          s = @app.instance_eval { render_item_list(":") }
          ok {s} !~ /\A\e\[1;34mUsage:\e\[0m$/
          ok {s} !~ /\A\e\[1;34mOptions:\e\[0m$/
          ok {s} !~ /\A\e\[1;34mActions:\e\[0m$/
          ok {s} =~ /\A\e\[1;34mCategories:\e\[0m \e\[2m\(depth=\d+\)\e\[0m$/
          #
          ok {s} !~ /^  hello/
          ok {s} =~ /^  foo: \(\d+\)$/
          ok {s} =~ /^  git: \(\d+\)$/
          ok {s} !~ /^  hello/
          #
          ok {s} =~ /^  giit: \(\d\d\)         : gitt commands$/
          ok {s} !~ /^  giit:branch: \(\d+\)$/
          ok {s} !~ /^  giit:commit: \(\d+\)$/
          ok {s} !~ /^  giit:repo: \(\d+\)$/
          ok {s} !~ /^  giit:staging: \(\d+\)$/
        end

        spec "[!bgput] returns two depth prefix list if '::' specified." do
          s = @app.instance_eval { render_item_list("::") }
          ok {s} !~ /\A\e\[1;34mUsage:\e\[0m$/
          ok {s} !~ /\A\e\[1;34mOptions:\e\[0m$/
          ok {s} !~ /\A\e\[1;34mActions:\e\[0m$/
          ok {s} =~ /\A\e\[1;34mCategories:\e\[0m \e\[2m\(depth=\d+\)\e\[0m$/
          #
          ok {s} =~ /^  foo: \(\d+\)$/
          ok {s} =~ /^  git: \(\d+\)$/
          ok {s} =~ /^  giit: \(\d\)          : gitt commands$/
          ok {s} !~ /^  hello/
          #
          ok {s} =~ /^  giit:branch: \(\d+\)$/
          ok {s} =~ /^  giit:commit: \(\d+\)$/
          ok {s} =~ /^  giit:repo: \(\d+\)$/
          ok {s} =~ /^  giit:staging: \(\d+\)$/
        end

        spec "[!tiihg] raises CommandError if no actions found having prefix." do
          fake_app_help_builder() do
            pr = proc { @app.instance_eval { render_item_list(":") } }
            ok {pr}.raise?(Benry::CmdApp::CommandError,
                           "Prefix of actions not found.")
          end
        end

      end

      case_when "[!xut9o] when prefix is specified..." do

        spec "[!z4dqn] filters action list by prefix if specified." do
          s = @app.instance_eval { render_item_list("git:") }
          ok {s} == <<"END"
\e[1;34mActions:\e[0m
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`
END
        end

        spec "[!1834c] raises CommandError if no actions found with names starting with that prefix." do
          fake_app_help_builder() do
            pr = proc { @app.instance_eval { render_item_list("git:") } }
            ok {pr}.raise?(Benry::CmdApp::CommandError,
                           "No actions found with names starting with 'git:'.")
          end
        end

      end

      case_else "[!xjdrm] else..." do

        spec "[!9r4w9] raises ArgumentError." do
          pr = proc { @app.instance_eval { render_item_list("git") } }
          ok {pr}.raise?(ArgumentError,
                         "\"git\": Invalid value as a prefix.")
        end

      end

    end


    topic '#render_topic_list()' do

      spec "[!uzmml] renders topic list." do
        x = @app.__send__(:render_topic_list, "action")
        ok {x} =~ /\A\e\[1;34mActions:\e\[0m$/
        ok {x} =~ /^  hello              : greeting message$/
        #
        Benry::CmdApp.define_alias("chiaou", ["hello", "-l", "it"])
        x = @app.__send__(:render_topic_list, "alias")
        ok {x} =~ /\A\e\[1;34mAliases:\e\[0m$/
        ok {x} =~ /^  chiaou             : alias for 'hello -l it'$/
        #
        x = @app.__send__(:render_topic_list, "category")
        ok {x} =~ /\A\e\[1;34mCategories:\e\[0m \e\[2m\(depth=0\)\e\[0m$/
        ok {x} =~ /^  git: \(3\)$/
        ok {x} =~ /^  giit: \(\d+\) +: gitt commands$/
        #
        Benry::CmdApp.define_abbrev("g31:", "git:")
        x = @app.__send__(:render_topic_list, "abbrev")
        ok {x} =~ /\A\e\[1;34mAbbreviations:\e\[0m$/
        ok {x} =~ /^  g31: +=>  git:$/
      end

      spec "[!vrzu0] topic 'category1' or 'categories2' is acceptable." do
        x = @app.__send__(:render_topic_list, "category1")
        ok {x} =~ /\A\e\[1;34mCategories:\e\[0m \e\[2m\(depth=1\)\e\[0m$/
        ok {x} =~ /^  git: \(3\)$/
        ok {x} =~ /^  giit: \(\d+\) +: gitt commands$/
        ok {x} !~ /^  giit:branch:/
        ok {x} !~ /^  giit:repo:/
        #
        x = @app.__send__(:render_topic_list, "category2")
        ok {x} =~ /\A\e\[1;34mCategories:\e\[0m \e\[2m\(depth=2\)\e\[0m$/
        ok {x} =~ /^  git: \(3\)$/
        ok {x} =~ /^  giit: \(0\) +: gitt commands$/
        ok {x} =~ /^  giit:branch: \(2\)$/
        ok {x} =~ /^  giit:repo: \(7\)$/
        ok {x} !~ /^  giit:repo:config:/
        ok {x} !~ /^  giit:repo:remote:/
        #
        x = @app.__send__(:render_topic_list, "categories3")
        ok {x} =~ /\A\e\[1;34mCategories:\e\[0m \e\[2m\(depth=3\)\e\[0m$/
        ok {x} =~ /^  git: \(3\)$/
        ok {x} =~ /^  giit: \(0\) +: gitt commands$/
        ok {x} =~ /^  giit:branch: \(2\)$/
        ok {x} =~ /^  giit:repo: \(2\)$/
        ok {x} =~ /^  giit:repo:config: \(3\)$/
        ok {x} =~ /^  giit:repo:remote: \(2\)$/
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
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`
END
      end

    end


    topic '#start_action()' do

      spec "[!vbymd] runs action with args and returns `0`." do
        ret = nil
        sout, serr = capture_sio do
          ret = @app.instance_eval { start_action("hello", ["-l", "it", "Alice"]) }
        end
        ok {ret} == 0
        ok {sout} == "Chao, Alice!\n"
      end

      spec "[!6htva] supports abbreviation of prefix." do
        Benry::CmdApp.define_abbrev("g1:", "git:")
        sout, serr = capture_sio do
          @app.instance_eval do
            start_action("g1:stage", ["."])
            start_action("g1:unstage", [])
          end
        end
        ok {sout} == <<'END'
git add -p .
git reset HEAD
END
      end

    end


    topic '#new_context()' do

      spec "[!9ddcl] creates new context object with config object." do
        x = @app.instance_eval { new_context() }
        ok {x}.is_a?(Benry::CmdApp::ApplicationContext)
        ok {x.instance_variable_get(:@config)} == @config
      end

    end


    topic '#print_str()' do

      spec "[!yiabh] do nothing if str is nil." do
        sout, serr = capture_sio do
          @app.instance_eval { print_str nil }
        end
        ok {sout} == ""
        ok {serr} == ""
      end

      spec "[!6kyv9] prints string as is if color mode is enabled." do
        bkup = $COLOR_MODE; at_end { $COLOR_MODE = bkup }
        $COLOR_MODE = true
        sout, serr = capture_sio do
          @app.instance_eval { print_str("\e[1mHello\e[0m") }
        end
        ok {sout} == "\e[1mHello\e[0m"
      end

      spec "[!lxhvq] deletes escape characters from string and prints it if color mode is disabled." do
        bkup = $COLOR_MODE; at_end { $COLOR_MODE = bkup }
        $COLOR_MODE = false
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


    topic '#skip_backtrace?()' do

      spec "[!r2fmv] ignores backtraces if matched to 'config.backtrace_ignore_rexp'." do
        @config.backtrace_ignore_rexp = /\/foobar\.rb/
        bt1 = "/home/yourname/foobar.rb:123:"
        bt2 = "/home/yourname/blabla.rb:123:"
        _ = self
        @app.instance_eval do
          _.ok {skip_backtrace?(bt1)} == 14
          _.ok {skip_backtrace?(bt2)} == nil
        end
      end

      spec "[!c6f11] not ignore backtraces if 'config.backtrace_ignore_rexp' is not set." do
        @config.backtrace_ignore_rexp = nil
        bt1 = "/home/yourname/foobar.rb:123:"
        bt2 = "/home/yourname/blabla.rb:123:"
        _ = self
        @app.instance_eval do
          _.ok {skip_backtrace?(bt1)} == false
          _.ok {skip_backtrace?(bt2)} == false
        end
      end

    end


    topic '#read_file_as_lines()' do

      spec "[!e9c74] reads file content as an array of line." do
        lines = @app.instance_eval { read_file_as_lines(__FILE__) }
        ok {lines}.is_a?(Array)
        ok {lines[__LINE__ - 2]} == "        ok {lines}.is_a?(Array)\n"
      end

    end


    topic '#should_rescue?()' do

      spec "[!8lwyn] returns trueif exception is a BaseError." do
        x = @app.__send__(:should_rescue?, Benry::CmdApp::DefinitionError.new)
        ok {x} == true
        x = @app.__send__(:should_rescue?, RuntimeError.new)
        ok {x} == false
      end

    end


  end


  topic Benry::CmdApp::GlobalOptionSchema do

    def new_schema(config)
      return Benry::CmdApp::GlobalOptionSchema.new(config)
    end


    topic '#initialize()' do

      spec "[!ppcvp] adds options according to config object." do
        config = Benry::CmdApp::Config.new("sample app", "1.2.3")
        schema = new_schema(config)
        ok {schema.get(:help)}    != nil
        ok {schema.get(:version)} != nil
        ok {schema.get(:list)}    != nil
        ok {schema.get(:all)}     != nil
        ok {schema.get(:verbose)} == nil
        ok {schema.get(:quiet)}   == nil
        ok {schema.get(:color)}   == nil
        ok {schema.get(:debug)}   != nil
        ok {schema.get(:debug)}.hidden?
        ok {schema.to_s} == <<"END"
  -h, --help     : print help message (of action if specified)
  -V, --version  : print version
  -l, --list     : list actions and aliases
  -a, --all      : list hidden actions/options, too
END
        ok {schema.get(:trace)}   == nil
        #
        config.option_help   = false
        config.option_version = false
        config.option_list   = false
        config.option_all    = false
        config.option_verbose = true
        config.option_quiet  = true
        config.option_color  = true
        config.option_debug  = true
        config.option_trace  = true
        #
        schema = new_schema(config)
        ok {schema.get(:help)}    == nil
        ok {schema.get(:version)} == nil
        ok {schema.get(:list)}    == nil
        ok {schema.get(:all)}     == nil
        ok {schema.get(:verbose)} != nil
        ok {schema.get(:quiet)}   != nil
        ok {schema.get(:color)}   != nil
        ok {schema.get(:trace)}   != nil
        ok {schema.get(:debug)}.NOT.hidden?
      end

      spec "[!doj0k] if config option is `:hidden`, makes option as hidden." do
        config = Benry::CmdApp::Config.new("sample app", "1.2.3")
        config.option_help    = :hidden
        config.option_version = :hidden
        config.option_list    = :hidden
        config.option_topic   = :hidden
        config.option_all     = :hidden
        config.option_verbose = :hidden
        config.option_quiet   = :hidden
        config.option_color   = :hidden
        config.option_debug   = :hidden
        config.option_trace   = :hidden
        #
        schema = new_schema(config)
        ok {schema.get(:help   ).hidden?} == true
        ok {schema.get(:version).hidden?} == true
        ok {schema.get(:list   ).hidden?} == true
        ok {schema.get(:topic  ).hidden?} == true
        ok {schema.get(:all    ).hidden?} == true
        ok {schema.get(:verbose).hidden?} == true
        ok {schema.get(:quiet  ).hidden?} == true
        ok {schema.get(:color  ).hidden?} == true
        ok {schema.get(:debug  ).hidden?} == true
        ok {schema.get(:trace  ).hidden?} == true
        #
        ok {schema.option_help()} == ""
        ok {schema.option_help(all: true)} == <<'END'
      --help           : print help message (of action if specified)
      --version        : print version
      --list           : list actions and aliases
  -L <topic>           : topic list (actions|aliases|categories|abbrevs)
      --all            : list hidden actions/options, too
      --verbose        : verbose mode
      --quiet          : quiet mode
  --color[=<on|off>]   : color mode
      --debug          : debug mode
      --trace          : trace mode
END
      end

      spec "[!umjw5] add nothing if config is nil." do
        schema = new_schema(nil)
        ok {schema}.empty?
      end

    end


    topic '#reorder_options(*keys)' do

      spec "[!2cp9s] sorts options in order of keys specified." do
        config = Benry::CmdApp::Config.new("sample app", "1.2.3", option_debug: true)
        schema = new_schema(config)
        ok {schema.to_s} == <<'END'
  -h, --help     : print help message (of action if specified)
  -V, --version  : print version
  -l, --list     : list actions and aliases
  -a, --all      : list hidden actions/options, too
      --debug    : debug mode
END
        #
        schema.reorder_options(:list, :topic, :help, :all, :debug, :version)
        ok {schema.to_s} == <<'END'
  -l, --list     : list actions and aliases
  -h, --help     : print help message (of action if specified)
  -a, --all      : list hidden actions/options, too
      --debug    : debug mode
  -V, --version  : print version
END
      end

      spec "[!xe7e1] moves options which are not included in specified keys to end of option list." do
        config = Benry::CmdApp::Config.new("sample app", "1.2.3", option_debug: true)
        schema = new_schema(config)
        schema.reorder_options(:list, :help)
        ok {schema.to_s} == <<'END'
  -l, --list     : list actions and aliases
  -h, --help     : print help message (of action if specified)
  -V, --version  : print version
  -a, --all      : list hidden actions/options, too
      --debug    : debug mode
END
      end

    end


  end


end
