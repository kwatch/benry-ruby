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

    end


    topic '#handle_global_opts()' do

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
              _.ok {handle_global_opts({sym => true})} == true
            end
            false_options.each do |sym|
              _.ok {handle_global_opts({sym => true})} == false
            end
            _.ok {handle_global_opts({:libdir => [libdir]})} == false
          end
        end
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


  end


end
