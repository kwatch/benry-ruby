Benry::CLI README
=================

($Release: 0.0.0 $)

Benry::CLI is a MVC-like framework for command-line application.
It is suitable for command-line application such as `git`, `gem` or `rails`.

Compared with Rake, Benry::CLI have a distinct advantage:

* Benry::CLI can define sub-command which can take arguments and options.
* Rake can't define such sub-command.

If you use Rake as command-line application framework instead of build tool,
take account of Benry::CLI as an alternative of Rake.

(Benry::CLI requires Ruby >= 2.0)


Basic Example
-------------

ex1.rb:
```ruby
require 'benry/cli'

##
## Define subclass of Benry::CLI::Action (= controller class).
##
class HelloAction < Benry::CLI::Action

  ##
  ## Define action (= sub-command) with @action.()
  ##
  @action.(:hello, "print hello message")
  def do_hello(name='World')
    puts "Hello, #{name}!"
  end

  ##
  ## When action name is nil then method name is used as action name instead.
  ##
  @action.(nil, "print goodbye message")
  def goodbye(name='World')
    puts "Goodbye, #{name}!"
  end

end

VERSION = "1.0"

def main()
  ##
  ## Create application object with desription, version and action classes.
  ## When 'action_classes' is nil, then all subclasses of Benry::CLI::Action
  ## are used instead.
  ##
  classes = [
    HelloAction,
  ]
  app = Benry::CLI::Application.new("example script",
                                    version: VERSION,
                                    action_classes: classes)
  app.main()
end


if __FILE__ == $0
  main()
end
```

Example:
```console
$ ruby ex1.rb hello
Hello, World!

$ ruby ex1.rb hello ruby
Hello, ruby!

$ ruby ex1.rb goodbye
Goodbye, World!

$ ruby ex1.rb goodbye sekai
Goodbye, sekai!
```

Help mesage:
```console
$ ruby ex1.rb --help   # or: ruby ex1.rb help
example script

Usage:
  ex1.rb [<options>] <action> [<args>...]

Options:
  -h, --help           : print help message
      --version        : print version

Actions:
  goodbye              : print goodbye message
  hello                : print hello message

(Run `ex1.rb help <action>' to show help message of each action.)
```


Command-line Options
--------------------

ex2.rb:
```ruby
require 'benry/cli'

class OptionTestAction < Benry::CLI::Action

  ##
  ## Define command-line options with @option.()
  ##
  @action.(:hello1, "say hello")
  @option.('-q, --quiet'        , "quiet mode")       # no argument
  @option.('-f, --format=TYPE'  , "'text' or 'html'") # required arg
  @option.('-d, --debug[=LEVEL]', "debug level")      # optional arg
  def do_hello1(name='World', quiet: nil, format: nil, debug: nil)
    puts "name=%p, quiet=%p, format=%p, debug=%p" % \
          [name, quiet, format, debug]
  end

  ##
  ## Long-only version
  ##
  @action.(:hello2, "say hello")
  @option.('--quiet'        , "quiet mode")       # no argument
  @option.('--format=TYPE'  , "'text' or 'html'") # required arg
  @option.('--debug[=LEVEL]', "debug level")      # optional arg
  def do_hello2(name='World', quiet: nil, format: nil, debug: nil)
    puts "name=%p, quiet=%p, format=%p, debug=%p" % \
          [name, quiet, format, debug]
  end

  ##
  ## Short-only version
  ##
  @action.(:hello3, "say hello")
  @option.('-q'        , "quiet mode")       # no argument
  @option.('-f TYPE'   , "'text' or 'html'") # required arg
  @option.('-d[=LEVEL]', "debug level")      # optional arg
  def do_hello3(name='World', q: nil, f: nil, d: nil)
    puts "name=%p, q=%p, f=%p, d=%p" % \
          [name, q, f, d]
  end

  ##
  ## Change keyword arg name without '--long' option
  ##
  @action.(:hello4,    "say hello")
  @option.(:quiet,  '-q        ' , "quiet mode")       # no argument
  @option.(:format, '-f TYPE   ' , "'text' or 'html'") # required arg
  @option.(:debug,  '-d[=LEVEL]' , "debug level")      # optional arg
  def do_hello4(name='World', quiet: nil, format: nil, debug: nil)
    puts "name=%p, quit=%p, format=%p, debug=%p" % \
          [name, quiet, format, debug]
  end

end

def main()
  app = Benry::CLI::Application.new(version: '1.0')
  app.main()
end


if __FILE__ == $0
  main()
end
```

Example:
```console
## no options
$ ruby ex2.rb hello world
name="world", quiet=nil, format=nil, debug=nil

## with some options
$ ruby ex2.rb hello -d -f foo.txt -d2 world
name="world", quiet=nil, format="foo.txt", debug="2"

## notice that argument of '-d' is optional.
$ ruby ex2.rb hello -d
name="World", quiet=nil, format=nil, debug=true
$ ruby ex2.rb hello -d2
name="World", quiet=nil, format=nil, debug="2"
```

Help message:
```console
$ ruby ex2.rb hello -h
Usage:
  ex2.rb [<options>] <action> [<args>...]

Options:
  -h, --help           : print help message
      --version        : print version

Actions:
  hello1               : say hello
  hello2               : say hello
  hello3               : say hello
  hello4               : say hello

(Run `ex2.rb help <action>' to show help message of each action.)
```


Validation and Type Conversion
------------------------------

ex3.rb:
```ruby
require 'benry/cli'

class ValidationTestAction < Benry::CLI::Action

  ##
  ## @option.() can take a block argument which does both validation
  ## and data conversion.
  ##
  @action.(:hello, "say hello")
  @option.('-L, --log-level=N', "log level (1~5)") {|val|
    val =~ /\A\d+\z/  or raise "positive integer expected."
    val.to_i   # convert string into integer
  }
  def do_hello(log_level: 1)
    puts "log_level=#{log_level.inspect}"
  end

end


if __FILE__ == $0
  Benry::CLI::Application.new(version: '1.0').main()
end
```

Example:
```console
$ ruby ex3.rb hello -L abc
ERROR: -L abc: positive integer expected.
```


Other Topics
------------


### Name Conversion Rule in Help Message

* Action name 'foo_bar' is printed as 'foo-bar' in help message.
* Long option '--foo-bar' corresponds to 'foo_bar' keyword argument.
* Parameter 'foo_bar' is printed as '<foo-bar>' in help message.
* Parameter 'foo_or_bar' is printed as '<foo|bar>' in help message (!!).

ex-argname.rb:
```ruby
require 'benry/cli'

class FooAction < Benry::CLI::Action

  ##
  ##   parameter name   ->   in help message
  ##  ----------------------------------------
  ##    file_name       ->    <file-name>
  ##    file_or_dir     ->    <file|dir>
  ##    file_name=nil   ->    [<file-name>]
  ##    *fil_namee      ->    [<file-name>...]
  ##
  @action.(:bla_bla_bla, "test")
  @option.('-v, --verbose-mode', "enable verbose mode")
  def do_something(file_name, file_or_dir=nil, verbose_mode: nil)
    # ...
  end

end

if __FILE__ == $0
  Benry::CLI::Application.new().main()
end
```

Example:
```console
$ ruby ex-argname.rb help bla-bla-bla
test

Usage:
  argname.rb bla-bla-bla [<options>] <file-name> [<file|dir>]

Options:
  -h, --help           : print help message
  -v, --verbose-mode   : enable verbose mode
```


### Prefix of Action Name

`self.prefix = "..."` sets prefix name of action.

mygit.rb:
```ruby
require 'benry/cli'

class GitAction < Benry::CLI::Action

  ##
  ## add prefix 'git:' to each actions
  ##
  self.prefix = 'git'

  @action.(:stage, "same as 'git add -p'")
  def do_stage(*filenames)
    system 'git', 'add', '-p', *filenames
  end

  @action.(:staged, "same as 'git diff --cached'")
  def do_staged(*filenames)
    system 'git', 'diff', '--cached', *filenames
  end

  @action.(:unstaged, "same as 'git reset HEAD'")
  def do_unstage(*filenames)
    system 'git', 'reset', 'HEAD', *filenames
  end

end

if __FILE__ == $0
  Benry::CLI::Application.new("git wrapper", version: '1.0').main()
end
```

Example (prefix 'git:' is added to actions):
```console
$ ruby mygit.rb --help
git wrapper

Usage:
  mygit.rb [<options>] <action> [<args>...]

Options:
  -h, --help           : print help message
      --version        : print version

Actions:
  git:stage            : same as 'git add -p'
  git:staged           : same as 'git diff --cached'
  git:unstaged         : same as 'git reset HEAD'

(Run `mygit.rb help <action>' to show help message of each action.)
```

Of course, it is possible to specify prefix name with `@action.(:'git:stage')`.


#### Multiple-Value Option

Validator callback can take option values as second argument.
Using it, you can define options which can be specified more than once
(such as `-I` option of gcc).

ex-multival.rb:
```ruby
require 'benry/cli'

class TestAction < Benry::CLI::Action

  @action.(nil, "example of multi-value option")
  @option.("-I, --include=path", "include path") {|val, opt|
    opt['include'] ||= []
    opt['include'] << val
    opt['include']
  }
  def multival(include: nil)
    p include
  end

end

if __FILE__ == $0
  Benry::CLI::Application.new("multi-value example", version: '1.0').main()
end
```

Example:
```console
$ ruby ex-multival.rb multival -I /path1 -I /path2 -I /path3
["/path1", "/path2", "/path3"]
```


#### Parse Command Options without Application

If you need just command-line option parser instead of application,
use `Benry::CLI::OptionParser` class.

ex-parser.rb:
```ruby
require 'benry/cli'

parser = Benry::CLI::OptionParser.new
parser.option("-h, --help",       "print help")
parser.option("-f, --file=FILE",  "load filename")
parser.option("-i, --indent=N",   "indent") {|val|
  val =~ /\A\d+\z/  or raise "integer expected."  # validation
  val.to_i    # convertion (string -> integer)
}
args = ['-hftest.txt', '-i', '2', "x", "y"]
options = parser.parse(args)
puts options       #=> {"help"=>true, "file"=>"test.txt", "indent"=>2}
puts args.inspect  #=> ["x", "y"]
```


License and Copyright
---------------------

$License: MIT License $

$Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $
