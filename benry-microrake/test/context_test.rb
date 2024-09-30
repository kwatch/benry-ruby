# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::BaseTaskContext do

    fixture :manager do
      Benry::MicroRake::TASK_MANAGER
    end

    fixture :context do |manager|
      Benry::MicroRake::BaseTaskContext.new(manager)
    end


    topic '#current_task()' do

      spec "[!6ly31] returns current task object." do
        |context|
        curr_task = nil
        tsk = task :foo do
          curr_task = current_task()
        end
        context.run_task(tsk)
        ok {curr_task}.same?(tsk)
      end

    end


    topic '#run_task()' do

      spec "[!4gsle] accepts either a task name or a task object." do
        |context|
        done1 = nil
        tsk1 = task :ex1 do
          done1 = true
        end
        done2 = nil
        tsk2 = task :ex2 do
          done2 = true
        end
        #
        done1 = false
        context.run_task(:ex1)
        ok {done1} == true
        #
        done2 = false
        context.run_task(tsk2)
        ok {done2} == true
      end

      spec "[!ngmx8] raises error when task not found corresponding the task name." do
        |context|
        done = false
        tsk = task :ex3 do
          done = true
        end
        pr = proc { context.run_task(:ex333) }
        ok {pr}.raise?(Benry::MicroRake::TaskExecutionError,
                       "run_task(:ex333): Task not found.")
      end

      spec "[!7iwdq] sets current task object." do
        |context|
        curr = nil
        tsk = task :ex4 do
          curr = current_task()
        end
        context.run_task(:ex4)
        ok {curr}.same?(tsk)
      end

      spec "[!bfo06] runs task object in this context with args and opts." do
        |context|
        name_ = nil
        lang_ = nil
        desc "task 5", {
               :lang => ["-l, --lang=<LANG>", "language"],
             }
        task :ex5 do |name, lang: nil|
          name_ = name
          lang_ = lang
        end
        context.run_task(:ex5, "Alice", lang: "fr")
        ok {name_} == "Alice"
        ok {lang_} == "fr"
      end

      spec "[!yi2du] recovers previous task object." do
        |context|
        tasklist = []
        pre = task :pre6 do
          tasklist << current_task()
        end
        tsk = task :ex6 => :pre6 do
          tasklist << current_task()
        end
        context.run_task(:ex6)
        ok {tasklist}.length(2)
        ok {tasklist[0]}.same?(pre)
        ok {tasklist[1]}.same?(tsk)
      end

    end


    topic '#_run_task()' do

      spec "[!bu56r] task should not be run more than once." do
        |context|
        n = 0
        task :ex1 do
          n += 1
        end
        ok {n} == 0
        context.run_task(:ex1)
        ok {n} == 1
        context.run_task(:ex1)
        ok {n} == 1
        context.run_task(:ex1)
        ok {n} == 1
      end

      spec "[!c9gie] when trace mode is on, skipped task will be reported." do
        |context|
        $TRACE_MODE = true
        n = 0
        task :ex2 do
          n += 1
        end
        sout, serr = capture_sio(tty: true) do
          context.run_task(:ex2)
          context.run_task(:ex2)
          context.run_task(:ex2)
        end
        ok {serr} == "\e[33m** enter: ex2\e[0m\n"\
                     "\e[33m** exit:  ex2\e[0m\n"\
                     "\e[33m** skip:  ex2  (alrady done)\e[0m\n"\
                     "\e[33m** skip:  ex2  (alrady done)\e[0m\n"
        ok {sout} == ""
      end

      spec "[!mrqag] returns false if the task is skipped." do
        |context|
        n = 0
        task :ex3 do
          n += 1
        end
        ok {context.run_task(:ex3)} == true
        ok {context.run_task(:ex3)} == false
        ok {context.run_task(:ex3)} == false
      end

      spec "[!jm3sj] when trace mode is on, entering task will be reported." do
        |context|
        $TRACE_MODE = true
        n = 0
        task :ex4 do
          n += 1
        end
        sout, serr = capture_sio(tty: true) do
          context.run_task(:ex4)
        end
        ok {serr} == "\e[33m** enter: ex4\e[0m\n"\
                     "\e[33m** exit:  ex4\e[0m\n"
        ok {sout} == ""
      end

      spec "[!y9b9m] run tasks in liked list." do
        |context|
        n = 0
        task :ex5 do n += 1 end
        task :ex5 do n += 9 end
        task :ex5 do n += 90 end
        ok {n} == 0
        context.run_task(:ex5)
        ok {n} == 100
      end

      spec "[!tyayh] when trace mode is on, next task name will be reported." do
        |context|
        $TRACE_MODE = true
        n = 0
        task :ex6 do n += 1 end
        task :ex6 do n += 9 end
        task :ex6 do n += 90 end
        sout, serr = capture_sio(tty: true) do
          context.run_task(:ex6)
        end
        ok {n} == 100
        ok {serr} == "\e[33m** enter: ex6\e[0m\n"\
                     "\e[33m** next:  ex6\e[0m\n"\
                     "\e[33m** next:  ex6\e[0m\n"\
                     "\e[33m** exit:  ex6\e[0m\n"
        ok {sout} == ""
      end

      spec "[!wz73x] detects cyclic task." do
        |context|
        $TRACE_MODE = true
        task :ex7a => :ex7b do end
        task :ex7b => :ex7c do end
        task :ex7c => :ex7d do end
        task :ex7d => [:ex7e, :ex7b] do end
        task :ex7e do end
        pr = proc do
          capture_sio(tty: false) do
            context.run_task(:ex7a)
          end
        end
        ok {pr}.raise?(Benry::MicroRake::CyclicTaskError,
                       "Cyclic task detected. (ex7b->ex7c->ex7d->ex7b)\n"\
                       "    ex7b                 : test/context_test.rb:207\n"\
                       "    ex7c                 : test/context_test.rb:208\n"\
                       "    ex7d                 : test/context_test.rb:209\n"\
                       "    ex7b                 : test/context_test.rb:207")
      end

      spec "[!6026e] prerequisite tasks are invoked before the target task." do
        |context|
        dones = []
        task :pre8a => :pre8b do
          dones << :pre8a
        end
        task :pre8b do
          dones << :pre8b
        end
        task :ex8 => :pre8a do
          dones << :ex8
        end
        context.run_task(:ex8)
        ok {dones} == [:pre8b, :pre8a, :ex8]
      end

      spec "[!xp4d9] raises error when prerequisite task is not found." do
        |context|
        task :ex9 => :pre9 do end
        pr = proc do
          context.run_task(:ex9)
        end
        ok {pr}.raise?(Benry::MicroRake::TaskExecutionError,
                       "pre9: Prerequisite task not found.")
      end

      spec "[!1nzl9] prerequisite tasks are invoked without args nor opts." do
        |context|
        pre_called_with = nil
        task :pre10 do |*args, **kwargs|
          pre_called_with = [args, kwargs]
        end
        tsk_called_with = nil
        task :ex10 => :pre10 do |*args, **kwargs|
          tsk_called_with = [args, kwargs]
        end
        context.run_task(:ex10, "a", "b", x: 10)
        ok {tsk_called_with} == [["a", "b"], {x: 10}]
        ok {pre_called_with} == [[], {}]
      end

      spec "[!kc2jt] when trace mode is on, exiting task will be reported." do
        |context|
        $TRACE_MODE = true
        n = 0
        task :ex11 do
          n += 1
        end
        sout, serr = capture_sio(tty: true) do
          context.run_task(:ex11)
        end
        ok {serr} == "\e[33m** enter: ex11\e[0m\n"\
                     "\e[33m** exit:  ex11\e[0m\n"
        ok {sout} == ""
      end

      spec "[!n1amc] records the task as 'done'." do
        |context|
        tsk = task :ex12 do end
        context.run_task(:ex12)
        dones = context.instance_eval { @__dones }
        ok {dones}.key?(tsk.object_id)
      end

      spec "[!ejxdf] returns true if the task is invoked." do
        |context|
        tsk = task :ex12 do end
        ret = context.run_task(:ex12)
        ok {ret} == true
      end

    end


    topic '#_invoke_task()' do

      spec "[!sahtx] simulates Rake when the task has argnames such as `task :foo, [:x, :y]`." do
        |context|
        x_ = y_ = nil
        task :ex21, [:x, :y] do |t, args|
          x_ = args.x
          y_ = args[:y]
        end
        context.run_task(:ex21, "abc", 123)
        ok {x_} == "abc"
        ok {y_} == 123
      end

      spec "[!tx0yq] task block will be invoked with this conext object as `self`." do
        |context|
        self_ = nil
        task :ex22 do
          self_ = self
        end
        context.run_task(:ex22)
        ok {self_}.same?(context)
      end

      spec "[!86mhe] do nothing when task has no blocks." do
        |context|
        called = []
        task :pre23 do called << :pre23 end
        task :ex23 => :pre23
        context.run_task(:ex23)
        ok {called} == [:pre23]
      end

    end


    topic '#_normalize()' do

      spec "[!uhw1e] converts a symbol object to a string." do
        |context|
        context.instance_exec(self) do |_|
          _.ok {_normalize(:foobar)} == "foobar"
        end
      end

      spec "[!a7159] converts 'aa-bb-cc' to 'aa_bb_cc'." do
        |context|
        context.instance_exec(self) do |_|
          _.ok {_normalize("foo-bar-baz")} == "foo_bar_baz"
        end
      end

    end


    topic '#_with_running()' do

      spec "[!5roqu] pushs task object into a stack before running the task." do
        |context|
        running1 = nil
        pre = task :pre31 do
          running1 = context.instance_eval { @__running }.dup()
        end
        tsk = task :ex31 => :pre31
        context.run_task(:ex31)
        ok {running1} == [tsk, pre]
      end

      spec "[!3iu4t] pops task object from a stack after running the task." do
        |context|
        running1 = nil
        pre = task :pre32 do
          running1 = context.instance_eval { @__running }.dup()
        end
        running2 = nil
        tsk = task :ex32 => :pre32 do
          running2 = context.instance_eval { @__running }.dup()
        end
        context.run_task(:ex32)
        ok {running1} == [tsk, pre]
        ok {running2} == [tsk]
        ok {context.instance_eval { @__running } } == []
      end

    end


    topic '#_report_trace()' do

      spec "[!9ssp0] prints the message into stderr." do
        |context|
        sout, serr = capture_sio() do
          context.instance_eval { _report_trace("foobar") }
        end
        ok {sout} == ""
        ok {serr} == "** foobar\n"
      end

      spec "[!bb29o] prints the message in color if stderr is a tty." do
        |context|
        sout, serr = capture_sio(tty: true) do
          context.instance_eval { _report_trace("foobar") }
        end
        ok {sout} == ""
        ok {serr} == "\e[33m** foobar\e[0m\n"
      end

      spec "[!ovbu9] prints the message without color if stderr is not a tty." do
        |context|
        sout, serr = capture_sio(tty: false) do
          context.instance_eval { _report_trace("foobar") }
        end
        ok {sout} == ""
        ok {serr} == "** foobar\n"
      end

      spec "[!pah14] the message will be indented in prerequisite task." do
        |context|
        $TRACE_MODE = true
        task :pre do end
        task :ex4 => :pre do end
        sout, serr = capture_sio() do
          context.run_task(:ex4)
        end
        ok {sout} == ""
        ok {serr} == "** enter: ex4\n"\
                     "**  enter: pre\n"\
                     "**  exit:  pre\n"\
                     "** exit:  ex4\n"
      end

    end

  end


  topic Benry::MicroRake::TaskContext do

    fixture :manager do
      Benry::MicroRake::TASK_MANAGER
    end

    fixture :context do |manager|
      Benry::MicroRake::TaskContext.new(manager)
    end


    topic '#initialize()' do

      spec "[!bb8ua] prompt string should be set." do
        |context|
        label = context.instance_eval { @fileutils_label }
        ok {label} == "\e[90m[urake]\e[0m$ "
      end

    end


    topic '#prompt()' do

      spec "[!uj8em] returns colorized prompt string when stdout is a tty." do
        |context|
        s = nil
        capture_sio(tty: true) do
          s = context.prompt()
        end
        ok {s} == "\e[90m[urake]\e[0m$ "
      end

      spec "[!58pra] returns non-colorized prompt string when stdout is not a tty." do
        |context|
        s = nil
        capture_sio(tty: false) do
          s = context.prompt()
        end
        ok {s} == "[urake]$ "
      end

      spec "[!ipvqi] prompt string should be indented according to nest of 'cd()'." do
        |context|
        capture_sio(tty: false) do
          context.instance_exec(self) do |_|
            _.ok {prompt()} == "[urake]$ "
            cd "." do
              _.ok {prompt()} == "[urake]$  "      # !!!
              cd "." do
                _.ok {prompt()} == "[urake]$   "   # !!!
              end
            end
            _.ok {prompt()} == "[urake]$ "
          end
        end
      end

    end

  end


end
