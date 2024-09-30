# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::CommandActionHandler do

    fixture :handler do
      mgr = Benry::MicroRake::TASK_MANAGER
      gopt_schema = Benry::MicroRake::MainApp::GLOBAL_OPTION_SCHEMA
      Benry::MicroRake::CommandActionHandler.new("urake4", gopt_schema, mgr)
    end


    topic '#help_message()' do

      spec "[!tel3c] returns help message." do
        |handler|
        ok {handler.help_message("urake4")} == <<END
\e[1mMicroRake\e[0m (0.0.0) --- Better Rake, args & options available for every task.

\e[36mUsage:\e[0m
  \e[1murake4\e[0m [<options>] <task> [<arguments...>]

\e[36mOptions:\e[0m
  -A, --all               : include hidden tasks for '-T'
      --backtrace         : print backtrace when error raised
  -C, --directory=<dir>   : change directory (tips: '-C .' not change dir)
  -D, --describe          : list tasks with description
  -e, --execute=<code>    : execute Ruby code and exit
  -E, --execute-continue=<code> : execute Ruby code and NOT exit
  -f, --taskfile=<file>   : Taskfile name (default: Taskfile.rb)
      --rakefile=<file>   : same as '--taskfile' (for Rake compatibility)
  -F <regexp>             : filter tasks for -T/-D/-P/-W
  -I, --libdir=<dir>      : add dir to library path (multiple ok)
  -l                      : list tasks without command name
  -n, --dry-run           : dry-run mode (not execute)
  -N, --no-search         : not search taskfile in parent dir
      --new               : print example code of taskfile
  -P, --prereqs           : detect cyclic task dependencies
  -q, --quiet             : quiet mode (suppress echoback)
  -s, --silent            : silent mode (more quiet)
  -T, --tasks             : list tasks with command name
  -u                      : use 'Rakefile' instead of 'Taskfile.rb'
  -V, --version           : print version
  -t, --trace             : trace task call with backtrace enabled
  -W, --where             : filepath and lineno where task defined
  -h, --help              : print help message

\e[36mTasks:\e[0m
  Run `urake4 -T` to list task names.

\e[36mExample:\e[0m
  $ urake4 --new > Taskfile.rb     # generate an example taskfile
  $ urake4 -T                      # list tasks
  $ urake4 hello                   # run a task
  $ urake4 hello Alice --lang=fr   # run a task with args and options
  $ urake4 hello --help            # (or '-h') help message of the task
END
      end

    end


    topic '#short_usage()' do

      spec "[!znc5e] changes hint message according to whether taskfile exists or not." do
        |handler|
        taskfile_exists = true
        s1 = handler.short_usage("urake4", taskfile_exists)
        ok {s1} =~ /^\(Hint: Run \`urake4 -h\` for help, and \`urake4 -T\` for task list.\)$/
        taskfile_exists = false
        s2 = handler.short_usage("urake4", taskfile_exists)
        ok {s2} =~ /^\(Hint: Run \`urake4 -h\` for help, and \`urake4 --new\` to create 'Taskfile.rb'.\)$/
      end

      spec "[!74761] returns short usage message." do
        |handler|
        s1 = handler.short_usage("urake4", true)
        ok {s1} == "Usage: urake4 [<options>] <task>\n"\
                   "\n"\
                   "(Hint: Run `urake4 -h` for help, and `urake4 -T` for task list.)\n"
        s2 = handler.short_usage("urake4", false)
        ok {s2} == "Usage: urake4 [<options>] <task>\n"\
                   "\n"\
                   "(Hint: Run `urake4 -h` for help, and `urake4 --new` to create 'Taskfile.rb'.)\n"
      end

    end


    topic '#do_help()' do

      spec "[!y7sxx] prints help message in color if stdout is a tty." do
        |handler|
        sout = capture_sout(tty: true) { handler.do_help() }
        ok {sout} =~ /^\e\[36mOptions:\e\[0m$/
      end

      spec "[!9yhvu] prints help message without color if stdout is not a tty." do
        |handler|
        sout = capture_sout(tty: false) { handler.do_help() }
        ok {sout} =~ /^Options:$/
      end

    end


    topic '#do_version()' do

      spec "[!azrt9] prints version number." do
        |handler|
        sout = capture_sout { handler.do_version() }
        ok {sout} == Benry::MicroRake::VERSION + "\n"
      end

    end


    topic '#_each_task_with_hyphenized_name()' do

      spec "[!mfmhj] converts task name 'a_b_c' into 'a-b-c'." do
        |handler|
        desc "test"
        task :aa_bb_cc do end
        handler.instance_exec(self) do |_|
          _each_task_with_hyphenized_name(false) do |name, task|
            _.ok {name} == "aa-bb-cc"
            _.ok {task.name} == :aa_bb_cc
          end
        end
      end

      spec "[!wvi9f] sorts by task name." do
        |handler|
        task :bb do end
        task :cc do end
        task :aa do end
        names = []
        handler.instance_eval do
          _each_task_with_hyphenized_name(true) do |name, task|
            names << name
          end
        end
        ok {names} == ["aa", "bb", "cc"]
      end

      def _prepare1()
        desc "foo"
        task :aa do end
        desc "bar", hidden: true
        task :bb do end
        task :cc do end
      end

      spec "[!cth9a] ignores hidden tasks." do
        |handler|
        _prepare1()
        names = []
        handler.instance_eval do
          _each_task_with_hyphenized_name(false) do |name, task|
            names << name
          end
        end
        ok {names} == ["aa"]
      end

      spec "[!uyl6f] includes hidden tasks when '-a' option specified." do
        |handler|
        _prepare1()
        names = []
        handler.instance_eval do
          _each_task_with_hyphenized_name(true) do |name, task|
            names << name
          end
        end
        ok {names} == ["aa", "bb", "cc"]
      end

      spec "[!tgi25] appends task argnames to each task name." do
        |handler|
        desc "foo"
        task :foo, [:x, :y] do end
        names = []
        handler.instance_eval do
          _each_task_with_hyphenized_name(false) do |name, task|
            names << name
          end
        end
        ok {names} == ["foo[x,y]"]
      end

      spec "[!x7bng] yields task name and task object." do
        |handler|
        desc "foo"
        tsk1 = task :foo do end
        tsk2 = task :bar do end
        names = []
        tasks = []
        handler.instance_eval do
          _each_task_with_hyphenized_name(true) do |name, task|
            names << name
            tasks << task
          end
        end
        ok {names} == ["bar", "foo"]
        ok {tasks} == [tsk2, tsk1]
      end

    end


    topic '#_colorize_according_to_task()' do

      spec "[!vdps0] hidden task name will be in gray color." do
        |handler|
        desc "foo", hidden: true
        tsk = task :foo do end
        handler.instance_exec(self) do |_|
          _.ok {_colorize_according_to_task("foo", tsk)} == "\e[2mfoo\e[0m"
        end
      end

      spec "[!hunkk] important task name will be in bold style." do
        |handler|
        desc "foo", important: true
        tsk = task :foo do end
        handler.instance_exec(self) do |_|
          _.ok {_colorize_according_to_task("foo", tsk)} == "\e[1mfoo\e[0m"
        end
      end

    end


    topic '#do_list_tasks()' do

      before do
        require './Taskfile.rb'
      end

      spec "[!h8vwc] lists tasks with command when '-T' specified." do
        |handler|
        sout = capture_sout do
          handler.do_list_tasks(all: false, with_command: true)
        end
        ok {sout} == <<'END'
urake4 clean            # delete garbage files (& product files too if '-a')
urake4 git              # alias for 'git:status:here'
urake4 git:stash        # alias for 'git:stash:list'
urake4 git:stash:list   # list stashes
urake4 git:stash:show   # show stash
urake4 git:status       # git status
urake4 git:status:here  # git status of current directory
urake4 hello            # greeting message
urake4 help             # print help message
END
      end

      spec "[!1kjof] lists tasks without command when '-l' specified." do
        |handler|
        sout = capture_sout do
          handler.do_list_tasks(all: false, with_command: false)
        end
        ok {sout} == <<'END'
clean                # delete garbage files (& product files too if '-a')
git                  # alias for 'git:status:here'
git:stash            # alias for 'git:stash:list'
git:stash:list       # list stashes
git:stash:show       # show stash
git:status           # git status
git:status:here      # git status of current directory
hello                # greeting message
help                 # print help message
END
      end

      spec "[!hi9es] filters task names if '-F' option specified." do
        |handler|
        sout = capture_sout do
          handler.do_list_tasks(all: false, with_command: true, filter: /^he/)
        end
        ok {sout} == <<'END'
urake4 hello            # greeting message
urake4 help             # print help message
END
      end

      spec "[!1ud7j] prints the first line of task description." do
        |handler|
        desc "aa\nbb\ncc\n"
        task :blalbla do end
        sout = capture_sout do
          handler.do_list_tasks(all: false, with_command: true)
        end
        ok {sout} =~ /aa/
        ok {sout} !~ /bb/
        ok {sout} !~ /cc/
      end

      spec "[!0hlgl] colorizes task names." do
        |handler|
        desc "foo", hidden: true
        task :foo do end
        desc "bar", important: true
        task :bar do end
        sout = capture_sout(tty: true) do
          handler.do_list_tasks(all: true, with_command: true)
        end
        ok {sout} =~ /^\e\[2murake4 foo +\# foo\e\[0m$/
        ok {sout} =~ /^\e\[1murake4 bar +\# bar\e\[0m$/
      end

      spec "[!i8chw] lists tasks without color when stdout is not a tty." do
        |handler|
        desc "foo", hidden: true
        task :foo do end
        desc "bar", important: true
        task :bar do end
        sout = capture_sout(tty: false) do
          handler.do_list_tasks(all: true, with_command: true)
        end
        ok {sout} =~ /^urake4 foo +\# foo$/
        ok {sout} =~ /^urake4 bar +\# bar$/
      end

    end


    topic '#do_list_descriptions()' do

      before do
        require './Taskfile.rb'
      end

      spec "[!nu0sw] list task names and descriptions." do
        |handler|
        sout = capture_sout { handler.do_list_descriptions() }
        ok {sout} == <<END
urake4 clean
    delete garbage files (& product files too if '-a')

urake4 git
    alias for 'git:status:here'

urake4 git:stash
    alias for 'git:stash:list'

urake4 git:stash:list
    list stashes

urake4 git:stash:show
    show stash

urake4 git:status
    git status

urake4 git:status:here
    git status of current directory

urake4 hello
    greeting message

urake4 help
    print help message

END
      end

      spec "[!q6ygj] ignores if task name not matched to filter." do
        |handler|
        sout = capture_sout { handler.do_list_descriptions(filter: /^he/) }
        ok {sout} == <<END
urake4 hello
    greeting message

urake4 help
    print help message

END
      end

      def _prepare1()
        desc "foo", hidden: true
        task :foo do end
        desc "bar", important: true
        task :bar do end
      end

      spec "[!gmx0k] colorizes task names." do
        |handler|
        _prepare1()
        sout = capture_sout(tty: true) { handler.do_list_descriptions(all: true) }
        ok {sout} =~ /\e\[2murake4 foo\e\[0m$/
        ok {sout} =~ /^    foo$/
        ok {sout} =~ /\e\[1murake4 bar\e\[0m$/
        ok {sout} =~ /^    bar$/
      end

      spec "[!1i8x1] adds indent to each line of description." do
        |handler|
        desc (s="aa\nbb\ncc\n")
        task :aa_bb_cc do end
        expected = /^urake4 aa-bb-cc\n    aa\n    bb\n    cc\n\nurake4/
        sout = capture_sout(tty: true) { handler.do_list_descriptions(all: true) }
        ok {sout} =~ expected
        #
        s.sub!(/\n\z/, '')
        sout = capture_sout(tty: true) { handler.do_list_descriptions(all: true) }
        ok {sout} =~ expected
      end

      spec "[!ur9bl] lists tasks without color when stdout is not a tty." do
        |handler|
        _prepare1()
        sout = capture_sout(tty: true) { handler.do_list_descriptions(all: true) }
        ok {sout} =~ /\e\[2murake4 foo\e\[0m$/
        ok {sout} =~ /\e\[1murake4 bar\e\[0m$/
        sout = capture_sout(tty: false) { handler.do_list_descriptions(all: true) }
        ok {sout} =~ /^urake4 foo$/
        ok {sout} =~ /^urake4 bar$/
      end

    end


    topic '#do_list_locations()' do

      before do
        require './Taskfile.rb'
      end

      fixture :linenums do |taskfile|
        arr = File.read(taskfile).each_line.to_a
        i = 0
        d = {}
        arr.each_with_index do |line, i|
          if line =~ /task :(\w+)/
            d[$1] = i+1
          end
        end
        d
      end

      spec "[!1j4cl] ignores if task name not matched to filter." do
        |handler, linenums|
        ln1 = linenums['hello']
        ln2 = linenums['help']
        sout = capture_sout(tty: false) { handler.do_list_locations(filter: /^he/) }
        ok {sout} == <<"END"
hello                     ./Taskfile.rb:#{ln1}
help                      ./Taskfile.rb:#{ln2}
END
      end

      spec "[!io3vq] shorten locations." do
        |handler, linenums|
        ln1 = linenums['hello']
        sout = capture_sout(tty: false) { handler.do_list_locations() }
        ok {sout} =~ /^hello +\.\/Taskfile\.rb:#{ln1}$/
      end

      def _prepare1()
        desc "foo", hidden: true
        task :foo do end
        desc "bar", important: true
        task :bar do end
        return __LINE__ - 3, __LINE__ - 1
      end

      spec "[!oqwim] colorizes tasks and locations." do
        |handler|
        ln1, ln2 = _prepare1()
        sout = capture_sout(tty: true) { handler.do_list_locations(all: true, filter: /foo|bar/) }
        ok {sout} == <<"END"
\e[1mbar                      \e[0m test/actionhandler_test.rb:#{ln2}
\e[2mfoo                      \e[0m test/actionhandler_test.rb:#{ln1}
END
      end

      spec "[!17q9m] lists task locations without color when stdout is not a tty." do
        |handler|
        ln1, ln2 = _prepare1()
        sout = capture_sout(tty: false) { handler.do_list_locations(all: true, filter: /foo|bar/) }
        ok {sout} == <<"END"
bar                       test/actionhandler_test.rb:#{ln2}
foo                       test/actionhandler_test.rb:#{ln1}
END
      end

    end


    topic '#do_list_prerequisites()' do

      before do
        desc "ex1"
        task :ex1 => [:ex2, :ex3] do end
        desc "ex2"
        task :ex2 => [:ex3, :ex4] do end
        desc "ex3"
        task :ex3 => :ex4 do end
        desc "ex4"
        task :ex4 do end
      end

      spec "[!50vab] ignores hidden task if '-A' not specified." do
        |handler|
        mgr = handler.instance_variable_get(:@task_manager)
        mgr.get_task(:ex1).instance_variable_set(:@desc, nil)
        mgr.get_task(:ex2).instance_variable_set(:@desc, nil)
        sout = capture_sout { handler.do_list_prerequisites() }
        ok {sout} == <<END
ex3
    ex4
ex4
END
      end

      spec "[!0oe25] ignores if task name not matched to filter." do
        |handler|
        sout = capture_sout { handler.do_list_prerequisites(filter: /ex[23]/) }
        ok {sout} == <<END
ex2
    ex3
        ex4
    ex4
ex3
    ex4
END
      end

      spec "[!3pfri] lists task names with prerequisite tasks." do
        |handler|
        sout = capture_sout { handler.do_list_prerequisites() }
        ok {sout} == <<END
ex1
    ex2
        ex3
            ex4
        ex4
    ex3
        ex4
ex2
    ex3
        ex4
    ex4
ex3
    ex4
ex4
END
      end

    end


    topic '#_traverse_prerequeistes()' do

      before do
        desc "ex1"
        task :ex1 => [:ex2, :ex3] do end
        desc "ex2"
        task :ex2 => [:ex3, :ex4] do end
        desc "ex3"
        task :ex3 => :ex4 do end
        desc "ex4"
        task :ex4 do end
        n = __LINE__
        @_linenums = [n-7, n-5, n-3, n-1]
      end

      spec "[!u9pr4] raises error if cyclic task exists." do
        |handler|
        task :ex4 => :ex2 do end
        ln4 = __LINE__ - 1
        _, ln2, ln3, _ = @_linenums
        pr = proc do
          handler.do_list_prerequisites()
        end
        ok {pr}.raise?(Benry::MicroRake::CyclicTaskError,
                       "Cyclic task detected. (ex2->ex3->ex4->ex2)\n\e[2m"\
                       "    ex2                  : test/actionhandler_test.rb:#{ln2}\n"\
                       "    ex3                  : test/actionhandler_test.rb:#{ln3}\n"\
                       "    ex4                  : test/actionhandler_test.rb:#{ln4}\n"\
                       "    ex2                  : test/actionhandler_test.rb:#{ln2}\e[0m")
      end

      spec "[!41w2a] task names should be hyphenized." do
        |handler|
        task :pre_1 do end
        desc "aa bb cc"
        task :aa_bb_cc => :pre_1 do end
        sout = capture_sout { handler.do_list_prerequisites() }
        ok {sout} =~ /^aa-bb-cc\n    pre-1\n/
      end

      spec "[!bkj2c] prerequiste task names are indented." do
        |handler|
        sout = capture_sout { handler.do_list_prerequisites(filter: /ex1/) }
        ok {sout} == <<END
ex1
    ex2
        ex3
            ex4
        ex4
    ex3
        ex4
END
      end

      spec "[!i6p8r] error if prerequisite task is not found." do
        |handler|
        desc "ex9"
        task :ex9 => :pre9 do end
        pr = proc { handler.do_list_prerequisites() }
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError,
                       "pre9: Prerequisite task not found.")
      end

    end


    topic '#_traverse_task()' do

      spec "[!9b2ge] yileds block with task and traverses next task." do
        |handler|
        task :pre1 do end
        task :pre2 do end
        desc "ex8"
        task :ex8 => :pre1 do end
        task :ex8 => :pre2 do end
        sout = capture_sout { handler.do_list_prerequisites(filter: /ex8/) }
        ok {sout} == <<END
ex8
    pre1
    pre2
END
      end

    end


    topic '#do_exec_code()' do

      spec "[!w3c3o] executes ruby code if provided." do
        |handler|
        sout = capture_sout { handler.do_exec_code("p 123") }
        ok {sout} == "123\n"
      end

      spec "[!anihk] do nothing if ruby code is nil." do
        |handler|
        sout = capture_sout { handler.do_exec_code(nil) }
        ok {sout} == ""
      end

    end


    topic '#do_new_taskfile()' do

      spec "[!8mz1b] prints taskfile skeleton." do
        |handler|
        sout = capture_sout { handler.do_new_taskfile() }
        ok {sout} =~ /^task :clean do /
        ok {sout} =~ /^task :hello do /
      end

    end


    topic '#do_when_no_tasks_specified()' do

      spec "[!ldvle] prints short usage in color." do
        |handler|
        sout = capture_sout { handler.do_when_no_tasks_specified(true) }
        ok {sout} == <<END
Usage: urake4 [<options>] <task>

(Hint: Run `urake4 -h` for help, and `urake4 -T` for task list.)
END
      end

      spec "[!3rlt8] prints without color if stdout is not a tty." do
        |handler|
        sout = capture_sout { handler.do_when_no_tasks_specified(false) }
        ok {sout} == <<END
Usage: urake4 [<options>] <task>

(Hint: Run `urake4 -h` for help, and `urake4 --new` to create 'Taskfile.rb'.)
END
      end

    end


  end


end
