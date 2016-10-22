# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/ok'

require 'benry/cli'



class HelloAction < Benry::CLI::Action
end


class HelloSubAction < HelloAction
end


class GitAction < Benry::CLI::Action

  @prefix = 'git'
  @action.('switch', 'switch git branch')
  @option.('-v, --verbose', "verbose mode")
  def do_git_switch(branch, verbose: false)
    puts "git checkout #{branch}"
  end

  @prefix = 'git'
  @action.('fork', 'create and switch to new branch')
  @option.('-v, --verbose', "verbose mode")
  def do_git_fork(branch, verbose: false)
    puts "git checkout -b #{branch}"
  end

  @prefix = 'git'
  @action.('join', 'merge branch with --no-ff')
  def do_git_join(branch)
    puts "git merge --no-ff #{branch}"
  end

end



describe Benry::CLI::OptionSchema do


  describe '#canonical_name' do

    it "[!86hqr] returns long option name if it is provided." do
      x = Benry::CLI::OptionSchema.parse("-h, --help", "show help")
      ok {x.canonical_name} == "help"
    end

    it "[!y9xch] returns short option name if long option is not provided." do
      x = Benry::CLI::OptionSchema.parse("-h", "show help")
      ok {x.canonical_name} == "h"
    end

  end


  describe '.parse()' do

    def _arg_should_be_nothing(x)
      ok {x.argname}       == nil
      ok {x.arg_required?} == false
      ok {x.arg_optional?} == false
      ok {x.arg_nothing?}  == true
    end

    def _arg_should_be_required(x, argname)
      ok {x.argname}       == argname
      ok {x.arg_required?} == true
      ok {x.arg_optional?} == false
      ok {x.arg_nothing?}  == false
    end

    def _arg_should_be_optional(x, argname)
      ok {x.argname}       == argname
      ok {x.arg_required?} == false
      ok {x.arg_optional?} == true
      ok {x.arg_nothing?}  == false
    end

    it "[!fdh36] can parse '-v, --version' (short + long)." do
      x = Benry::CLI::OptionSchema.parse("-v, --version", "print version")
      ok {x.short} == "v"
      ok {x.long}  == "version"
      ok {x.desc}  == "print version"
      _arg_should_be_nothing(x)
    end

    it "[!jkmee] can parse '-v' (short)" do
      x = Benry::CLI::OptionSchema.parse("-v", "print version")
      ok {x.short} == "v"
      ok {x.long}  == nil
      ok {x.desc}  == "print version"
      _arg_should_be_nothing(x)
    end

    it "[!uc2en] can parse '--version' (long)." do
      x = Benry::CLI::OptionSchema.parse("--version", "print version")
      ok {x.short} == nil
      ok {x.long}  == "version"
      ok {x.desc}  == "print version"
      _arg_should_be_nothing(x)
    end

    it "[!sy157] can parse '-f, --file=FILE' (short + long + required-arg)." do
      x = Benry::CLI::OptionSchema.parse("-f, --file=FILENAME", "config file")
      ok {x.short} == "f"
      ok {x.long}  == "file"
      ok {x.desc}  == "config file"
      _arg_should_be_required(x, "FILENAME")
    end

    it "[!wrjqa] can parse '-f FILE' (short + required-arg)." do
      x = Benry::CLI::OptionSchema.parse("-f FILENAME", "config file")
      ok {x.short} == "f"
      ok {x.long}  == nil
      ok {x.desc}  == "config file"
      _arg_should_be_required(x, "FILENAME")
    end

    it "[!ip99s] can parse '--file=FILE' (long + required-arg)." do
      x = Benry::CLI::OptionSchema.parse("--file=FILENAME", "config file")
      ok {x.short} == nil
      ok {x.long}  == "file"
      ok {x.desc}  == "config file"
      _arg_should_be_required(x, "FILENAME")
    end

    it "[!9pmv8] can parse '-i, --indent[=N]' (short + long + optional-arg)." do
      x = Benry::CLI::OptionSchema.parse("-i, --indent[=N]", "indent (default 2)")
      ok {x.short} == "i"
      ok {x.long}  == "indent"
      ok {x.desc}  == "indent (default 2)"
      _arg_should_be_optional(x, "N")
    end

    it "[!ooo42] can parse '-i[N]' (short + optional-arg)." do
      x = Benry::CLI::OptionSchema.parse("-i[N]", "indent (default 2)")
      ok {x.short} == "i"
      ok {x.long}  == nil
      ok {x.desc}  == "indent (default 2)"
      _arg_should_be_optional(x, "N")
    end

    it "[!o93c7] can parse '--indent[=N]' (long + optional-arg)." do
      x = Benry::CLI::OptionSchema.parse("--indent[=N]", "indent (default 2)")
      ok {x.short} == nil
      ok {x.long}  == "indent"
      ok {x.desc}  == "indent (default 2)"
      _arg_should_be_optional(x, "N")
    end

    it "[!gzuhx] can parse string with extra spaces." do
      x = Benry::CLI::OptionSchema.parse("  -v,   --version ", "print version")
      ok {x.short}   == "v"
      ok {x.long}    == "version"
      ok {x.argname} == nil
      x = Benry::CLI::OptionSchema.parse("  -f,   --file=FILENAME ", "config file")
      ok {x.short}   == "f"
      ok {x.long}    == "file"
      ok {x.argname} == "FILENAME"
      x = Benry::CLI::OptionSchema.parse("  -i,   --indent[=N] ", "indent (default 2)")
      ok {x.short}   == "i"
      ok {x.long}    == "indent"
      ok {x.argname} == "N"
    end

    it "[!1769n] raises error when invalid format." do
      pr = proc { Benry::CLI::OptionSchema.parse("-f, --file FILENAME", "config file") }
      ok {pr}.raise?(Benry::CLI::OptionDefinitionError,
                     "'-f, --file FILENAME': failed to parse option definition.")
    end

    it "[!j2wgf] raises error when '-i [N]' specified." do
      pr = proc { Benry::CLI::OptionSchema.parse("-i [N]", "indent (default 2)") }
      ok {pr}.raise?(Benry::CLI::OptionDefinitionError,
                     "'-i [N]': failed to parse option definition due to extra space before '[' (should be '-i[N]').")
    end

  end


  describe '#option_string()' do

    it "[!pdaz3] builds option definition string." do
      cls = Benry::CLI::OptionSchema
      #
      ok {cls.parse("-v, --version", "")    .option_string} == "-v, --version"
      ok {cls.parse("-v", "")               .option_string} == "-v"
      ok {cls.parse("--version", "")        .option_string} == "    --version"
      #
      ok {cls.parse("-f, --file=FILE1", "") .option_string} == "-f, --file=FILE1"
      ok {cls.parse("-f FILE1", "")         .option_string} == "-f FILE1"
      ok {cls.parse("--file=FILE1", "")     .option_string} == "    --file=FILE1"
      #
      ok {cls.parse("-i, --indent[=N]", "") .option_string} == "-i, --indent[=N]"
      ok {cls.parse("-i[=N]", "")           .option_string} == "-i[=N]"
      ok {cls.parse("--indent[=N]", "")     .option_string} == "    --indent[=N]"
    end

  end


end



describe Benry::CLI::OptionParser do

  def _option_schemas
    return [
      Benry::CLI::OptionSchema.parse("-v, --version", "print version"),
      Benry::CLI::OptionSchema.parse("-f, --file=FILE", "config file"),
      Benry::CLI::OptionSchema.parse("-i, --indent[=N]", "indent (default 2)"),
    ]
  end

  def _option_parser
    arr = _option_schemas()
    return Benry::CLI::OptionParser.new(arr)
  end


  describe '#initialize()' do

    it "[!bflls] takes array of option schema." do
      arr = _option_schemas()
      parser = Benry::CLI::OptionParser.new(arr)
      parser.instance_exec(self) do |_|
        _.ok {@option_schemas}.is_a?(Array)
        _.ok {@option_schemas.length} == 3
        _.ok {@option_schemas[0].long} == "version"
        _.ok {@option_schemas[1].long} == "file"
        _.ok {@option_schemas[2].long} == "indent"
      end
    end

  end


  describe '#parse_options()' do

    it "[!5jfhv] returns command-line options as hash object." do
      p = _option_parser()
      args = "-vffile.txt foo bar".split()
      ok {p.parse_options(args)} == {"version"=>true, "file"=>"file.txt"}
      args = "--file=foo.txt --version --indent=2".split()
      ok {p.parse_options(args)} == {"version"=>true, "file"=>"foo.txt", "indent"=>"2"}
    end

    it "[!06iq3] removes command-line options from args." do
      p = _option_parser()
      args = "-vffile.txt foo bar".split()
      p.parse_options(args)
      ok {args} == ["foo", "bar"]
      args = "--file=foo.txt --version --indent=2 1 2".split()
      p.parse_options(args)
      ok {args} == ["1", "2"]
    end

    it "[!w5dpy] can parse long options." do
      p = _option_parser()
      args = "--version".split()
      ok {p.parse_options(args)} == {"version"=>true}
      args = "--file=foo.txt".split()
      ok {p.parse_options(args)} == {"file"=>"foo.txt"}
      args = "--indent".split()
      ok {p.parse_options(args)} == {"indent"=>true}
      args = "--indent=99".split()
      ok {p.parse_options(args)} == {"indent"=>"99"}
    end

    it "[!mov8e] can parse short options." do
      p = _option_parser()
      args = "-v".split()
      ok {p.parse_options(args)} == {"version"=>true}
      args = "-f foo.txt".split()
      ok {p.parse_options(args)} == {"file"=>"foo.txt"}
      args = "-i foo bar".split()
      ok {p.parse_options(args)} == {"indent"=>true}
      args = "-i99 foo bar".split()
      ok {p.parse_options(args)} == {"indent"=>"99"}
    end

    it "[!31h46] stops parsing when '--' appears in args." do
      p = _option_parser()
      args = "-v -- -ffile.txt foo bar".split()
      ok {p.parse_options(args)} == {"version"=>true}
      ok {args} == ["-ffile.txt", "foo", "bar"]
    end

    it "[!w67gl] raises error when long option is unknown." do
      p = _option_parser()
      pr = proc { p.parse_options("-v --verbose".split()) }
      ok {pr}.raise?(Benry::CLI::OptionError, "--verbose: unknown option.")
      pr = proc { p.parse_options("-v --quiet=yes".split()) }
      ok {pr}.raise?(Benry::CLI::OptionError, "--quiet: unknown option.")
    end

    it "[!kyd1j] raises error when required argument of long option is missing." do
      p = _option_parser()
      pr = proc { p.parse_options("-v --file".split()) }
      ok {pr}.raise?(Benry::CLI::OptionError, "--file: argument required.")
    end

    it "[!wuyrh] uses true as default value of optional argument of long option." do
      p = _option_parser()
      ok {p.parse_options("-v --indent".split())} == {"indent"=>true, "version"=>true}
    end

    it "[!91b2j] raises error when long option takes no argument but specified." do
      p = _option_parser()
      pr = proc { p.parse_options("-v --version=1.1".split()) }
      ok {pr}.raise?(Benry::CLI::OptionError, "--version=1.1: unexpected argument.")
    end

    it "[!9td8b] invokes callback with long option value if callback exists." do
      p = _option_parser()
      ok {p.parse_options(["--indent=99"])} == {"indent"=>"99"}
      #
      arr = [
        Benry::CLI::OptionSchema.parse("-i, --indent[=N]", "") {|value| value.to_i }
      ]
      p2 = Benry::CLI::OptionParser.new(arr)
      ok {p2.parse_options(["--indent=99"])} == {"indent"=>99}
    end

    it "[!wr58v] raises error when unknown short option specified." do
      p = _option_parser()
      pr = proc { p.parse_options("-vx".split()) }
      ok {pr}.raise?(Benry::CLI::OptionError, "-x: unknown option.")
    end

    it "[!jzdcr] raises error when requried argument of short option is missing." do
      p = _option_parser()
      pr = proc { p.parse_options("-vf".split()) }
      ok {pr}.raise?(Benry::CLI::OptionError, "-f: argument required.")
    end

    it "[!hnki9] uses true as default value of optional argument of short option." do
      p = _option_parser()
      ok {p.parse_options("-i".split())} == {"indent"=>true}
    end

    it "[!8gj65] uses true as value of short option which takes no argument." do
      p = _option_parser()
      ok {p.parse_options("-v".split())} == {"version"=>true}
    end

    it "[!l6gss] invokes callback with short option value if exists." do
      p = _option_parser()
      ok {p.parse_options("-i99".split())} == {"indent"=>"99"}
      #
      arr = [
        Benry::CLI::OptionSchema.parse("-i, --indent[=N]", "") {|value| value.to_i }
      ]
      p2 = Benry::CLI::OptionParser.new(arr)
      ok {p2.parse_options(["-i99"])} == {"indent"=>99}
    end

  end


end



describe Benry::CLI::Action do


  describe '.inherited()' do

    it "[!al5pr] provides @action and @option for subclass." do
      HelloAction.instance_exec(self) do |_|
        _.ok {@action} != nil
        _.ok {@action}.is_a?(Proc)
        _.ok {@option} != nil
        _.ok {@option}.is_a?(Proc)
      end
    end

    it "[!ymtsg] allows block argument to @option." do
      cls = Class.new(Benry::CLI::Action) do
        @action.(:hello, "print hello")
        @option.('-L, --level=N', 'level') {|val| val.to_i }
        def hello(level: 1)
          "level=#{level.inspect}"
        end
      end
      cls.instance_exec(self) do |_|
        arr = @__mappings[0]
        _.ok {arr[0]} == :hello
        _.ok {arr[1]} == "print hello"
        _.ok {arr[2][1].short} == 'L'
        _.ok {arr[2][1].long}  == 'level'
        _.ok {arr[2][1].block}.is_a?(Proc)
        _.ok {arr[2][1].block.call("123")} == 123
      end
    end

    it "[!di9na] raises error when @option.() called without @action.()." do
      pr = proc do
        Class.new(Benry::CLI::Action) do
          @option.('-v, --verbose', "verbose mode")
          def hello(verbose)
          end
        end
      end
      ok {pr}.raise?(Benry::CLI::OptionDefinitionError,
                     '@option.("-v, --verbose"): @action.() should be called prior to @option.().')
    end

    it "[!4otr6] registers subclass." do
      ok {Benry::CLI::Action::SUBCLASSES}.include?(HelloAction)
      ok {Benry::CLI::Action::SUBCLASSES}.include?(HelloSubAction)
    end

  end


  describe '.method_added()' do

    it "[!syzvc] registers action with method." do
      cls = Class.new(Benry::CLI::Action) do
        @action.("hello", "print hello message")
        @option.('-n, --name=NAME', "user name")
        def do_hello(name: "World")
          puts "Hello, #{name}!"
        end
      end
      cls.instance_exec(self) do |_|
        _.ok {@__mappings} == [
          [
            'hello',
            'print hello message',
            [Benry::CLI::OptionSchema.new('h', 'help', nil, nil, 'print help message'),
             Benry::CLI::OptionSchema.new('n', 'name', 'NAME', :required, 'user name')],
            :do_hello,
          ],
        ]
      end
    end

    it "[!m7y8p] clears current action definition." do
      _ = self
      cls = Class.new(Benry::CLI::Action) do
        _.ok {@__defining} == nil
        @action.("hello", "print hello message")
        @option.('-n, --name=NAME', "user name")
        _.ok {@__defining} != nil
        def do_hello
        end
        _.ok {@__defining} == nil
      end
    end

  end


end



describe Benry::CLI::ActionInfo do


  describe '#help_message()' do

    def _new_info()
      schemas = [
        Benry::CLI::OptionSchema.parse("-v, --verbose", "verbose mode"),
        Benry::CLI::OptionSchema.parse("-f, --file=NAME", "file name"),
        Benry::CLI::OptionSchema.parse("-i, --indent[=N]", "indent (default 2)"),
      ]
      cls = Class.new(Benry::CLI::Action) do
        def do_git_switch(aa, bb, cc=nil, dd=nil, *args, verbose: false, file: nil, indent: 2)
        end
      end
      return Benry::CLI::ActionInfo.new('git:switch', 'switch', 'switch git branch',
                                        schemas, cls, :do_git_switch)
    end

    it "[!hjq5l] builds help message." do
      expected = <<END
switch git branch

Usage:
  script-name git:switch [options] aa bb [cc] [dd] [args...]

Options:
  -v, --verbose        : verbose mode
  -f, --file=NAME      : file name
  -i, --indent[=N]     : indent (default 2)
END
      info = _new_info()
      ok {info.help_message('script-name')} == expected
    end

  end


end


describe Benry::CLI::Application do


  describe '.inherited()' do

    it "[!b09pv] provides @option in subclass." do
      cls = Class.new(Benry::CLI::Application)
      cls.instance_exec(self) do |_|
        _.ok {@option} != nil
        _.ok {@option}.is_a?(Proc)
      end
    end

  end


  describe '#accept()' do

    it "[!ue26k] builds action dictionary." do
      app = Benry::CLI::Application.new
      d = app.__send__(:accept, [GitAction])
      ok {d}.is_a?(Hash)
      ok {d.keys().sort} == ['git:fork', 'git:join', 'git:switch']
      ok {d['git:fork']} == Benry::CLI::ActionInfo.new(
                              'git:fork', 'fork', 'create and switch to new branch',
                              [Benry::CLI::OptionSchema.parse('-h, --help', 'print help message'),
                               Benry::CLI::OptionSchema.parse('-v, --verbose', 'verbose mode')],
                              GitAction, :do_git_fork
                            )
      ok {d['git:switch']} == Benry::CLI::ActionInfo.new(
                              'git:switch', 'switch', 'switch git branch',
                              [Benry::CLI::OptionSchema.parse('-h, --help', 'print help message'),
                               Benry::CLI::OptionSchema.parse('-v, --verbose', 'verbose mode')],
                              GitAction, :do_git_switch
                            )
    end

  end


  describe '#call()' do

    def _argtest_action_class
      return Class.new(Benry::CLI::Action) do
        @action.(:hello1, "hello1")
        @option.('-f, --file=NAME', 'filename')
        @option.('-i, --indent[=N]', 'indent (default 2)')
        def do_hello1(aa, bb, cc=nil, dd=nil, file: nil, indent: 2)
          return ("aa=#{aa.inspect}, bb=#{bb.inspect}, cc=#{cc.inspect}, dd=#{dd.inspect}"+\
            ", file=#{file.inspect}, indent=#{indent.inspect}")
        end
        #
        @action.(:hello2, "hello2")
        @option.('-f, --file=NAME', 'filename')
        @option.('-i, --indent[=N]', 'indent (default 2)')
        def do_hello2(aa, bb, cc=nil, dd=nil, *args, file: nil, indent: 2)
          return ("aa=#{aa.inspect}, bb=#{bb.inspect}, cc=#{cc.inspect}, dd=#{dd.inspect}"+\
            ", args=#{args.inspect}, file=#{file.inspect}, indent=#{indent.inspect}")
        end
        #
        @action.(:hello3, "hello3")
        @option.('-L, --debug-log-level=N', 'log level')
        def do_hello3(debug_log_level: 1)
          return "debug_log_level=#{debug_log_level.inspect}"
        end
      end
    end

    it "[!p5pr6] returns global help message when action is 'help'." do
      expected = <<END
Usage:
  cli_test.rb [actions]

Actions:
  git:fork                  : create and switch to new branch
  git:join                  : merge branch with --no-ff
  git:switch                : switch git branch

(Use `cli_test.rb help <ACTION>' to show help message of each action.)
END
      app = Benry::CLI::Application.new([GitAction])
      output = app.call('help')
      ok {output} == expected
    end

    it "[!3hyvi] returns help message of action when action is 'help' with action name." do
      expected = <<END
create and switch to new branch

Usage:
  cli_test.rb git:fork [options] branch

Options:
  -h, --help           : print help message
  -v, --verbose        : verbose mode
END
      app = Benry::CLI::Application.new([GitAction])
      output = app.call('help', 'git:fork')
      ok {output} == expected
    end

    it "[!mb92l] raises error when action name is unknown." do
      app = Benry::CLI::Application.new([GitAction])
      pr = proc { app.call('fork') }
      ok {pr}.raise?(Benry::CLI::OptionError, "fork: unknown action.")
    end

    it "[!13m3q] returns help message if '-h' or '--help' specified to action." do
      expected = <<END
create and switch to new branch

Usage:
  cli_test.rb git:fork [options] branch

Options:
  -h, --help           : print help message
  -v, --verbose        : verbose mode
END
      app = Benry::CLI::Application.new([GitAction])
      output = app.call('git:fork', '--help')
      ok {output} == expected
    end

    it "[!yhry7] raises error when required argument is missing." do
      cls = _argtest_action_class()
      app = Benry::CLI::Application.new([cls])
      pr = proc { app.call('hello1') }
      ok {pr}.raise?(Benry::CLI::OptionError,
                     "too few arguments (at least 2 args expected).")
      pr = proc { app.call('hello1', "x") }
      ok {pr}.raise?(Benry::CLI::OptionError,
                     "too few arguments (at least 2 args expected).")
      pr = proc { app.call('hello1', "x", "y") }
      ok {pr}.NOT.raise?(Exception)
    end

    it "[!h5522] raises error when too much arguments specified." do
      cls = _argtest_action_class()
      app = Benry::CLI::Application.new([cls])
      pr = proc { app.call('hello1', "x1", "x2", "x3", "x4", "x5") }
      ok {pr}.raise?(Benry::CLI::OptionError,
                     "too many arguments (at most 4 args expected).")
    end

    it "[!hq8b0] not raise error when many argument specified but method has *args." do
      cls = _argtest_action_class()
      app = Benry::CLI::Application.new([cls])
      pr = proc { app.call('hello2', "x1", "x2", "x3", "x4", "x5", "x6") }
      ok {pr}.NOT.raise?(Exception)
    end

    it "[!qwd9x] passes command arguments and options as method arguments and options." do
      cls = _argtest_action_class()
      app = Benry::CLI::Application.new([cls])
      #
      output = app.call('hello1', "-ffoo.txt", "x1", "x2")
      ok {output} == 'aa="x1", bb="x2", cc=nil, dd=nil, file="foo.txt", indent=2'
      output = app.call('hello1', "-i", "x1", "x2", "x3")
      ok {output} == 'aa="x1", bb="x2", cc="x3", dd=nil, file=nil, indent=true'
      #
      output = app.call('hello2', "-ffoo.txt", "x1", "x2", "x3", "x4", "x5", "x6")
      ok {output} == 'aa="x1", bb="x2", cc="x3", dd="x4", args=["x5", "x6"], file="foo.txt", indent=2'
    end

    it "[!rph9y] converts 'foo-bar' option name into :foo_bar keyword." do
      cls = _argtest_action_class()
      app = Benry::CLI::Application.new([cls])
      pr = proc { app.call('hello3', "-L30") }
      ok {pr}.NOT.raise?(Exception)
      output = pr.call()
      ok {output} == 'debug_log_level="30"'
    end

  end


end