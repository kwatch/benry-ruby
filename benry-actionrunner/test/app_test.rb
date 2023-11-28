# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative './shared'


Oktest.scope do

  before_all do
    TestHelperModule.setup_all()
  end

  after_all do
    TestHelperModule.teardown_all()
  end


  topic Benry::ActionRunner do

    def new_app()
      config  = Benry::ActionRunner::CONFIG
      gschema = Benry::ActionRunner::GLOBAL_OPTION_SCHEMA
      app     = Benry::ActionRunner::MainApplication.new(config, gschema)
      return app
    end

    before do
      clear_registry()
      @app = new_app()
      @filename = Benry::ActionRunner::DEFAULT_FILENAME
      File.unlink(@filename) if File.exist?(@filename)
    end

    after do
      File.unlink(@filename) if File.exist?(@filename)
    end

    def main(*args)
      sout, serr, status = main!(*args)
      ok {serr} == ""
      ok {status} == 0
      return sout
    end

    def main!(*args)
      status = nil
      sout, serr = capture_sio(tty: true) do
        status = @app.main(args)
      end
      return sout, serr, status
    end

    topic('.main()') {
      spec "[!wmcup] handles '$ACRIONRUNNER_OPTION' value." do
        ENV['ACTIONRUNNER_OPTION'] = "-h -a"
        at_end { ENV['ACTIONRUNNER_OPTION'] = nil }
        sout, serr = capture_sio(tty: true) { Benry::ActionRunner.main(["-l"]) }
        ok {serr} == ""
        ok {sout} =~ /^\e\[1;34mUsage:\e\[0m$/
      end
      spec "[!hujvl] returns status code." do
        status = nil
        sout, serr = capture_sio(tty: true) {
          status = Benry::ActionRunner.main(["-m"])
        }
        ok {status} == 1
        ok {serr} == "\e\[31m[ERROR]\e\[0m -m: Unknown option.\n"
        ok {sout} == ""
        #
        sout, serr = capture_sio(tty: true) {
          status = Benry::ActionRunner.main(["-V"])
        }
        ok {status} == 0
        ok {serr} == ""
        ok {sout} != ""
      end
    }

    topic('#parse_global_options()') {
      spec "[!bpedh] parses `--<name>=<val>` as global variables." do
        main "--g9942=ABC", "-h"
        ok {$g9942} == "ABC"
      end
      spec "[!0tz4j] stops parsing options when any argument found." do
        args = ["-hV", "-a", "help", "-a"]
        @app.instance_eval { parse_global_options(args) }
        ok {args} == ["help", "-a"]
      end
      spec "[!gkp9b] returns global options." do
        args = ["-ha", "--g8839=DDD", "--g7402=EEE", "help"]
        ret = @app.instance_eval { parse_global_options(args) }
        ok {ret} == {:help => true, :all => true}
        gvars = @app.instance_variable_get(:@global_vars)
        ok {gvars} == {"g8839" => "DDD", "g7402" => "EEE"}
      end
    }

    topic('#toggle_global_options()') {
      spec "[!3kdds] global option '-C' sets `$COLOR_mode = false`." do
        ok {$COLOR_MODE} == nil
        at_end { $COLOR_MODE = nil }
        main "-C", "-h"
        ok {$COLOR_MODE} == false
      end
      spec "[!1882x] global option '-u' sets instance var." do
        ok {@app.instance_variable_get(:@flag_search)} == false
        main "-u", "-h"
        ok {@app.instance_variable_get(:@flag_search)} == true
      end
      spec "[!bokge] global option '-w' sets instance var." do
        ok {@app.instance_variable_get(:@flag_chdir)} == false
        main "-w", "-h"
        ok {@app.instance_variable_get(:@flag_chdir)} == true
      end
      spec "[!4sk24] global option '-f' changes filename." do
        ok {@app.instance_variable_get(:@action_file)} == "Actionfile.rb"
        main "-f", "Actions.rb", "-h"
        ok {@app.instance_variable_get(:@action_file)} == "Actions.rb"
      end
      spec "[!9u400] sets `$BENRY_ECHOBACK = true` if option `-v` specified." do
        bkup = $BENRY_ECHOBACK
        at_end { $BENRY_ECHOBACK = bkup }
        $BENRY_ECHOBACK = false
        main "-v", "-h"
        ok {$BENRY_ECHOBACK} == true
      end
      spec "[!jp2mw] sets `$BENRY_ECHOBACK = false` if option `-q` specified." do
        bkup = $BENRY_ECHOBACK
        at_end { $BENRY_ECHOBACK = bkup }
        $BENRY_ECHOBACK = true
        main "-q", "-h"
        ok {$BENRY_ECHOBACK} == false
      end
    }

    topic('#handle_global_options()') {
      spec "[!psrmp] loads action file (if exists) before displaying help message." do
        ok {@filename}.not_exist?
        sout = arun "-h"
        ok {sout}.include?(<<"END")

Actions:
  help               : print help message (of action if specified)

END
        #
        prepare_actionfile("a6913")
        ok {@filename}.file_exist?
        @app = new_app()
        sout = arun "-h"
        ok {sout}.include?(<<"END")

Actions:
  a6913              : test
  help               : print help message (of action if specified)

END
      end
      spec "[!9wfaw] loads action file before listing actions by '-l' or '-L' option." do
        sout = main "-g"
        ok {@filename}.file_exist?
        #
        sout = arun "-l"
        ok {sout}.include?(<<END)
Actions:
  build              : create all
  build:zip          : create zip file
  clean              : delete garbage files (and product files too if '-a')
END
        #
        sout = arun "-L", "actions"
        ok {sout}.include?(<<END)
Actions:
  build              : create all
  build:zip          : create zip file
  clean              : delete garbage files (and product files too if '-a')
END
      end
      spec "[!qanx2] option '-l' and '-L' requires action file." do
        ["-l", "-Lactions"].each do |opt|
          ok {@filename}.not_exist?
          sout, serr, status = arun! opt
          ok {status} != 0
          ok {serr} == "[ERROR] Action file ('Actionfile.rb') not found. Create it by `arun -g` command firstly.\n"
          ok {sout} == ""
        end
      end
      spec "[!7995e] option '-g' generates action file." do
        ok {@filename}.not_exist?
        system "arun", "-g", "-q"
        ok {@filename}.file_exist?
      end
      spec "[!k5nuk] option '-h' or '--help' prints help message." do
        sout = main "-h"
        ok {sout} =~ /^\e\[1;34mUsage:\e\[0m$/
      end
      spec "[!dmxt2] option '-V' prints version number." do
        sout = arun "-V"
        ok {sout} == "#{Benry::ActionRunner::VERSION}\n"
      end
      spec "[!i4qm5] option '-v' sets `$VERBOSE_MODE = true`." do
        bkup = $VERBOSE_MODE
        at_end { $VERBOSE_MODE = bkup }
        $VERBOSE_MODE = nil
        main "-v", "-h"
        ok {$VERBOSE_MODE} == true
      end
      spec "[!5nwnv] option '-q' sets `$QUIET_MODE = true`." do
        bkup = $QUIET_MODE
        at_end { $QUIET_MODE = bkup }
        $QUIET_MODE = nil
        main "-q", "-h"
        ok {$QUIET_MODE} == true
      end
      spec "[!klxkr] option '-c' sets `$COLOR_MODE = true`." do
        bkup = $COLOR_MODE
        at_end { $COLOR_MODE = bkup }
        $COLOR_MODE = nil
        main "-c", "-h"
        ok {$COLOR_MODE} == true
      end
      spec "[!kqbwd] option '-C' sets `$COLOR_MODE = false`." do
        bkup = $COLOR_MODE
        at_end { $COLOR_MODE = bkup }
        $COLOR_MODE = nil
        main "-C", "-h"
        ok {$COLOR_MODE} == false
      end
      spec "[!oce46] option '-D' sets `$DEBUG_MODE = true`." do
        bkup = $DEBUG_MODE
        at_end { $DEBUG_MODE = bkup }
        $DEBUG_MODE = nil
        main "-D", "-h"
        ok {$DEBUG_MODE} == true
      end
      spec "[!mq5ko] option '-T' enables trace mode." do
        prepare_actionfile("a3349")
        sout = main "-T", "a3349", "Alice"
        ok {sout} == <<"END"
\e[33m### enter: a3349\e[0m
Hi, Alice!
\e[33m### exit:  a3349\e[0m
END
      end
      spec "[!jwah3] option '-X' sets `$DRYRUN_MODE = true`." do
        bkup = $DRYRUN_MODE
        at_end { $DRYRUN_MODE = bkup }
        $DRYRUN_MODE = nil
        main "-X", "-h"
        ok {$DRYRUN_MODE} == true
      end
    }

    topic('#handle_action()') {
      spec "[!qdrui] loads action file before performing actions." do
        prepare_actionfile("a6315")
        sout, serr = capture_sio do
          @app.instance_eval { handle_action(["a6315", "Alice"], {}) }
        end
        ok {serr} == ""
        ok {sout} == "Hi, Alice!\n"
      end
      spec "[!4992c] raises error if action specified but action file not exist." do
        pr = proc do
          @app.instance_eval { handle_action(["hello", "Alice"], {}) }
        end
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                      "Action file ('Actionfile.rb') not found. Create it by `arun -g` command firstly.")
      end
    }

    topic('#skip_backtrace?()') {
      spec "[!k8ddu] ignores backtrace of 'actionrunner.rb'." do
        prepare_actionfile("a7452", "run_once('hello')")
        sout, serr = capture_sio(tty: true) { @app.main(["a7452"]) }
        ok {sout} == ""
        ok {serr} =~ /\e\[31m\[ERROR\]\e\[0m hello: Action not found\./
        ok {serr} !~ /\bactionrunner\.rb/
      end
      spec "[!89mz3] ignores backtrace of 'kernel_require.rb'." do
        prepare_actionfile("a7613", "run_once('hello')")
        sout, serr = capture_sio(tty: true) { @app.main(["a7613"]) }
        ok {sout} == ""
        ok {serr} =~ /\e\[31m\[ERROR\]\e\[0m hello: Action not found\./
        ok {serr} !~ /\brequire\b/
      end
      spec "[!ttt98] ignores backtrace of 'arun'." do
        prepare_actionfile("a5310", "run_once('hello')")
        sout, serr = capture_sio(tty: true) { @app.main(["a5310"]) }
        ok {sout} == ""
        ok {serr} =~ /\e\[31m\[ERROR\]\e\[0m hello: Action not found\./
        ok {serr} !~ /\barun:/
      end
      spec "[!z72yj] not ignore backtrace of others." do
        prepare_actionfile("a6230", "run_once('hello')")
        sout, serr = capture_sio(tty: true) { @app.main(["a6230"]) }
        ok {sout} == ""
        ok {serr} =~ /\e\[31m\[ERROR\]\e\[0m hello: Action not found\./
        ok {serr} =~ /oktest/
      end
    }

    topic('#load_action_file()') {
      spec "[!nx22j] returns false if action file already loaded." do
        prepare_actionfile("a0572")
        ok {@app.instance_eval { load_action_file() }} == true
        ok {@app.instance_eval { load_action_file() }} == false
        ok {@app.instance_eval { load_action_file() }} == false
      end
      spec "[!aov55] loads action file if exists." do
        prepare_actionfile("a2894")
        ok {Benry::CmdApp::REGISTRY.metadata_exist?("a2894")} == false
        @app.instance_eval { load_action_file() }
        ok {Benry::CmdApp::REGISTRY.metadata_exist?("a2894")} == true
      end
      spec "[!ssmww] raises error when `required: true` and action file not exist." do
        ok {@filename}.not_exist?
        pr = proc { @app.instance_eval { load_action_file() } }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                      "Action file ('Actionfile.rb') not found. Create it by `arun -g` command firstly.")
      end
      spec "[!vwtwe] it is AFTER loading action file to set global variables." do
        prepare_actionfile("a5298", "puts $_a5298.inspect")   # ... (A)
        File.open(@filename, "a") do |f|
          f << "puts $_a5298.inspect\n"             # ... (B)
        end
        sout, serr = capture_sio() do
          @app.instance_eval {
            @global_vars = {"_a5298" => "a5298val"}
            load_action_file()
          }
          @app.main(["a5298", "Alice"])
        end
        ok {serr} == ""
        ok {sout} == ("nil\n" +                     # ... (B)
                      "\"a5298val\"\n")             # ... (A)
      end
      spec "[!8i55a] prevents to load action file more than once." do
        prepare_actionfile("a8569")
        File.open(@filename, "a") do |f|
          f << "$_a8569 += 1\n"
        end
        $_a8569 = 0
        @app.instance_eval { load_action_file() }
        ok {$_a8569} == 1
        @app.instance_eval { load_action_file() }
        ok {$_a8569} == 1
        ok {$_a8569} != 2
      end
      spec "[!f68yv] returns true if action file loaded successfully." do
        prepare_actionfile("a9586")
        ret1 = @app.instance_eval { load_action_file() }
        ok {ret1} == true
        ret2 = @app.instance_eval { load_action_file() }
        ok {ret2} == false
        ret3 = @app.instance_eval { load_action_file() }
        ok {ret3} == false
      end
    }

    topic('#generate_action_file()') {
      spec "[!dta7r] generates action file." do
        ok {@filename}.not_exist?
        @app.instance_eval { generate_action_file(quiet: true) }
        ok {@filename}.file_exist?
      end
      spec "[!tmlqt] prints action file content if filename is '-'." do
        ok {@filename}.not_exist?
        sout = main "-g", "-f", "-"
        ok {@filename}.not_exist?
        ok {sout} =~ /^include Benry::ActionRunner::Export$/
      end
      spec "[!ymrjh] prints action file content if stdout is not a tty." do
        ok {@filename}.not_exist?
        sout, serr = capture_sio(tty: false) do
          @app.instance_eval { generate_action_file() }
        end
        ok {@filename}.not_exist?
        ok {serr} == ""
        ok {sout} =~ /^include Benry::ActionRunner::Export$/
      end
      spec "[!9e3c0] returns nil if action file is not generated." do
        ret = nil
        capture_sio(tty: false) do
          @app.instance_eval {
            @action_file = "-"
            ret = generate_action_file(quiet: true)
          }
        end
        ok {ret} == nil
      end
      spec "[!685cq] raises error if action file already exist." do
        prepare_actionfile("a1697")
        ok {@filename}.file_exist?
        pr = proc do
          @app.instance_eval { generate_action_file(quiet: true) }
        end
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "Action file ('Actionfile.rb') already exists. If you want to generate a new one, delete it first.")
      end
      spec "[!n09pl] reports result if action file generated successfully." do
        sout, serr = capture_sio(tty: true) do
          @app.instance_eval { generate_action_file() }
        end
        ok {serr} == ""
        ok {sout} == "[OK] Action file 'Actionfile.rb' generated.\n"
      end
      spec "[!iq0p2] reports nothing if option '-q' specified." do
        sout, serr = capture_sio(tty: true) do
          @app.instance_eval { generate_action_file(quiet: true) }
        end
        ok {serr} == ""
        ok {sout} == ""
      end
      spec "[!bf60l] returns action file name if generated." do
        ret = @app.instance_eval { generate_action_file(quiet: true) }
        ok {ret} == @filename
      end
    }

  end


end
