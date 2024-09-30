# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::UnixUtils do

    class DummyUtilsObject
      include Benry::MicroRake::UnixUtils
    end

    include Benry::MicroRake::UnixUtils

    def prompt()
      space = " " * (@_urake_chdir_depth || 0)
      return "[urake5]$ #{space}"
    end

    before do
      set_prompt()
    end


    spec "[!v1pbf] changes verbose mode of FileUtils commands to be controlled by `$VERBOSE_MODE`." do
      $VERBOSE_MODE = false
      sout = capture_sout() do
        touch "ex1.tmp"
        rm "ex1.tmp"
      end
      ok {sout} == ""
      $VERBOSE_MODE = true
      sout = capture_sout() do
        touch "ex1.tmp"
        rm "ex1.tmp"
      end
      ok {sout} == "[urake5]$ touch ex1.tmp\n"\
                   "[urake5]$ rm ex1.tmp\n"
    end

    spec "[!mm05w] changes dryrun mode of FileUtils commands to be controlled by `$DRYRUN_MODE`." do
      $DRYRUN_MODE = true
      sout = capture_sout() do
        touch "ex2.tmp"
      end
      ok {sout} == "[urake5]$ touch ex2.tmp\n"
      ok {"ex2.tmp"}.not_exist?
      $DRYRUN_MODE = false
      sout = capture_sout() do
        touch "ex2.tmp"
      end
      ok {sout} == "[urake5]$ touch ex2.tmp\n"
      ok {"ex2.tmp"}.file_exist?
    end


    topic '.disable_fileutils_commands()' do

      spec "[!rb0ii] disables FileUtils commands and raises NotImplementedError when called." do
        skip_when ENV['TEST_TARGET'] != "skipped",
                  "cannot recover changes on classes and modules"
        require "benry/unixcommand"
        use_commands_instead_of_fileutils(Benry::UnixCommand)
        dummy_file("ex1.tmp", "foobar\n")
        task :ex1 do
          compare_file "ex1.tmp", "ex1.tmp"
        end
        pr = proc do
          Benry::MicroRake::TASK_MANAGER.run_task(:ex1)
        end
        ok {pr}.raise?(NotImplementedError,
                       "compare_file(): Cannot invoke this method because FileUtils has been disabled.")
      end

    end


    topic '#prompt()' do

      spec "[!k6l7m] `prompt()` is an abstract method." do
        pr = proc do
          DummyUtilsObject.new().instance_eval do
            prompt()
          end
        end
        ok {pr}.raise?(NotImplementedError,
                       "DummyUtilsObject#prompt(): not implemented yet.")
      end

    end


    topic '#set_prompt()' do

      spec "[!grnd0] sets command prompt." do
        ok {prompt()} == "[urake5]$ "
        def prompt(); "[urake500]$ "; end
        sout = capture_sout { touch "dummy394" }
        ok {sout} == "[urake5]$ touch dummy394\n"
        set_prompt()
        sout = capture_sout { touch "dummy394" }
        ok {sout} == "[urake500]$ touch dummy394\n"
      end

    end


    topic '#cd()' do

      case_when "[!o97er] when block not given..." do

        spec "[!vo70t] just change directory." do
          tmpdir = "dummy594"
          dummy_dir(tmpdir)
          pwd = Dir.pwd
          at_end { Dir.chdir(pwd) }
          ok {Dir.pwd} == pwd
          sout = capture_sout { cd tmpdir }
          ok {sout} == "[urake5]$ cd #{tmpdir}\n"
          ok {Dir.pwd} != pwd
          ok {Dir.pwd} == File.join(pwd, tmpdir)
        end

      end

      case_when "[!ggjut] else..." do

        spec "[!gcfb6] change directory, yield block, and back to the original directory." do
          tmpdir = "dummy841"
          dummy_dir(tmpdir)
          pwd = Dir.pwd
          at_end { Dir.chdir(pwd) }
          ok {Dir.pwd} == pwd
          pwd2 = nil
          capture_sout do
            cd tmpdir do
              pwd2 = Dir.pwd
            end
          end
          ok {pwd2} != pwd
          ok {pwd2} == File.join(pwd, tmpdir)
        end

        spec "[!tpzd1] changes command prompt in block correctly." do
          tmpdir = "dummy291"
          dummy_dir(tmpdir)
          pwd = Dir.pwd
          at_end { Dir.chdir(pwd) }
          sout = capture_sout do
            cd "dummy291" do
              echo 1
            end
          end
          ok {sout} == "[urake5]$ cd dummy291\n"\
                       "[urake5]$  echo 1\n"\
                       "1\n"\
                       "[urake5]$  cd -\n"
        end

        spec "[!qs34j] recovers command prompt after block yielded." do
          tmpdir = "dummy723/dummy398"
          dummy_dir(tmpdir)
          pwd = Dir.pwd
          at_end { Dir.chdir(pwd) }
          sout = capture_sout do
            echo 1
            cd "dummy723" do
              echo 2
              cd "dummy398" do
                echo 3
              end
              echo 4
            end
            echo 5
          end
          ok {sout} == "[urake5]$ echo 1\n"\
                       "1\n"\
                       "[urake5]$ cd dummy723\n"\
                       "[urake5]$  echo 2\n"\
                       "2\n"\
                       "[urake5]$  cd dummy398\n"\
                       "[urake5]$   echo 3\n"\
                       "3\n"\
                       "[urake5]$   cd -\n"\
                       "[urake5]$  echo 4\n"\
                       "4\n"\
                       "[urake5]$  cd -\n"\
                       "[urake5]$ echo 5\n"\
                       "5\n"
        end

      end

    end


    topic '#echoback()' do

      spec "[!pslkx] prints nothing on dryrun mode." do
        $DRYRUN_MODE = true
        sout = capture_sout do
          echoback "foobar"
        end
        ok {sout} == ""
      end

      spec "[!ao39n] prints a string with command prompt." do
        sout = capture_sout do
          echoback "foobar"
        end
        ok {sout} == "[urake5]$ foobar\n"
      end

    end


    topic '#echo()' do

      spec "[!bxelq] prints echoback on verbose mode." do
        ok {$VERBOSE_MODE} == true
        sout = capture_sout do
          echo 123
        end
        ok {sout} == "[urake5]$ echo 123\n"\
                     "123\n"
        #
        $VERBOSE_MODE = false
        sout = capture_sout do
          echo 123
        end
        ok {sout} == "123\n"
      end

      spec "[!u8dsb] prints nothing on dryrun mode." do
        $DRYRUN_MODE = true
        sout = capture_sout do
          echo 123
        end
        ok {sout} == "[urake5]$ echo 123\n"
      end

      spec "[!00sy3] prints arguments." do
        sout = capture_sout do
          echo 123
        end
        ok {sout} == "[urake5]$ echo 123\n"\
                     "123\n"
      end

    end


    topic '#time()' do

      spec "[!6qroj] measures real, user, and system times." do
        sout, serr = capture_sio do
          time do
            echo "ABC"
          end
        end
        ok {sout} == "[urake5]$ echo ABC\n"\
                     "ABC\n"
        ok {serr} =~ /\A       0\.\d\d\d real        0\.\d\d\d user        0\.\d\d\d sys\n\z/
      end

      spec "[!hllql] prints real, user, and system times." do
        sout, serr = capture_sio do
          time do
            echo "ABC"
          end
        end
        ok {sout} == "[urake5]$ echo ABC\n"\
                     "ABC\n"
        ok {serr} =~ /\A       0\.\d\d\d real        0\.\d\d\d user        0\.\d\d\d sys\n\z/
      end

      spec "[!omp36] prints nothing on quiet mode." do
        $VERBOSE_MODE = false
        sout, serr = capture_sio do
          time do
            echo "ABC"
          end
        end
        ok {sout} == "ABC\n"
        ok {serr} == ""
      end

    end


    topic '#sh()' do

      spec "[!91wbl] prints command echoback with prompt." do
        sout = capture_sout do
          sh "touch foobar.txt"
        end
        ok {sout} == "[urake5]$ touch foobar.txt\n"
        ok {"foobar.txt"}.file_exist?
      end

      spec "[!ulses] prints nothing on quiet mode." do
        $VERBOSE_MODE = false
        sout = capture_sout do
          sh "touch foo2.txt"
        end
        ok {sout} == ""
        ok {"foo2.txt"}.file_exist?
      end

      spec "[!4fl74] do nothing on dryrun mode." do
        $DRYRUN_MODE = true
        sout = capture_sout do
          sh "touch foo3.txt"
        end
        ok {sout} == "[urake5]$ touch foo3.txt\n"
        ok {"foo3.txt"}.not_exist?
      end

      spec "[!dcann] executes command." do
        sout = capture_sout do
          sh "touch foo4.txt"
        end
        ok {sout} == "[urake5]$ touch foo4.txt\n"
        ok {"foo4.txt"}.file_exist?
      end

      spec "[!8mfps] yields block if given." do
        args = nil
        sout = capture_sout do
          sh "touch foo5.txt" do |*args_|
            args = args_
          end
        end
        ok {args[0]} == true
        ok {args[1]}.is_a?(Process::Status)
        ok {args[1].exitstatus} == 0
      end

      spec "[!i2b9g] yields block even if command failed." do
        args = nil
        sout = capture_sout do
          sh "false" do |result, pstat|
            args = [result, pstat]
          end
        end
        ok {args[0]} == false
        ok {args[1]}.is_a?(Process::Status)
        ok {args[1].exitstatus} == 1
      end

      spec "[!bfjmd] returns true if command finished successfully." do
        ret = nil
        sout = capture_sout do
          ret = sh "touch foo7.txt"
        end
        ok {ret} == true
      end

      spec "[!tte4w] fails when command finished unsuccessfully." do
        $VERBOSE_MODE = false
        pr = proc do
          sh "false a b c"
        end
        ok {pr}.raise?(RuntimeError, "Command failed (status=1): [false a b c]")
      end

    end


    topic '#sh!()' do

      spec "[!u01e3] prints command echoback on verbose mode." do
        sout = capture_sout do
          sh! "touch bar1.txt"
        end
        ok {sout} == "[urake5]$ touch bar1.txt\n"
      end

      spec "[!4tgx8] do nothing on dryrun mode." do
        $DRYRUN_MODE = true
        ok {"bar2.txt"}.not_exist?
        sout = capture_sout do
          sh! "touch bar2.txt"
        end
        ok {"bar2.txt"}.not_exist?
      end

      spec "[!hrw7q] exuectes command." do
        ok {"bar3.txt"}.not_exist?
        sout = capture_sout do
          sh! "touch bar3.txt"
        end
        ok {"bar3.txt"}.file_exist?
      end

      spec "[!ppnpj] yields block only when command failed." do
        args = nil
        sout = capture_sout do
          sh! "touch bar4.txt" do |*args_|
            args = args_
          end
        end
        ok {args} == nil
        #
        args = nil
        sout = capture_sout do
          sh! "false" do |*args_|
            args = args_
          end
        end
        ok {args} != nil
        ok {args}.length(1)
        ok {args[0]}.is_a?(Process::Status)
        ok {args[0].exitstatus} == 1
      end

      spec "[!4ni9x] returns true when command finished successfully." do
        ret = nil
        sout = capture_sout do
          ret = sh! "true"
        end
        ok {ret} == true
        #
        ret = nil
        sout = capture_sout do
          ret = sh! "false xx yy"
        end
        ok {ret} == false
      end

    end


    topic '#question()' do

      spec "[!1v63y] prints question message, reads user input, and returns result." do
        ret = nil
        sout = capture_sout("Alice\n") do
          ret = question "Your name"
        end
        ok {ret} == "Alice"
        ok {sout} == "Your name: "
      end

      spec "[!9bqbz] prints default value as a part of message when given." do
        ret = nil
        sout = capture_sout("\n") do
          ret = question "Your name", default: "Meg"
        end
        ok {ret} == "Meg"
        ok {sout} == "Your name (default: Meg): "
      end

      spec "[!4x9or] returns user input data when entered." do
        ret = nil
        sout = capture_sout("Kathy\n") do
          ret = question "What's your name"
        end
        ok {ret} == "Kathy"
        ok {sout} == "What's your name: "
      end

      spec "[!81k3h] repeats to print message when required data not entered nor default value provided." do
        ret = nil
        sout, serr = capture_sio("\nSara\n") do
          ret = question "Enter your name", required: true
        end
        ok {serr} == "** Answer required.\n"
        ok {ret} == "Sara"
        ok {sout} == "Enter your name: " * 2
        #
        ret = nil
        sout, serr = capture_sio("\n") do
          ret = question "Enter your name", required: false, default: "Barbara"
        end
        ok {serr} == ""
        ok {ret} == "Barbara"
        ok {sout} == "Enter your name (default: Barbara): "
      end

      spec "[!6ckyu] raises error if repeated more than 3 times." do
        ret = nil; sout = serr = nil
        sout, serr = capture_sio("\n\n\nSara\n") do
          pr = proc do
            ret = question "Enter your name", required: true
          end
          ok {pr}.raise?(RuntimeError, "Answer expected but not entered.")
        end
        ok {serr} == "** Answer required.\n" * 2
        ok {ret} == nil
        ok {sout} == "Enter your name: " * 3
      end

    end


    topic '#confirm()' do

      spec "[!mkefm] prints messgae, reads yes/no input, and returns result." do
        ret = nil
        sout = capture_sout("y\n") do
          ret = confirm "Are you ok?"
        end
        ok {ret} == true
        #
        ret = nil
        sout = capture_sout("n\n") do
          ret = confirm "Are you ok?"
        end
        ok {ret} == false
      end

      spec "[!xzera] prints '[y/n]:' if default value is not specified." do
        sout = capture_sout("y\n") do
          confirm "Are you ok?"
        end
        ok {sout} == "Are you ok? [y/n]: "
      end

      spec "[!iia89] prints '[y/N]:' if default value is false." do
        sout = capture_sout("y\n") do
          confirm "Are you ok?", default: false
        end
        ok {sout} == "Are you ok? [y/N]: "
      end

      spec "[!ew57o] prints '[Y/n]:' if default value is truthy." do
        sout = capture_sout("y\n") do
          confirm "Are you ok?", default: true
        end
        ok {sout} == "Are you ok? [Y/n]: "
      end

      spec "[!8xstk] if user data starts with 'y' or 'Y' then returns true." do
        ret = nil
        capture_sout("y\n") { ret = confirm "OK?" }
        ok {ret} == true
        capture_sout("Y\n") { ret = confirm "OK?" }
        ok {ret} == true
      end

      spec "[!feayf] if user data starts with 'n' or 'N' then returns false." do
        ret = nil
        capture_sout("n\n") { ret = confirm "OK?" }
        ok {ret} == false
        capture_sout("N\n") { ret = confirm "OK?" }
        ok {ret} == false
      end

      spec "[!56qd9] if user data is empty then returns default value if provided." do
        ret = nil
        capture_sout("\n") { ret = confirm "OK?", default: true }
        ok {ret} == true
        capture_sout("\n") { ret = confirm "OK?", default: false }
        ok {ret} == false
      end

      spec "[!skvl6] ignores invalid answer." do
        ret = nil
        sout, serr = capture_sio("123\nX\nY\n") { ret = confirm "Are you OK?" }
        ok {serr} == "** Please enter 'y' or 'n'.\n" * 2
        ok {sout} == "Are you OK? [y/n]: " * 3
        ok {ret} == true
      end

      spec "[!zwlg4] repeats while user data is empty or invalid and default value is nil." do
        ret = nil
        sout, serr = capture_sio("\nX\nN\n") { ret = confirm "Are you OK?" }
        ok {serr} == "** Please enter 'y' or 'n'.\n" * 2
        ok {sout} == "Are you OK? [y/n]: " * 3
        ok {ret} == false
      end

      spec "[!94380] raises error if repeated more than 3 times." do
        sout, serr = capture_sio("\n\n\n") do
          pr = proc { confirm "Are you OK?" }
          ok {pr}.raise?(RuntimeError,
                         "Expected 'y' or 'n', but not answered correctly.")
        end
        ok {serr} == "** Please enter 'y' or 'n'.\n" * 2
        ok {sout} == "Are you OK? [y/n]: " * 3
      end

    end

  end


end
