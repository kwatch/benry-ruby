# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::TaskManager do

    fixture :manager do
      Benry::MicroRake::TaskManager.new()
    end


    topic '#add_task()' do

      spec "[!8bzd4] registers a task." do
        |manager|
        tsk = task :ex301 do
          nil
        end
        ok {manager.get_task(:ex301)} == nil
        manager.add_task(tsk)
        ok {manager.get_task(:ex301)}.same?(tsk)
      end

    end


    topic '#get_task()' do

      spec "[!hyit0] returns a task." do
        |manager|
        tsk = task :ex302 do
          nil
        end
        ok {manager.get_task(:ex302)} == nil
        manager.add_task(tsk)
        ok {manager.get_task(:ex302)}.same?(tsk)
      end

    end


    topic '#has_task?()' do

      spec "[!587bq] returns true if a task exist, false if not." do
        |manager|
        tsk = task :ex303 do
          nil
        end
        ok {manager.has_task?(:ex303)} == false
        manager.add_task(tsk)
        ok {manager.has_task?(:ex303)} == true
      end

    end


    topic '#delete_task()' do

      spec "[!yftry] deletes a task." do
        |manager|
        tsk = task :ex304 do
          nil
        end
        manager.add_task(tsk)
        ok {manager.has_task?(:ex304)} == true
        manager.delete_task(:ex304)
        ok {manager.has_task?(:ex304)} == false
      end

    end


    topic '#each_task()' do

      spec "[!9033a] returns Enumerator object if block not given." do
        |manager|
        tsk1 = task :ex305a do end
        tsk2 = task :ex305b do end
        manager.add_task(tsk1)
        manager.add_task(tsk2)
        ok {manager.each_task()}.is_a?(Enumerator)
        arr = manager.each_task.to_a
        ok {arr} == [tsk1, tsk2]
      end

      spec "[!z3vg1] yields block with each task object." do
        |manager|
        tsk1 = task :ex306a do end
        tsk2 = task :ex306b do end
        manager.add_task(tsk1)
        manager.add_task(tsk2)
        arr = []
        manager.each_task() do |x|
          arr << x
        end
        ok {arr} == [tsk1, tsk2]
      end

    end


    topic '#find_task()' do

      spec "[!120pp] can accepts Symbol as well as String." do
        |manager|
        tsk = task :ex401 do
        end
        manager.add_task(tsk)
        ok {manager.find_task(:ex401 , nil)}.same?(tsk)
        ok {manager.find_task("ex401", nil)}.same?(tsk)
      end

      spec "[!z4w9l] regards task name starting with ':' as absolute name." do
        |manager|
        tsk1 = task :ex402 do end
        tsk2 = nil
        namespace :ns402 do
          tsk2 = task :ex402 do end
        end
        manager.add_task(tsk1)
        manager.add_task(tsk2)
        ok {manager.find_task("ex402" , nil)}.same?(tsk1)
        ok {manager.find_task("ex402", "ns402")}.same?(tsk2)
        ok {manager.find_task(":ex402", "ns402")}.same?(tsk1)  # !!!
      end

      spec "[!co6ic] base task can be a task object." do
        |manager|
        tsk1 = tsk2 = nil
        namespace :ns403 do
          tsk1 = task :ex403a do end
          tsk2 = task :ex403b do end
        end
        manager.add_task(tsk1)
        manager.add_task(tsk2)
        ok {manager.find_task("ex403b" , tsk1)}.same?(tsk2)
        ok {manager.find_task("ex403a" , tsk2)}.same?(tsk1)
      end

      spec "[!2a4n5] base task may be nil." do
        |manager|
        tsk1 = task :ex404 do end
        tsk2 = nil
        namespace :ns404 do
          tsk2 = task :ex404 do end
        end
        manager.add_task(tsk1)
        manager.add_task(tsk2)
        ok {manager.find_task("ex404" , nil)}.same?(tsk1)
      end

      spec "[!k6lza] base task can be a namespace string." do
        |manager|
        tsk1 = task :ex405 do end
        tsk2 = nil
        namespace :ns405 do
          tsk2 = task :ex405 do end
        end
        manager.add_task(tsk1)
        manager.add_task(tsk2)
        ok {manager.find_task("ex405" , "ns405")}.same?(tsk2)
      end

      spec "[!mdge0] searches a task according to namespace of base task." do
        |manager|
        tsk1 = tsk2 = tsk3 = nil
        namespace :ns406 do
          tsk1 = task :ex406a do end
          namespace :child do
            tsk2 = task :ex406b do end
            tsk3 = task :ex406c do end
          end
        end
        manager.add_task(tsk1)
        manager.add_task(tsk2)
        manager.add_task(tsk3)
        ok {manager.find_task("ex406a"       , tsk3)}.same?(tsk1)
        ok {manager.find_task("child:ex406b" , tsk1)}.same?(tsk2)
        ok {manager.find_task("child:ex406c" , tsk2)}.same?(tsk3)
      end

      spec "[!mq6gk] find a task object when not found in namespace." do
        |manager|
        tsk2 = tsk3 = nil
        tsk1 = task :ex407a do end
        namespace :ns407 do
          tsk2 = task :ex407b do end
          namespace :child do
            tsk3 = task :ex407c do end
          end
        end
        manager.add_task(tsk1)
        manager.add_task(tsk2)
        manager.add_task(tsk3)
        ok {manager.find_task("ex407a", tsk2   )}.same?(tsk1)
        ok {manager.find_task(:ex407a , tsk3   )}.same?(tsk1)
        ok {manager.find_task(:ex407a , "ns407")}.same?(tsk1)
      end

    end


    topic '#run_task()' do

      spec "[!ay12h] invokes a task with new context object." do
        |manager|
        tsk = nil
        ctx = nil
        namespace :ns408 do
          tsk = task :ex408 do
            ctx = self
          end
        end
        #manager.add_task(tsk)
        manager.run_task(tsk)
        ok {ctx}.is_a?(Benry::MicroRake::TaskContext)
      end

      spec "[!htt27] invokes a task with args and opts." do
        |manager|
        a_ = b_ = x_ = y_ = nil
        tsk = task :ex409 do |a, b="B", x: nil, y: nil|
          a_ = a; b_ = b; x_ = x; y_ = y
        end
        #manager.add_task(tsk)
        manager.run_task(tsk, "aa", x: "xx", y: "yy")
        ok {a_} == "aa"
        ok {b_} == "B"
        ok {x_} == "xx"
        ok {y_} == "yy"
      end

      spec "[!1bufa] retruns a context object in which task block invoked." do
        |manager|
        ctx = nil
        tsk = task :ex410a do
          ctx = self
        end
        ret = manager.run_task(tsk)
        ok {ctx}.is_a?(Benry::MicroRake::TaskContext)
        ok {ret}.same?(ctx)
      end

    end


    topic '#_normalize()' do

      spec "[!emsee] converts a Symbol object to a String object." do
        |manager|
        manager.instance_exec(self) do |_|
          _.ok {_normalize(:foo)} == "foo"
        end
      end

      spec "[!ti173] converts \"aa-bb-cc\" to \"aa_bb_cc\"." do
        |manager|
        manager.instance_exec(self) do |_|
          _.ok {_normalize("aa-bb-cc")} == "aa_bb_cc"
        end
      end

    end


    topic '.detect_cyclic_task()' do

      fixture :tasks do
        t1 = task :ex501 do end
        t2 = task :ex502 do end
        t3 = task :ex503 do end
        t4 = task :ex504 do end
        [t1, t2, t3, t4]
      end

      spec "[!7yqf8] raises error if a task object found in a stack." do
        |tasks|
        pr = proc do
          Benry::MicroRake::TaskManager.detect_cyclic_task(tasks.first, tasks)
        end
        ok {pr}.raise?(Benry::MicroRake::CyclicTaskError,
                       /^Cyclic task detected\./)
      end

      spec "[!lz5ap] cycled task names are joined with '->'." do
        |tasks|
        pr = proc do
          Benry::MicroRake::TaskManager.detect_cyclic_task(tasks[1], tasks)
        end
        ok {pr}.raise?(Benry::MicroRake::CyclicTaskError,
                       /\(ex502->ex503->ex504->ex502\)/)
      end

      spec "[!yeapj] task locations are included in error message." do
        |tasks|
        pr = proc do
          capture_sio(tty: false) do
            Benry::MicroRake::TaskManager.detect_cyclic_task(tasks.first, tasks)
          end
        end
        ok {pr}.raise?(Benry::MicroRake::CyclicTaskError,
                       "Cyclic task detected. (ex501->ex502->ex503->ex504->ex501)\n"\
                       "    ex501                : test/manager_test.rb:273\n"\
                       "    ex502                : test/manager_test.rb:274\n"\
                       "    ex503                : test/manager_test.rb:275\n"\
                       "    ex504                : test/manager_test.rb:276\n"\
                       "    ex501                : test/manager_test.rb:273")
      end

      spec "[!3lh5l] task locations are printed in gray color if stdout is a tty." do
        |tasks|
        pr = proc do
          capture_sio(tty: true) do
            Benry::MicroRake::TaskManager.detect_cyclic_task(tasks.first, tasks)
          end
        end
        ok {pr}.raise?(Benry::MicroRake::CyclicTaskError,
                       "Cyclic task detected. (ex501->ex502->ex503->ex504->ex501)\n"\
                       "\e[2m    ex501                : test/manager_test.rb:273\n"\
                       "    ex502                : test/manager_test.rb:274\n"\
                       "    ex503                : test/manager_test.rb:275\n"\
                       "    ex504                : test/manager_test.rb:276\n"\
                       "    ex501                : test/manager_test.rb:273\e[0m")
      end

    end

  end


end
