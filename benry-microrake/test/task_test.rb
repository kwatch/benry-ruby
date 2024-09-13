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


  topic Benry::MicroRake::TaskWrapper do


    topic '#initialize()' do

      spec "[!llobx] accepts a task object." do
        desc "foo task"
        tsk = task :foo, [:x, :y] => [:pre1, :pre2] do
          nil
        end
        x = Benry::MicroRake::TaskWrapper.new(tsk)
        ok {x.name} == :foo
        ok {x.desc} == "foo task"
        ok {x.prerequisites} == [:pre1, :pre2]
        ok {x.prerequisite} == :pre1
      end

    end

  end


  topic Benry::MicroRake::TaskArgVals do


    topic '#initialize()' do

      spec "[!71ejo] stores argvals as instance variables." do
        x = Benry::MicroRake::TaskArgVals.new([:foo, :bar], ["abc", 123])
        ok {x.instance_variable_get(:@foo)} == "abc"
        ok {x.instance_variable_get(:@bar)} == 123
      end

      spec "[!4pzq2] defines setter methods for argvals." do
        x2 = Benry::MicroRake::TaskArgVals.new([:foo2, :bar2], ["xyz", 456])
        ok {x2.foo2} == "xyz"
        ok {x2.bar2} == 456
      end

    end


    topic '#[]' do

      spec "[!qsi9j] returns argval corresponding to key." do
        x3 = Benry::MicroRake::TaskArgVals.new([:foo3, :bar3], [false, 789])
        ok {x3[:foo3]} == false
        ok {x3[:bar3]} == 789
      end

    end


  end


  topic Benry::MicroRake::TaskHelpBuilder do


    topic '#build_task_help()' do

      spec "[!johw0] returns help message of the task." do
        desc "desc1", {:foo=>["-f, --foo", "foo flag"], :bar=>["-b, --bar", "bar flag"]}
        tsk = task :ex1 do |src, dest, *rest, foo: nil, bar: nil|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        ok {b.build_task_help("urake3")} == <<END
\e[1murake3 ex1\e[0m --- desc1

\e[36mUsage:\e[0m
  $ urake3 ex1 [<options>] [<src> [<dest> [<rest>...]]]

\e[36mOptions:\e[0m
  -f, --foo      : foo flag
  -b, --bar      : bar flag

END
      end

      spec "[!mr7yw] adds '[<options>]' into 'Usage:' section only when the task has options." do
        desc "desc2"
        tsk = task :ex2 do |src, dest, *rest|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        ok {b.build_task_help("urake3")} == <<END
\e[1murake3 ex2\e[0m --- desc2

\e[36mUsage:\e[0m
  $ urake3 ex2 [<src> [<dest> [<rest>...]]]

END
      end

      spec "[!bt8ut] adds '[<arg1> [<arg2>]]' into 'Usage:' section only when the task has args." do
        desc "desc3", {:foo=>["-f, --foo", "foo flag"], :bar=>["-b, --bar", "bar flag"]}
        tsk = task :ex3 do |foo: nil, bar: nil|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        ok {b.build_task_help("urake3")} == <<END
\e[1murake3 ex3\e[0m --- desc3

\e[36mUsage:\e[0m
  $ urake3 ex3 [<options>]

\e[36mOptions:\e[0m
  -f, --foo      : foo flag
  -b, --bar      : bar flag

END
      end

      spec "[!wua6b] adds 'Options:' section only when the task has options." do
        desc "desc4a", {:foo=>["-f, --foo", "foo flag"]}
        tsk = task :ex4a do |foo: nil|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        ok {b.build_task_help("urake3")} == <<END
\e[1murake3 ex4a\e[0m --- desc4a

\e[36mUsage:\e[0m
  $ urake3 ex4a [<options>]

\e[36mOptions:\e[0m
  -f, --foo      : foo flag

END
        #
        desc "desc4b"
        tsk = task :ex4b do |src, dst|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        ok {b.build_task_help("urake3")} == <<END
\e[1murake3 ex4b\e[0m --- desc4b

\e[36mUsage:\e[0m
  $ urake3 ex4b [<src> [<dst>]]

END
      end

      spec "[!22q3f] includes hidden options when `all: true` specified." do
        desc "desc5", {:foo=>["-f, --foo", "foo flag", :hidden]}
        tsk = task :ex5 do |foo: nil|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        ok {b.build_task_help("urake3")} == <<END
\e[1murake3 ex5\e[0m --- desc5

\e[36mUsage:\e[0m
  $ urake3 ex5

END
        #
        ok {b.build_task_help("urake3", all: true)} == <<END
\e[1murake3 ex5\e[0m --- desc5

\e[36mUsage:\e[0m
  $ urake3 ex5 [<options>]

\e[36mOptions:\e[0m
  -h, --help     : show help message
  -f, --foo      : foo flag

END
      end

    end


    topic '#_build_arguments_str()' do

      spec "[!h175w] arg name 'a_b_c' will be pritned as 'a-b-c'." do
        desc "desc1"
        tsk = task :ex1 do |aa_bb_cc|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        s = b.build_task_help("urake3")
        ok {s}.include?("  $ urake3 ex1 [<aa-bb-cc>]\n")
      end

      spec "[!q7lwp] arg name 'a_or_b_or_c' will be printed as 'a|b|c'." do
        desc "desc2"
        tsk = task :ex2 do |aa_or_bb_or_cc|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        s = b.build_task_help("urake3")
        ok {s}.include?("  $ urake3 ex2 [<aa|bb|cc>]\n")
      end

      spec "[!nyq2o] arg name 'file__html' will be printed as 'file.html'." do
        desc "desc3"
        tsk = task :ex3 do |file__html|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        s = b.build_task_help("urake3")
        ok {s}.include?("  $ urake3 ex3 [<file.html>]\n")
      end

      spec "[!xerus] variable arg name will be printed as '<var>...'." do
        desc "desc4"
        tsk = task :ex4 do |aa, bb=nil, *cc|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        s = b.build_task_help("urake3")
        ok {s}.include?("  $ urake3 ex4 [<aa> [<bb> [<cc>...]]]\n")
      end

    end


    topic '#_retrieve_arg_and_opt_names(block)' do

      spec "[!axtdb] returns positional param names, keyword param names, and flag of rest arg." do
        tsk = task :ex5 do |aa, bb=1, *cc, xx: nil, yy: nil, **zz|
          nil
        end
        b = Benry::MicroRake::TaskHelpBuilder.new(tsk)
        b.instance_exec(self) do |_|
          anames, kwnames, rest_flag = _retrieve_arg_and_opt_names(tsk.block)
          _.ok {anames} == [:aa, :bb, :cc]
          _.ok {kwnames} == [:xx, :yy]
          _.ok {rest_flag} == true
        end
      end

    end


  end


end
