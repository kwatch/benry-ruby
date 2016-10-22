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
# -*- coding: utf-8 -*-

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

def main()
  ##
  ## Create application object with action classes.
  ## If they are not specified, all subclasses of Benry::CLI::Action are used.
  ##
  classes = [
    HelloAction,
  ]
  app = Benry::CLI::Application.new(classes)
  #app = Benry::CLI::Application.new()   # arg 'classes' is optional
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
$ ruby ex1.rb    # or: ruby ex1.rb help
Usage:
  ex1.rb [actions]

Actions:
  goodbye                   : print goodbye message
  hello                     : print hello message

(Use `ex1.rb help <ACTION>' to show help message of each action.)

$ ruby ex1.rb hello --help   # or: ruby ex.rb help hello
print hello message

Usage:
  ex1.rb hello [options] [name]

Options:
  -h, --help           : print help message
```


Command-line Options
--------------------

ex2.rb:
```ruby
# -*- coding: utf-8 -*-

require 'benry/cli'

class OptionTestAction < Benry::CLI::Action

  ##
  ## Define command-line options with @option.()
  ##
  @action.(:hello, "print hello message")
  @option.('-q, --quiet'        , "quiet mode")       # no argument
  @option.('-f, --format=TYPE'  , "'text' or 'html'") # required arg
  @option.('-d, --debug[=LEVEL]', "debug level")      # optional arg
  def do_hello(name='World', quiet: nil, format: nil, debug: nil)
    puts "name=%p, quiet=%p, format=%p, debug=%p" % \
          [name, quiet, format, debug]
  end

  ##
  ## Short-only version
  ##
  @action.(:hello3, "print hello message")
  @option.('-q'        , "quiet mode")       # no argument
  @option.('-f TYPE'   , "'text' or 'html'") # required arg
  @option.('-d[=LEVEL]', "debug level")      # optional arg
  def do_hello2(name='World', q: nil, f: nil, d: nil)
    puts "name=%p, q=%p, f=%p, d=%p" % \
          [name, q, f, d]
  end

  ##
  ## Long-only version
  ##
  @action.(:hello3, "print hello message")
  @option.('--quiet'        , "quiet mode")       # no argument
  @option.('--format=TYPE'  , "'text' or 'html'") # required arg
  @option.('--debug[=LEVEL]', "debug level")      # optional arg
  def do_hello3(name='World', quiet: nil, format: nil, debug: nil)
    puts "name=%p, quiet=%p, format=%p, debug=%p" % \
          [name, quiet, format, debug]
  end

end

def main()
  app = Benry::CLI::Application.new()
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
print hello message

Usage:
  ex2.rb hello [options] [name]

Options:
  -h, --help           : print help message
  -q, --quiet          : quiet mode
  -f, --format=TYPE    : 'text' or 'html'
  -d, --debug[=LEVEL]  : debug level
```


Validation and Type Conversion
------------------------------

ex3.rb:
```ruby
# -*- coding: utf-8 -*-

require 'benry/cli'

class ValidationTestAction < Benry::CLI::Action

  ##
  ## Call @option.() with block parameter.
  ## Block parameter will validate and convert option value.
  ##
  @action.(:hello, "print hello message")
  @option.('-L, --log-level=N', "log level (1~5)") {|val|
    val =~ /\A\d+\z/  or raise "positive integer expected."
    val.to_i   # convert string into integer
  }
  def do_hello(log_level: 1)
    puts "log_level=#{log_level.inspect}"
  end

end


if __FILE__ == $0
  Benry::CLI::Application.new().main()
end
```

Example:
```console
$ ruby ex3.rb hello -L abc
ERROR: -L abc: positive integer expected.
```


License and Copyright
---------------------

$License: MIT License $

$Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $