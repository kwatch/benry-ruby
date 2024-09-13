# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::Task do


    topic '#initialize()' do

      spec "[!gpsw6] raises error when schema is specified but block is nil." do
        schema = Benry::MicroRake::TaskOptionSchema.new
        pr = proc { Benry::MicroRake::Task.new("foo", "", nil, nil, nil, schema) }
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError, "Task option schema cannot be specified when task block is empty.")
      end

      spec "[!600yq] raises error if there is any contradiction between option schema and block parameters." do
        schema = Benry::MicroRake::TaskOptionSchema.new
        schema.add(:force, "-f, --force", "forcedly")
        pr = proc do
          Benry::MicroRake::Task.new("foo", "", nil, nil, nil, schema) do |force|
            nil
          end
        end
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError,
                       "Block parameter `force` is declared as a positional parameter,"+\
                       " but should be declared as a keyword parameter,"+\
                       " because it is defined as a task option in the schema.")
      end

      spec "[!fi4j3] creates default schema object when option schema is not specified." do
        task = Benry::MicroRake::Task.new("foo", "desc") do |a, b, opt_x_: nil, foo: nil|
        end
        ok {task.schema} != nil
        ok {task.schema}.is_a?(Benry::MicroRake::TaskOptionSchema)
        ok {task.schema.get(:foo).long} == "foo"
        ok {task.schema.get(:foo).arg_requireness} == :optional
        ok {task.schema.get(:opt_x_).short} == "x"
        ok {task.schema.get(:opt_x_).arg_requireness} == :required
      end

    end


    topic '#hidden?' do

      spec "[!8kefc] 'important: false' means 'hidden: true'." do
        task = Benry::MicroRake::Task.new("foo", "(foo)", important: false)
        ok {task.hidden?} == true
        task = Benry::MicroRake::Task.new("foo", nil, important: false)
        ok {task.hidden?} == true
      end

      spec "[!kuapz] if description is nil then returns true if 'important: false' is not specified." do
        [nil, true].each do |val|
          task = Benry::MicroRake::Task.new("foo", nil, important: val)
          ok {task.hidden?} == true
          task = Benry::MicroRake::Task.new("foo", "desc", important: val)
          ok {task.hidden?} == false
        end
      end

    end


    topic '#important?' do

      spec "[!gg3gy] returns true or false if 'important:' kwarg specified." do
        task = Benry::MicroRake::Task.new("foo", nil, important: true)
        ok {task.important?} == true
        task = Benry::MicroRake::Task.new("foo", nil, important: false)
        ok {task.important?} == false
      end

      spec "[!lk1se] returns nil if 'important:' kwarg not specified." do
        task = Benry::MicroRake::Task.new("foo", nil)
        ok {task.important?} == nil
      end

    end


    topic '#_validate_block_params()' do

      def newblock(&b)
        return b
      end

      spec "[!tvuag] parameter type `:req` must not appear in block parameters." do
        blk = newblock do |a, b=0, *c, x: nil, **y|
          nil
        end
        blk.parameters.each do |(ptype, pname)|
          ok {ptype} != :req
        end
      end

      spec "[!bsnmu] error when positional param of block is defined as a task option." do
        pr = proc do
          desc "foo", {:bla=>["-b", "bla flag"]}
          task :foo do |bla|
            nil
          end
        end
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError,
                       "Block parameter `bla` is declared as a positional parameter,"+\
                       " but should be declared as a keyword parameter,"+\
                       " because it is defined as a task option in the schema.")
      end

      spec "[!7ube0] error when variable param of block is defined as a task option." do
        pr = proc do
          desc "foo", {:bla=>["-b", "bla flag"]}
          task :foo do |*bla|
            nil
          end
        end
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError,
                       "Block parameter `bla` is declared as a variable parameter,"+\
                       " but should be declared as a keyword parameter,"+\
                       " because it is defined as a task option in the schema.")
      end

      spec "[!t2x6s] error when keyword param of block is not defined as a task option." do
        pr = proc do
          desc "foo", {:bla=>["-b", "bla flag"]}
          task :foo do |blabla, foobar: nil|
            nil
          end
        end
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError,
                       "Block parameter `foobar` is declared as a keyword parameter,"+\
                       " but not defined in the task option schema.")
      end

      spec "[!se4ol] variable keyword param of block is just ignored." do
        pr = proc do
          desc "foo", {:bla=>["-b", "bla flag"]}
          task :foo do |bla: nil, **kwargs|
            nil
          end
        end
        ok {pr}.NOT.raise?(Exception)
      end

      spec "[!q3ylg] not raise error when 'help:' keyword param not found in task block parameters." do
        tsk = nil
        pr = proc do
          desc "foo", {:bla=>["-b", "bla flag"]}
          tsk = task :foo do |bla: nil|
            nil
          end
        end
        ok {pr}.NOT.raise?(Exception)
        ok {tsk.schema.get(:help)} != nil
      end

      spec "[!ycykr] error when a task option is defined but there is no corresponding keyword param in the task block." do
        pr = proc do
          desc "foo", {:bla=>["-b", "bla flag"], :quux=>["-q", "quux flag"]}
          tsk = task :foo do |bla: nil|
            nil
          end
        end
        ok {pr}.raise?(Benry::MicroRake::TaskDefinitionError,
                       "Option `quux` is defined in task option schema,"+\
                       " but not declared as a keyword parameter of the task block.")
      end

    end


    topic '#append_task()' do

      spec "[!jg8h1] appends other task to the end of linked list of tasks." do
        tsk1 = task "foo" do
          nil
        end
        tsk2 = Benry::MicroRake::Task.new("foo", "#2") do
          nil
        end
        tsk3 = Benry::MicroRake::Task.new("foo", "#3") do
          nil
        end
        ok {tsk1.next_task} == nil
        tsk1.append_task(tsk2)
        ok {tsk1.next_task} == tsk2
        ok {tsk1.next_task.next_task} == nil
        tsk1.append_task(tsk3)
        ok {tsk1.next_task.next_task} == tsk3
        ok {tsk1.next_task.next_task.next_task} == nil
      end

    end


    topic '#clone_task()' do

      spec "[!1cp1k] copies the task object with new name and description." do
        desc "foo task", {:bla=>["-b", "bla flag"]}, hidden: true, important: true
        tsk1 = task :foo => :pre1 do |bla: nil|
          nil
        end
        tsk2 = tsk1.clone_task("foo2", "new desc")
        ok {tsk2.name}          == "foo2"
        ok {tsk2.desc}          == "new desc"
        ok {tsk2.hidden?}       == tsk1.hidden?
        ok {tsk2.important?}    == tsk1.important?
        ok {tsk2.prerequisites} == tsk1.prerequisites
        ok {tsk2.argnames}      == tsk1.argnames
        ok {tsk2.location}      == tsk1.location
        ok {tsk2.schema}        == tsk1.schema
        ok {tsk2.block}         == tsk1.block
      end

    end


  end


end
