# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::MainApp do


    topic '#main()' do

      spec "[!dtl8y] adds `$URAKE_OPTS` to command-line arguments." do
        |main|
        libpath = "/opt/lib/boo"
        ok {$LOAD_PATH}.NOT.include?(libpath)
        ok {$DRYRUN_MODE} == false
        #
        ENV["URAKE_OPTS"] = "-I #{libpath} -e nil --dry-run"
        at_end {
          ENV.delete("URAKE_OPTS")
          $LOAD_PATH.delete(libpath)
          $DRYRUN_MODE = false
        }
        #
        sout = capture_sout { main.main(["hello"]) }
        ok {sout} == ""
        ok {$LOAD_PATH}.include?(libpath)
        ok {$DRYRUN_MODE} == true
      end

      spec "[!ndfqt] returns 0 if no exception raised." do
        |main|
        exit_code = nil
        sout, serr = capture_sio { exit_code = main.main(["hello"]) }
        ok {serr} == ""
        ok {exit_code} == 0
      end

      spec "[!ljpqg] catches exception and prints reduced backtrace." do
        |main, taskfile|
        content = File.read(taskfile, encoding: 'utf-8')
        content += <<-END
          task :err1 do
            1/0
          end
        END
        File.rename(taskfile, taskfile+".bkp")
        at_end { File.rename(taskfile+".bkp", taskfile) }
        File.write(taskfile, content, encoding: 'utf-8')
        sout, serr = capture_sio { main.main(["err1"]) }
        ok {sout} == ""
        ok {serr} =~ /\A\[ERROR\] divided by 0\n/
        ok {serr} =~ /^    from \.\/Taskfile\.rb:\d+:in /
        ok {serr} !~ /benry\/microrake\.rb:/
      end

      spec "[!yfdw9] raises exception if '-t' or '--backtrace' option specified." do
        |main|
        sout, serr = capture_sio { main.main(["hello", "-X"]) }
        ok {sout} == ""
        ok {serr} == "[ERROR] -X: Unknown option.\n"
        #
        pr = proc do
          sout, serr = capture_sio { main.main(["-t", "hello", "-X"]) }
        end
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-X: Unknown option.")
        #
        pr = proc do
          sout, serr = capture_sio { main.main(["--backtrace", "hello", "-X"]) }
        end
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-X: Unknown option.")
      end

      spec "[!ggxr1] returns 1 if any exception raised." do
        |main|
        exit_code = nil
        sout, serr = capture_sio { exit_code = main.main(["hello", "-X"]) }
        ok {serr} == "[ERROR] -X: Unknown option.\n"
        ok {exit_code} == 1
      end

    end


    topic '#run()' do

      spec "[!biwyv] parses global options only (not parse task options)." do
        |main|
        args = ["-l", "hello", "-l"]
        pr = proc { capture_sio { main.run(*args) } }
        ok {pr}.raise_nothing?
        #
        args = ["hello", "-l"]
        pr = proc { capture_sio { main.run(*args) } }
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-l: Argument required.")
      end

      spec "[!0rv6h] returns 0 when certain global options such as '-h' or '-V' are specified." do
        |main|
        exit_code = nil
        sout = capture_sout { exit_code = main.run("-h") }
        ok {exit_code} == 0
      end

      spec "[!ufbzx] changs global variables when '-q', '-s', -t' options are specified." do
        |main|
        ok {$VERBOSE_MODE} == true
        ok {$QUIET_MODE}   == false
        capture_sio { main.run("-q", "hello") }
        ok {$VERBOSE_MODE} == false
        ok {$QUIET_MODE}   == true
        #
        $VERBOSE_MODE = true
        $VERBOSE_MODE = false
        capture_sio { main.run("-s", "hello") }
        ok {$VERBOSE_MODE} == false
        ok {$QUIET_MODE}   == true
        #
        ok {$TRACE_MODE} == false
        capture_sio { main.run("-t", "hello") }
        ok {$TRACE_MODE} == true
      end

      spec "[!qppmx] use specified task filename when '-f' option specified." do
        |taskfile|
        File.rename taskfile, "#{taskfile}.bkp"
        at_end { File.rename "#{taskfile}.bkp", taskfile }
        File.write("tasklist.rb", <<-END)
          desc "foo1"
          task :foo1 do
            puts 'FOO1'
          end
        END
        MicroRakeTestHelper.reset_microrake()
        main = Benry::MicroRake::MainApp.new("urake3")
        #
        pr = proc { main.run("-N", "foo1") }
        ok {pr}.raise?(Benry::MicroRake::CommandLineError,
                       "Taskfile.rb: Task file not found.")
        #
        sout = nil
        pr = proc do
          sout = capture_sout do
            main.run("-N", "-f", "tasklist.rb", "foo1")
          end
        end
        ok {pr}.raise_nothing?
        ok {sout} == "FOO1\n"
      end

      spec "[!36ry7] use default task filename when '-f' option not specified." do
        |main, taskfile|
        ok {taskfile}.file_exist?
        sout = capture_sout { main.run("-l") }
        ok {sout} =~ /^hello                # greeting message$/
      end

      spec "[!8yyoq] searches task file in current dir or in parent dir." do
        |main, taskfile|
        dummy_dir "foo/bar"
        Dir.chdir "foo/bar" do
          ok {    "./"+taskfile}.not_exist?
          ok {   "../"+taskfile}.not_exist?
          ok {"../../"+taskfile}.file_exist?
          sout = capture_sout { main.run("-l") }
          ok {sout} =~ /^hello                # greeting message$/
        end
      end

      spec "[!bjq75] not search task file in parent dir if '-N' option specified." do
        |main, taskfile|
        dummy_dir "foo/bar"
        Dir.chdir "foo/bar" do
          ok {    "./"+taskfile}.not_exist?
          ok {   "../"+taskfile}.not_exist?
          ok {"../../"+taskfile}.file_exist?
          sout = capture_sout { main.run("-l") }
          ok {sout} =~ /^hello                # greeting message$/
        end
      end

      case_when "[!g64iv] when task file not found..." do

        spec "[!rcqfk] prints short usage message if no task name specified." do
          |main, taskfile|
          File.rename taskfile, (taskfile+".bkp")
          at_end { File.rename (taskfile+".bkp"), taskfile }
          sout, serr = capture_sio { main.run("-N") }
          ok {sout} == <<~'END' % {taskfile: taskfile}
            Usage: urake2 [<options>] <task>

            (Hint: Run `urake2 -h` for help, and `urake2 --new` to create '%{taskfile}'.)
          END
          ok {serr} == ""
        end

        spec "[!f6cre] raises error if task name specified." do
          |main, taskfile|
          File.rename taskfile, (taskfile+".bkp")
          at_end { File.rename (taskfile+".bkp"), taskfile }
          pr = proc { main.run("-N", "hello") }
          ok {pr}.raise?(Benry::MicroRake::CommandLineError,
                         "Taskfile.rb: Task file not found.")
        end

      end

      spec "[!0a2fw] changes current dir to where task file placed." do
        |main, taskfile|
        pwd = Dir.pwd
        dummy_dir "foo/bar"
        Dir.chdir "foo/bar"
        at_end { Dir.chdir pwd }
        ok {    "./"+taskfile}.not_exist?
        ok {   "../"+taskfile}.not_exist?
        ok {"../../"+taskfile}.file_exist?
        task :pwd do
          puts Dir.pwd
        end
        sout, serr = capture_sio { main.run("pwd") }
        ok {sout.strip} != Dir.pwd
        ok {sout.strip} == pwd
        ok {serr} == "(in #{pwd}/)\n"
      end

      spec "[!xh7qi] loads task file after current directory changed." do
        |main, taskfile|
        pwd = Dir.pwd
        dummy_dir "foo/bar"
        Dir.chdir "foo/bar"
        at_end { Dir.chdir pwd }
        ok {Dir.pwd} == pwd + "/foo/bar"
        def main.require_rubyscript(filepath)
          @_pwd = Dir.pwd
          super
        end
        capture_sio{ main.run("hello") }
        _pwd = main.instance_variable_get(:@_pwd)
        ok {_pwd} != pwd + "/foo/bar"
        ok {_pwd} == pwd
      end

      spec "[!ehzxe] runs ruby code and exit 0 if '-e' option specified." do
        |main|
        exit_code = nil
        sout = capture_sout do
          exit_code = main.run("-e", "puts Benry::MicroRake.name", "hello")
        end
        ok {sout} == "Benry::MicroRake\n"
        ok {exit_code} == 0
      end

      spec "[!iiegt] runs ruby code but not exit if '-E' option specified." do
        |main|
        exit_code = nil
        sout = capture_sout do
          exit_code = main.run("-E", "puts Benry::MicroRake.name", "hello")
        end
        ok {sout} == "Benry::MicroRake\n"\
                     "Hello, world!\n"
        ok {exit_code} == 0
      end

      spec "[!u9inq] runs specified task with args and opts." do
        |main|
        sout = capture_sout do
          main.run("hello", "Alice", "-l", "fr")
        end
        ok {sout} == "Bonjour, Alice!\n"
      end

    end


    topic '#parse_global_options()' do

      spec "[!ba0tb] parses only global options and not parse task options." do
        |main|
        args = ["-h", "hello", "--help"]
        g_opts = main.instance_eval { parse_global_options(args) }
        ok {g_opts} == {help: true}
        ok {args} == ["hello", "--help"]
      end

      spec "[!3elu3] raises error if invalid global option specified." do
        |main|
        args = ["-X", "hello", "--help"]
        pr = proc do
          main.instance_eval { parse_global_options(args) }
        end
        ok {pr}.raise?(Benry::CmdOpt::OptionError, "-X: Unknown option.")
      end

    end


    topic '#handle_global_options()' do

      spec "[!pcn0t] '-h' or '--help' option prints help message." do |main|
        ["-h", "--help"].each do |opt|
          sout = capture_sout { main.run(opt) }
          ok {sout} =~ /\AMicroRake \(\d+\.\d+\.\d+\) --- Better Rake,/
          ok {sout} =~ /^Usage:\n/
          ok {sout} =~ /^Options:\n/
          ok {sout} =~ /^Tasks:\n/
          ok {sout} =~ /^Example:\n/
        end
      end

      spec "[!d0hln] '-V' or '--version' option prints version." do |main|
        ["-V", "--version"].each do |opt|
          sout = capture_sout { main.run(opt) }
          ok {sout} =~ /\A\d+\.\d+\.\d+\n\z/
          ok {sout} == "#{Benry::MicroRake::VERSION}\n"
        end
      end

      spec "[!iw6ug] '-I' or '--libdir' option adds library path to `$LOAD_PATH`." do
        |main, taskfile|
        libpath = "/opt/lib/foo"
        ok {$LOAD_PATH}.NOT.include?(libpath)
        at_end { $LOAD_PATH.delete(libpath) }
        create_taskfile(<<-END)
          task :show_libpath do
            p $LOAD_PATH
          end
        END
        [["-I", libpath], ["--libdir=#{libpath}"]].each do |opts|
          sout = capture_sout do
            main.run(*opts, "show-libpath")
          end
          ok {sout}.include?(", \"#{libpath}\"\]")
        end
        ok {$LOAD_PATH}.include?(libpath)
        ok {$LOAD_PATH[-1]} == libpath
      end

      spec "[!f7729] skips if library path already exists in `$LOAD_PATH`." do
        |main|
        libpath = "/opt/lib/bar"
        at_end { $LOAD_PATH.delete(libpath) }
        ok {$LOAD_PATH}.NOT.include?(libpath)
        _ = capture_sout { main.run("-I", libpath, "--libdir=#{libpath}", "hello") }
        ok {$LOAD_PATH[-1]} == libpath
        ok {$LOAD_PATH.count(libpath)} == 1
        _ = capture_sout { main.run("-I", libpath, "-I#{libpath}", "hello") }
        ok {$LOAD_PATH[-1]} == libpath
        ok {$LOAD_PATH.count(libpath)} == 1
      end

      spec "[!07yf1] '-T' or '--tasks' option lists task names with command name." do
        |main|
        ["-T", "--tasks"].each do |opt|
          sout = capture_sout { main.run(opt) }
          ok {sout} =~ /^urake2 hello +# greeting message$/
          ok {sout} =~ /^urake2 clean +# delete garbage files \(& product files too if '-a'\)$/
        end
      end

      spec "[!6t9fa] '-l' option lists task names without command name." do
        |main|
        ["-l"].each do |opt|
          sout = capture_sout { main.run(opt) }
          ok {sout} =~ /^hello +# greeting message$/
          ok {sout} =~ /^clean +# delete garbage files \(& product files too if '-a'\)$/
        end
      end

      spec "[!yoqzz] '-D' or '--describe' option lists task names with description." do
        |main|
        ["-D", "--describe"].each do |opt|
          sout = capture_sout { main.run(opt) }
          ok {sout}.include?("
urake2 hello
    greeting message
\n")
        end
      end

      spec "[!02xlo] '-P' or '--prereqs' option lists prerequisites of each task." do
        |main, taskfile|
        create_taskfile(<<-END)
          desc "A1"
          task :A1 => [:A2, :A3] do; puts "A1"; end
          desc "A2"
          task :A2 => :A4 do; puts "A2"; end
          desc "A3"
          task :A3 do; puts "A3"; end
          desc "A4"
          task :A4 do; puts "A4"; end
        END
        expected = <<-END
	A1
	    A2
	        A4
	    A3
	A2
	    A4
	A3
	A4
	END
        expected = expected.gsub(/^\t/, "")
        ["-P", "--prereqs"].each do |opt|
          sout = capture_sout { main.run(opt) }
          ok {sout} == expected
        end
      end

      spec "[!26hf6] '-P' or '--prereqs' option reports cyclic task dependency." do
        |main, taskfile|
        create_taskfile(<<-END)
          desc "A1"
          task :A1 => [:A3, :A2] do; puts "A1"; end
          desc "A2"
          task :A2 => :A4 do; puts "A2"; end
          desc "A3"
          task :A3 => :A5 do; puts "A3"; end
          desc "A4"
          task :A4 => :A5 do; puts "A4"; end
          desc "A5"
          task :A5 => :A2 do; puts "A5"; end
        END
        expected = <<-END
END
        ["-P", "--prereqs"].each do |opt|
          exc = nil
          begin
            main.run(opt)
          rescue => exc
          end
          ok {exc} != nil
          ok {exc.message} == <<END.chomp
Cyclic task detected. (A5->A2->A4->A5)
\e[2m    A5                   : ./Taskfile.rb:10
    A2                   : ./Taskfile.rb:4
    A4                   : ./Taskfile.rb:8
    A5                   : ./Taskfile.rb:10\e[0m
END
        end
      end

      spec "[!s3jek] '-W' or '--where' option lists locations of each task." do
        |main|
        ["-W", "--where"].each do |opt|
          sout = capture_sout { main.run(opt) }
          ok {sout} =~ /^clean +\.\/Taskfile\.rb:\d+$/
          ok {sout} =~ /^hello +\.\/Taskfile\.rb:\d+$/
        end
      end

      spec "[!59ev8] '--new' option prints example code of taskfile." do
        |main|
        ["--new"].each do |opt|
          sout = capture_sout { main.run(opt) }
          ok {sout} =~ /^task :hello do/
          ok {sout} =~ /^task :clean do/
          ok {sout} =~ /^namespace :git, alias_for: "status:here" do/
          ok {sout} =~ /^  sh "urake2 --help"$/
        end
      end

      spec "[!vggoh] '--backtrace' option enables to print backtrace when error raised." do
        |main|
        varname = :@backtrace_enabled
        ["--backtrace"].each do |opt|
          pr = proc { main.main([opt, "hello", "--foo"]) }
          ok {pr}.raise?(Benry::CmdOpt::OptionError, "--foo: Unknown long option.")
        end
        #
        sout, serr = capture_sio() do
          pr = proc { main.main(["hello", "--foo"]) }
          ok {pr}.NOT.raise?(Exception)
        end
      end

      spec "[!byhaa] '-t' or '--trace' option enables to print backtrace when error raised." do
        |main|
        varname = :@backtrace_enabled
        ["-t", "--trace"].each do |opt|
          ok {main.instance_variable_get(varname)} == false
          sout, serr = capture_sio { main.run(opt, "hello") }
          ok {main.instance_variable_get(varname)} == true
          main.instance_variable_set(varname, false)
        end
      end

      spec "[!jiixo] returns true if no need to do more, false if else." do
        |main|
        options = [:help, :version, :tasks, :list, :describe, :prereqs, :where, :new]
        false_options = [:backtrace, :trace]
        libdir = "/opt/lib"
        at_end { $LOAD_PATH.delete(libdir) }
        capture_sio do
          main.instance_exec(self) do |_|
            options.each do |sym|
              _.ok {handle_global_options({sym => true})} == true
            end
            false_options.each do |sym|
              _.ok {handle_global_options({sym => true})} == false
            end
            _.ok {handle_global_options({:libdir => [libdir]})} == false
          end
        end
      end

    end


    topic '#_filter2regexp()' do

      spec "[!tu020] do nothing if filter pattern is nil." do
        |main|
        ret = main.instance_eval { _filter2regexp(nil) }
        ok {ret} == nil
      end

      spec "[!lgy64] compiles filter pattern string to regexp object." do
        |main|
        ret = main.instance_eval { _filter2regexp('\d+') }
        ok {ret} == /\d+/
      end

      spec "[!hgt9s] raises error if filter pattern cannot be compiled." do
        |main|
        pr = proc do
          main.instance_eval { _filter2regexp('*[0-9]') }
        end
        ok {pr}.raise?(Benry::MicroRake::CommandLineError,
                       "*[0-9]: Invalid regexp pattern.")
      end

    end


    topic '#toggle_global_mode()' do

      spec "[!rtghg] '-q' or '--quiet' option enables quiet mode and disables verbose mode." do
        |main|
        $VERBOSE_MODE = true
        $QUIET_MODE   = false
        capture_sout { main.run("-q", "hello") }
        ok {$VERBOSE_MODE} == false
        ok {$QUIET_MODE}   == true
        #
        $VERBOSE_MODE = true
        $QUIET_MODE   = false
        capture_sout { main.run("--quiet", "hello") }
        ok {$VERBOSE_MODE} == false
        ok {$QUIET_MODE}   == true
      end

      spec "[!xr8km] '-s' or '--silent' option enables quiet mode and disables verbose mdoe." do
        |main|
        $VERBOSE_MODE = true
        $QUIET_MODE   = false
        capture_sout { main.run("-s", "hello") }
        ok {$VERBOSE_MODE} == false
        ok {$QUIET_MODE}   == true
        #
        $VERBOSE_MODE = true
        $QUIET_MODE   = false
        capture_sout { main.run("--silent", "hello") }
        ok {$VERBOSE_MODE} == false
        ok {$QUIET_MODE}   == true
      end

      spec "[!wijrh] '-n' or '--dry-run' option enables dryrun mode." do
        |main|
        $DRYRUN_MODE = false
        capture_sout { main.run("-n", "hello") }
        ok {$DRYRUN_MODE} == true
        #
        $DRYRUN_MODE = false
        capture_sout { main.run("--dry-run", "hello") }
        ok {$DRYRUN_MODE} == true
      end

      spec "[!j4y2v] '-t' or '--trace' option enables trace mode." do
        |main|
        $TRACE_MODE = false
        capture_sio { main.run("-t", "hello") }
        ok {$TRACE_MODE} == true
        #
        $TRACE_MODE = false
        capture_sio { main.run("--trace", "hello") }
        ok {$TRACE_MODE} == true
      end

    end


    topic '#determine_task_filename()' do

      spec "[!zrmec] returns specified task file name when '-f' option specified." do
        |main|
        ret = main.instance_eval {
          determine_task_filename({taskfile: "tasks.rb"})
        }
        ok {ret} == "tasks.rb"
        #
        ret = main.instance_eval {
          determine_task_filename({rakefile: "tasks2.rb"})
        }
        ok {ret} == "tasks2.rb"
      end

      spec "[!2fzyc] returns 'Rakefile' when '-u' option specified." do
        |main|
        ret = main.instance_eval {
          determine_task_filename({userake: true})
        }
        ok {ret} == "Rakefile"
      end

      spec "[!4ufpx] returns 'Taskfile.rb' when no global option specified." do
        |main|
        ret = main.instance_eval {
          determine_task_filename({})
        }
        ok {ret} == "Taskfile.rb"
      end

    end


    topic '#find_task_file()' do

      spec "[!siwnn] returns absolute filepath of task file when exists." do
        |main, taskfile|
        nosearch = false
        ret = main.instance_eval { find_task_file(taskfile, nosearch) }
        ok {ret} == File.absolute_path(taskfile)
      end

      spec "[!2gxmu] returns nil if task file not found and '-N' option specified." do
        |main, taskfile|
        pwd = Dir.pwd
        dummy_dir "foo/bar"
        Dir.chdir "foo/bar"
        at_end { Dir.chdir pwd }
        nosearch = true
        ret = main.instance_eval { find_task_file(taskfile, nosearch) }
        ok {ret} == nil
      end

      spec "[!hha89] searches task file in parent directory." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = Dir.pwd
        dummy_dir "foo/bar"
        Dir.chdir "foo/bar"
        at_end { Dir.chdir pwd }
        nosearch = false
        ret = main.instance_eval { find_task_file(taskfile, nosearch) }
        ok {ret} == fullpath
      end

      spec "[!9wein] stops task file searching when loop time goes over max time." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = Dir.pwd
        dummy_dir "foo/bar"
        Dir.chdir "foo/bar"
        at_end { Dir.chdir pwd }
        nosearch = false
        ret = main.instance_eval { find_task_file(taskfile, nosearch, max: 3) }
        ok {ret} == fullpath
        ret = main.instance_eval { find_task_file(taskfile, nosearch, max: 2) }
        ok {ret} == nil
      end

      spec "[!295n1] returns nil if task file not found in parent directories." do
        |main|
        nosearch = false
        ret = main.instance_eval { find_task_file("TempTaskfile.rb", nosearch) }
        ok {ret} == nil
      end

    end


    topic '#load_task_file()' do

      spec "[!hzdd9] searches and loads task file." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = Dir.pwd
        dummy_dir "foo/bar"
        Dir.chdir "foo/bar"
        at_end { Dir.chdir pwd }
        ok {$LOADED_FEATURES}.NOT.include?(fullpath)
        main.instance_eval { load_task_file({}) }
        ok {$LOADED_FEATURES}.include?(fullpath)
      end

      spec "[!aeeuq] raises error if task file not found." do
        |main|
        pr = proc do
          main.instance_eval { load_task_file({taskfile: "TempTasks.rb"}) }
        end
        ok {pr}.raise?(Benry::MicroRake::CommandLineError,
                       "TempTasks.rb: Task file not found.")
      end

      spec "[!176my] loads task file if found." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        ok {$LOADED_FEATURES}.NOT.include?(fullpath)
        main.instance_eval { load_task_file({}) }
        ok {$LOADED_FEATURES}.include?(fullpath)
      end

    end


    topic '#require_rubyscript()' do

      spec "[!yr615] sets task file path to global var." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        ok {$URAKE_TASKFILE_FULLPATH} == nil
        main.instance_eval { require_rubyscript(fullpath) }
        ok {$URAKE_TASKFILE_FULLPATH} == fullpath
      end

      spec "[!3nfq9] requires task file if file name ends with '.rb'." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        ok {fullpath}.end_with?(".rb")
        ok {$LOADED_FEATURES}.NOT.include?(fullpath)
        main.instance_eval { require_rubyscript(fullpath) }
        ok {$LOADED_FEATURES}.include?(fullpath)
      end

      spec "[!ua08a] loads task file if file name not end with '.rb'." do
        |main, taskfile|
        File.rename taskfile, "Taskfile"
        at_end { File.rename "Taskfile", taskfile }
        fullpath = File.absolute_path("Taskfile")
        ok {fullpath}.NOT.end_with?(".rb")
        ok {$LOADED_FEATURES}.NOT.include?(fullpath)
        main.instance_eval { require_rubyscript(fullpath) }
        ok {$LOADED_FEATURES}.NOT.include?(fullpath)   # !!!
      end

    end


    topic '#change_dir_if_necessary()' do

      def _prepare()
        pwd = Dir.pwd
        dummy_dir "foo/bar"
        Dir.chdir "foo/bar"
        at_end { Dir.chdir pwd }
        return pwd
      end

      spec "[!nvx4s] when dir is current dir, not change dir." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = Dir.pwd()
        dir = nil
        silent = true
        main.instance_eval {
          change_dir_if_necessary(".", fullpath, taskfile, silent) do
            dir = Dir.pwd()
          end
        }
        ok {dir} == pwd
      end

      spec "[!n6el9] when dir is specified, change to it." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = _prepare()
        dir = nil
        silent = true
        main.instance_eval {
          change_dir_if_necessary("..", fullpath, taskfile, silent) do
            dir = Dir.pwd()
          end
        }
        ok {dir} == pwd + "/foo"
      end

      spec "[!5045n] when task file exists in current dir, not change dir." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = Dir.pwd()
        dir = nil
        silent = true
        main.instance_eval {
          change_dir_if_necessary(nil, fullpath, taskfile, silent) do
            dir = Dir.pwd()
          end
        }
        ok {dir} == pwd
      end

      spec "[!6u9uc] when task file not exist in current dir, change dir." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = _prepare()
        dir = nil
        silent = true
        main.instance_eval {
          change_dir_if_necessary(nil, fullpath, taskfile, silent) do
            dir = Dir.pwd()
          end
        }
        ok {dir} == pwd
      end

      spec "[!donwz] yields block after directory changed." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = _prepare()
        dir = nil
        silent = true
        main.instance_eval {
          change_dir_if_necessary(nil, fullpath, taskfile, silent) do
            dir = Dir.pwd()
          end
        }
        ok {dir} == pwd
      end

      spec "[!hi5wr] back to original dir after yielding block." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = _prepare()
        dir = nil
        silent = true
        ok {Dir.pwd} == pwd + "/foo/bar"
        main.instance_eval {
          change_dir_if_necessary(nil, fullpath, taskfile, silent) do
            dir = Dir.pwd()
          end
        }
        ok {dir} == pwd
        ok {Dir.pwd} == pwd + "/foo/bar"
      end

      spec "[!b9esj] prints information when directory changed." do
        |main, taskfile|
        fullpath = File.absolute_path(taskfile)
        pwd = _prepare()
        dir = nil
        silent = true
        ok {Dir.pwd} == pwd + "/foo/bar"
        main.instance_eval {
          change_dir_if_necessary(nil, fullpath, taskfile, silent) do
            dir = Dir.pwd()
          end
        }
        ok {dir} == pwd
        ok {Dir.pwd} == pwd + "/foo/bar"
      end

      spec "[!fa18c] not print information when '-s' option specified." do
        |main, taskfile|
        pwd = _prepare()
        #
        sout, serr = capture_sio { main.run("-s", "hello") }
        ok {serr} == ""
        #
        sout, serr = capture_sio { main.run("--silent", "hello") }
        ok {serr} == ""
        #
        sout, serr = capture_sio { main.run("hello") }
        ok {serr} == "(in #{pwd}/)\n"
      end

    end


    topic '#run_the_task()' do

      spec "[!zw84u] runs 'default' task if defined and no task name specified." do
        |main|
        create_taskfile(<<-END)
          task :ex1 do
            puts "task=ex1"
          end
          task :default => :ex1
        END
        sout = capture_sout { main.run() }
        ok {sout} == "task=ex1\n"
      end

      spec "[!yq0sh] prints short usage if no task name specified nor 'default' task defined." do
        |main|
        sout = capture_sout { main.run() }
        ok {sout} == <<END
Usage: urake2 [<options>] <task>

(Hint: Run `urake2 -h` for help, and `urake2 -T` for task list.)
END
      end

      spec "[!vfn69] handles `task[var1,var2]` style argument." do
        |main|
        create_taskfile(<<-END)
          task :rakestyle1, [:a1, :a2] do |t, args|
            puts "== rakestyle1 =="
            p [args.a1, args.a2]
          end
          task :rakestyle2, [:b1, :b2] => [:rakestyle1] do |t, args|
            puts "== rakestyle2 =="
            p [args[:b1], args[:b2]]
          end
        END
        sout = capture_sout { main.run("rakestyle1[foo,bar]") }
        ok {sout} == <<END
== rakestyle1 ==
["foo", "bar"]
END
        sout = capture_sout { main.run("rakestyle2[123,true]") }
        ok {sout} == <<END
== rakestyle1 ==
[nil, nil]
== rakestyle2 ==
["123", "true"]
END
      end

      spec "[!nhvus] raises error when task not defined." do
        |main|
        pr = proc { main.run("blabla") }
        ok {pr}.raise!(Exception, "blabla: Task not defined.")
      end

      spec "[!o9ouk] handles 'name=val' style arg as environment variables." do
        |main|
        create_taskfile(<<-END)
          task :env do
            puts ENV["foo"]
            puts ENV["bar"]
          end
        END
        ok {ENV["foo"]} == nil
        ok {ENV["bar"]} == nil
        at_end { ENV.delete("foo"); ENV.delete("bar") }
        sout = capture_sout { main.run("env", "foo=ABC", "bar=123") }
        ok {sout} == "ABC\n123\n"
        ok {ENV["foo"]} == "ABC"
        ok {ENV["bar"]} == "123"
      end

      spec "[!1cwjs] parses task options even after arguments." do
        |main|
        sout = capture_sout { main.run("hello", "Alice", "-l", "it") }
        ok {sout} == "Chao, Alice!\n"
      end

      spec "[!8dn6t] not parse task options after '--'." do
        |main|
        sout = capture_sout { main.run("hello", "Alice", "--", "-l", "it") }
        ok {sout} == "Hello, Alice!\n"
      end

      spec "[!xs3gw] if '-h' or '--help' option specified for task, show help message of the task." do
        |main|
        expected = <<END
urake2 hello --- greeting message

Usage:
  $ urake2 hello [<options>] [<name>]

Options:
  -l, --lang=<en|fr|it>  : language
  -c, --color[=<on|off>] : enable color

END
        ["-h", "--help"].each do |opt|
          sout = capture_sout() { main.run("hello", opt) }
          ok {sout} == expected
        end
      end

      spec "[!4wzxj] global option '-A' or '--all' affects to task help message." do
        |main|
        sout = capture_sout() { main.run("-A", "hello", "--help") }
        ok {sout} =~ /^  -h, --help +: show help message$/
        #
        sout = capture_sout() { main.run("hello", "--help") }
        ok {sout} !~ /^  -h, --help +: show help message$/
      end

      spec "[!wqfjl] runs the task with args and options if task name specified." do
        |main|
        sout = capture_sout() { main.run("hello") }
        ok {sout} == "Hello, world!\n"
        sout = capture_sout() { main.run("hello", "Alice") }
        ok {sout} == "Hello, Alice!\n"
        sout = capture_sout() { main.run("hello", "-l", "fr", "Bob") }
        ok {sout} == "Bonjour, Bob!\n"
        sout = capture_sout() { main.run("hello", "--lang=it", "Charlie") }
        ok {sout} == "Chao, Charlie!\n"
      end

    end

    topic '#parse_task_options()' do

      spec "[!!1cwjs] parses task options even after arguments." do
        |main|
        capture_sio { main.run("hello") }   # to load taskfile
        task = main.instance_eval { @task_manager.get_task("hello") }
        args = ["--help", "Alice", "-l", "fr", "Bob"]
        opts = main.instance_eval { parse_task_options(task, args) }
        ok {opts} == {lang: "fr", help: true}
        ok {args} == ["Alice", "Bob"]
      end

      spec "[!!8dn6t] not parse task options after '--'." do
        |main|
        capture_sio { main.run("hello") }   # to load taskfile
        task = main.instance_eval { @task_manager.get_task("hello") }
        args = ["--help", "Alice", "--", "-l", "fr", "Bob"]
        opts = main.instance_eval { parse_task_options(task, args) }
        ok {opts} == {help: true}
        ok {args} == ["Alice", "-l", "fr", "Bob"]
      end

    end


    topic '#handle_exception()' do

      spec "[!jmyym] error messages are printed in color when stdout is a tty." do
        |main|
        sout, serr = capture_sio(tty: true) { main.main(["hello", "-x"]) }
        ok {sout} == ""
        ok {serr} == "\e[31m[ERROR]\e[0m -x: Unknown option.\n"
      end

      spec "[!p15z9] error messages are printed in non-color when stdout is not a tty." do
        |main|
        sout, serr = capture_sio(tty: false) { main.main(["hello", "-x"]) }
        ok {sout} == ""
        ok {serr} == "[ERROR] -x: Unknown option.\n"
      end

      spec "[!gwnzq] not print backtrace if OptionError." do
        |main|
        sout, serr = capture_sio(tty: false) { main.main(["hello", "-x"]) }
        ok {sout} == ""
        ok {serr} == "[ERROR] -x: Unknown option.\n"
      end

      spec "[!5yp7f] not print backtrace if CommandLineError." do
        |main|
        sout, serr = capture_sio(tty: false) { main.main(["hello2"]) }
        ok {sout} == ""
        ok {serr} == "[ERROR] hello2: Task not defined.\n"
      end

      spec "[!swz7v] not print backtrace if CyclicTaskError." do
        |main|
        task :ex1 => :ex2 do end; ln1 = __LINE__
        task :ex2 => :ex3 do end; ln2 = __LINE__
        task :ex3 => :ex1 do end; ln3 = __LINE__
        sout, serr = capture_sio(tty: true) { main.main(["ex2"]) }
        ok {sout} == ""
        ok {serr} == "\e[31m[ERROR]\e[0m Cyclic task detected. (ex2->ex3->ex1->ex2)\n"\
                     "\e[2m    ex2                  : test/mainapp_test.rb:#{ln2}\n"\
                          "    ex3                  : test/mainapp_test.rb:#{ln3}\n"\
                          "    ex1                  : test/mainapp_test.rb:#{ln1}\n"\
                          "    ex2                  : test/mainapp_test.rb:#{ln2}\e[0m\n"
      end

      spec "[!gvbkd] prints processed backtrace." do
        |main|
        task :ex3 do
          1/0
        end
        sout, serr = capture_sio(tty: true) { main.main(["ex3"]) }
        ok {sout} == ""
        ok {serr} =~ /from test\/mainapp_test\.rb:/
        ok {serr} !~ /benry\/microrake\.rb:/
      end

      spec "[!arcqw] clears file lines cache." do
        skip_when true, reason: "difficult to test"
      end

    end


    topic '#skip_backtrace?()' do

      spec "[!d42wd] returns true if exception is one of OptionError, CommandLineError, or CyclicTaskError." do
        |main|
        main.instance_exec(self) do |_|
          _.ok {skip_backtrace?(Benry::CmdOpt::OptionError.new())} == true
          _.ok {skip_backtrace?(Benry::MicroRake::CommandLineError.new())} == true
          _.ok {skip_backtrace?(Benry::MicroRake::CyclicTaskError.new())} == true
        end
      end

      spec "[!5fy6f] returns false if else." do
        |main|
        main.instance_exec(self) do |_|
          _.ok {skip_backtrace?(ZeroDivisionError.new)} == false
          _.ok {skip_backtrace?(RuntimeError.new("msg"))} == false
        end
      end

    end


    topic '#filter_backtrace()' do

      spec "[!h50s4] filters backtrace entries to reduce output." do
        |main|
        pr = proc { main.run("-e", "1/0") }
        exc = ok {pr}.raise?(ZeroDivisionError)
        ok {exc.backtrace}.any? {|bt| bt =~ /benry\/microrake\.rb/ }
        backtrace = main.instance_eval { filter_backtrace(exc.backtrace) }
        ok {backtrace}.NOT.any? {|bt| bt =~ /benry\/microrake\.rb/ }
      end

    end


  end


end
