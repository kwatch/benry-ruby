# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::Export do


    topic '#desc()' do

      spec "[!sddvl] creates schema object according to option schema definition." do
        desc "desc1", {
               :foo=>["-f, --foo", "foo flag"],
               :bar=>["-b, --bar=<val>", "bar option"],
             }
        schema = @_task_desc[1]
        ok {schema}.is_a?(Benry::MicroRake::TaskOptionSchema)
        ok {schema.get(:foo).short} == "f"
        ok {schema.get(:foo).long} == "foo"
        ok {schema.get(:foo).arg_requireness} == :none
        ok {schema.get(:bar).short} == "b"
        ok {schema.get(:bar).long} == "bar"
        ok {schema.get(:bar).arg_requireness} == :required
      end

      spec "[!f6b6g] `hidden: true` is regarded as `important: false` internally." do
        desc "desc2", {}, hidden: true
        important = @_task_desc[2]
        ok {important} == false
        #
        desc "desc2", {}, important: true
        important = @_task_desc[2]
        ok {important} == true
      end

      spec "[!7fdl0] if `hidden: false` specified, description should not be nil." do
        desc nil, {}, hidden: false
        description = @_task_desc[0]
        ok {description} == ""
        #
        desc nil, {}
        description = @_task_desc[0]
        ok {description} == nil
      end

    end


    topic '#task()' do

      spec "[!cb1wg] records method call location into task object." do
        tsk = task :ex1 do
          nil
        end
        ok {tsk.location}.start_with?("#{__FILE__}:#{__LINE__ - 3}:in `")
      end

      spec "[!bx3sr] creates a new task object and returns it." do
        tsk = task :ex2 do
          nil
        end
        ok {tsk}.is_a?(Benry::MicroRake::Task)
        ok {tsk.name} == :ex2
      end

      spec "[!z313l] if there is other task with same name, then appends new task to it." do
        tsk1 = task :ex3 do
          nil
        end
        tsk2 = task :ex3 do
          nil
        end
        ok {find_task(:ex3)} == tsk1
        ok {find_task(:ex3)} != tsk2
        ok {find_task(:ex3).next_task} == tsk2
      end

      spec "[!8qlbs] new task object should be registered." do
        tsk = task :ex4 do
          nil
        end
        ok {find_task(:ex4)} == tsk
      end

    end


    topic '#task!()' do

      spec "[!7eeci] records method call location into task object." do
        task :ex1 do
          nil
        end
        tsk = task! :ex1 do
          nil
        end
        ok {tsk.location}.start_with?("#{__FILE__}:#{__LINE__ - 3}:in `")
      end

      spec "[!214kt] creates a new task object and returns it." do
        tsk1 = task  :ex2 do; nil; end
        tsk2 = task! :ex2 do; nil; end
        ok {tsk2} != tsk1
      end

      spec "[!29qo8] if there is other task with same name, then removes it and registers new one." do
        tsk1 = task  :ex3 do; nil; end
        tsk2 = task! :ex3 do; nil; end
        ok {find_task(:ex3)} != tsk1
        ok {find_task(:ex3)} == tsk2
      end

      spec "[!oodzr] raises error if there is no task with same name." do
        pr = proc do
          task! :ex4 do; nil; end
        end
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError,
                       "task!(:ex4): Task to overwrite should exist, but not defined.")
      end

    end


    topic '#append_to_task()' do

      spec "[!s8mib] records method call location into task object." do
        task :ex1 do
          nil
        end
        tsk = append_to_task :ex1 do
          nil
        end
        ok {tsk.location}.start_with?("#{__FILE__}:#{__LINE__ - 3}:in `")
      end

      spec "[!bbmoy] raises error if `desc()` is called before this method." do
        task :ex2 do; nil; end
        desc "ex2"
        pr = proc do
          append_to_task :ex2 do; nil; end
        end
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError,
                       "append_to_task(:ex2): Cannot be called with `desc()`.")
      end

      spec "[!km0n6] creates a new task object and returns it." do
        task :ex3 do; nil; end
        tsk = append_to_task :ex3 do; nil; end
        ok {tsk}.is_a?(Benry::MicroRake::Task)
        ok {tsk.name} == :ex3
        ok {tsk.desc} == nil
      end

      spec "[!9aq2i] appends new task object to existing task object." do
        tsk1 = task :ex4 do; nil; end
        tsk2 = append_to_task :ex4 do; nil; end
        ok {tsk1.next_task} == tsk2
      end

      spec "[!usmb1] raises error if other task with same name doesn't exist." do
        pr = proc do
          append_to_task :ex5 do; nil; end
        end
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError,
                       "append_to_task(:ex5): Task should exist, but not defined.")
      end

    end


    topic '#__create_task()' do

      spec "[!277vd] retrieves data set by `desc()`." do
        desc "desc1", {:foo=>["-f, --foo", "foo flag"]}, hidden: true
        tsk = __create_task(:ex1, [:x, :y], "", :task) do |foo: nil| end
        ok {tsk.desc} == "desc1"
        ok {tsk.hidden?} == true
        ok {tsk.schema.get(:foo).short} == "f"
        ok {tsk.schema.get(:foo).long} == "foo"
      end

      spec "[!v3dvm] data should be cleared after retrieved." do
        desc "desc2", {:foo=>["-f, --foo", "foo flag"]}, hidden: true
        ok {@_task_desc} != nil
        __create_task(:ex2, [:x, :y], "", :task) do |foo: nil| end
        ok {@_task_desc} == nil
      end

      spec "[!0jper] retrieves prerequisite names from task name or argnames." do
        tsk1 = task :ex3 => [:pre1, :pre2] do nil end
        ok {tsk1.prerequisites} == [:pre1, :pre2]
        tsk2 = task :ex3, [:x, :y] => [:pre3, :pre4] do nil end
        ok {tsk2.prerequisites} == [:pre3, :pre4]
      end

      spec "[!14p62] considers namespace." do
        tsk = nil
        namespace :foo do
          namespace :bar do
            tsk = task :ex4 do
            end
          end
        end
        ok {tsk.name} == "foo:bar:ex4"
        ok {find_task("foo:bar:ex4")} == tsk
      end

      spec "[!f9z9f] converts argnames into symbols." do
        tsk = task :ex5, ["a", "b"] do nil end
        ok {tsk.argnames} == [:a, :b]
      end

      spec "[!ydlra] creates new task object and returns it." do
        tsk = __create_task(:ex5, nil, nil, :task) do nil end
        ok {tsk}.is_a?(Benry::MicroRake::Task)
        ok {tsk.name} == :ex5
      end

    end


    topic '#__retrieve_prerequisite()' do

      spec "[!nmbok] if task name is a Hash, then retrieves prerequisite names from it." do
        tupl = __retrieve_prerequisite({:ex1 => [:pre1]}, nil, :task)
        task_name, argnames, prerequisites = tupl
        ok {task_name} == :ex1
        ok {argnames} == nil
        ok {prerequisites} == [:pre1]
      end

      spec "[!yysmo] if argnames is a Hash, then retrieves prerequisite names from it." do
        tupl = __retrieve_prerequisite(:ex2 , {[:x, :y] => [:pre2]}, :task)
        task_name, argnames, prerequisites = tupl
        ok {task_name} == :ex2
        ok {argnames} == [:x, :y]
        ok {prerequisites} == [:pre2]
      end

      spec "[!ujwvs] returns task name, argnamens, and prerequisite names." do
        tupl = __retrieve_prerequisite({:ex3 => :pre3}, {:x => :pre4}, :task)
        task_name, argnames, prerequisites = tupl
        ok {task_name} == :ex3
        ok {argnames} == :x
        ok {prerequisites} == :pre4
      end

    end


    topic '#find_task()' do

      spec "[!ja7vq] considers current namespace." do
        tsk = nil
        namespace :foo do
          namespace :bar do
            task :ex1 do; end
            tsk = find_task(:ex1)
          end
        end
        ok {tsk} != nil
        ok {tsk.name} == "foo:bar:ex1"
      end

      spec "[!39ufc] returns task object if task found." do
        task :ex2 do; end
        tsk = find_task(:ex2)
        ok {tsk}.is_a?(Benry::MicroRake::Task)
        ok {tsk.name} == :ex2
      end

      spec "[!kgp19] returns nil if task not found." do
        tsk = find_task(:ex3)
        ok {tsk} == nil
      end

    end


    topic '#task?()' do

      spec "[!2edan] returns true if the task is defined, false otherwise." do
        ok {task?(:ex9)} == false
        task :ex9 do; nil; end
        ok {task?(:ex9)} == true
      end

    end


    topic '#file()' do

      spec "[!ro813] raises NotImplementedError if `file()` is called." do
        pr = proc do
          file "file.o" => "file.c"
        end
        ok {pr}.raise?(NotImplementedError,
                       "'file()' is not implemented in MicroRake.")
      end

    end


    topic '#namespace()' do

      spec "[!dbusz] raises error if namespace name contains '::'." do
        pr = proc do
          namespace "foo::bar" do; end
        end
        ok {pr}.raise?(Benry::MicroRake::NamespaceError,
                       "'foo::bar': Invalid namespace name.")
      end

      spec "[!or5wf] converts namespace name ':foo' or 'foo:' to 'foo' automatically." do
        ns = namespace ":foo" do; end
        ok {ns} == "foo"
        ns = namespace "foo:" do; end
        ok {ns} == "foo"
      end

      spec "[!gzrnb] stacks namespace name with normalized." do
        namespace :foo do
          namespace :bar do
            ok {@_task_namespace} == ["foo", "bar"]
          end
        end
      end

      spec "[!80kn0] registers new alias task if `alias_for:` specified." do
        namespace :git, alias_for: "status:here" do
          namespace :status do
            desc "git status here", {:quiet=>["-q", "quiet"]}, hidden: true
            task :here, [:x, :y] => :pre9 do |quiet: false|
              puts "git status -sb ."
            end
          end
        end
        orig_tsk  = find_task("git:status:here")
        alias_tsk = find_task("git")
        ok {alias_tsk}          != nil
        ok {alias_tsk.name}     == "git"
        ok {alias_tsk.desc}     == "alias for 'git:status:here'"
        ok {alias_tsk.argnames} == [:x, :y]
        ok {alias_tsk.prerequisites} == [:pre9]
        ok {alias_tsk.schema.get(:quiet).short} == "q"
        ok {alias_tsk.location} == orig_tsk.location
        ok {alias_tsk.hidden?}  == true
        ok {alias_tsk.block}    == orig_tsk.block
      end

      spec "[!v1z88] considers namespace when finding original task of alias." do
        namespace :git, alias_for: "status:here" do
          namespace :status do
            desc "git status here"
            task :here do
              puts "git status -sb ."
            end
          end
        end
        orig_tsk  = find_task("git:status:here")
        alias_tsk = find_task("git")
        ok {alias_tsk.block} == orig_tsk.block
      end

      spec "[!elivv] raises error when original task of alias not found." do
        pr = proc do
          namespace :foo, alias_for: :ex5x do
            desc "git status here"
            task :ex5 do; nil; end
          end
        end
        ok {pr}.raise?(Benry::MicroRake::NamespaceError,
                       "'ex5x': No such task.")
      end

      spec "[!bq3ol] creates an alias task which is a clone of original one with different description." do
        namespace :ex6, alias_for: :foo do
          task :foo do; nil; end
        end
        orig_tsk  = find_task("ex6:foo")
        alias_tsk = find_task("ex6")
        ok {alias_tsk.desc} != orig_tsk.desc
        ok {alias_tsk.desc} == "alias for 'ex6:foo'"
      end

      spec "[!uxx3a] namespace name should be popped from namespace stack." do
        ok {@_task_namespace} == nil
        namespace :ex7a do
          ok {@_task_namespace} == ["ex7a"]
          namespace :ex7b do
            ok {@_task_namespace} == ["ex7a", "ex7b"]
          end
          ok {@_task_namespace} == ["ex7a"]
        end
        ok {@_task_namespace} == []
      end

    end


    topic '#use_commands_instead_of_fileutils()' do

      spec "[!9yfrl] disables FileUtils commands.", tag: "skipped" do
        skip_when ENV['TEST_TARGET'] != "skipped",
                  "cannot recover changes on classes and modules"
        require "benry/unixcommand"
        use_commands_instead_of_fileutils(Benry::UnixCommand)
        dummy_file("ex1.txt", "foobar\n")
        task :ex1 do
          compare_file "ex1.txt", "ex1.txt"
        end
        pr = proc do
          Benry::MicroRake::TASK_MANAGER.run_task(:ex1)
        end
        ok {pr}.raise?(NotImplementedError,
                       "compare_file(): Cannot invoke this method because FileUtils has been disabled.")
      end

      spec "[!taukw] enables commands of the module.", tag: "skipped" do
        skip_when ENV['TEST_TARGET'] != "skipped",
                  "cannot recover changes on classes and modules"
        require "benry/unixcommand"
        use_commands_instead_of_fileutils(Benry::UnixCommand)
        dummy_file("ex1.txt", "foobar\n")
        task :ex1 do
          atomic_symlink! "ex1.txt", "ex1.symlink"
        end
        pr = proc do
          capture_sio do
            Benry::MicroRake::TASK_MANAGER.run_task(:ex1)
          end
        end
        ok {pr}.NOT.raise?
      end

    end


  end


end
