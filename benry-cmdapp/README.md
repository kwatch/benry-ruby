# Benry-CmdApp

($Release: 0.0.0 $)


## What's This?

Benry-CmdApp is a framework to create command-line application.
If you want create command-line application which takes sub-commands
like `git`, `docker`, or `npm`, Benry-CmdApp is the solution.

Basic idea:

* Action (= sub-command) is defined as a method in Ruby.
* Commnad-line arguments are passed to action method as positional arguments.
* Command-line options are passed to action method as keyword arguments.

For example:

* `<command> hello` in command-line invokes action method `hello()` in Ruby.
* `<command> hello arg1 arg2` invokes `hello("arg1", "arg2")`.
* `<command> hello arg --opt=val` invokes `hello("arg", opt: "val")`.

Links:

* Document: <https://kwatch.github.io/benry-ruby/benry-cmdapp.html>
* GitHub: <https://github.com/kwatch/benry-ruby/tree/main/benry-cmdapp>
* Changes: <https://github.com/kwatch/benry-ruby/tree/main/benry-cmdapp/CHANGES.md>

Benry-CmdApp requires Ruby >= 2.3.


### Table of Contents

<!-- TOC -->

* [What's This?](#whats-this)
* [Install](#install)
* [Basic Usage](#basic-usage)
  * [Action](#action)
  * [Method Name and Action Name](#method-name-and-action-name)
  * [Parameter Name in Help Message of Action](#parameter-name-in-help-message-of-action)
  * [Options](#options)
  * [Option Definition Format](#option-definition-format)
  * [Option Value Validation](#option-value-validation)
  * [Callback for Option Value](#callback-for-option-value)
  * [Boolean (On/Off) Option](#boolean-onoff-option)
  * [Option Set](#option-set)
  * [Copy Options](#copy-options)
  * [Option Error and Action Error](#option-error-and-action-error)
* [Advanced Feature](#advanced-feature)
  * [Category of Action](#category-of-action)
  * [Nested Category](#nested-category)
  * [Category Action or Alias](#category-action-or-alias)
  * [Invoke Other Action](#invoke-other-action)
  * [Cleaning Up Block](#cleaning-up-block)
  * [Alias for Action](#alias-for-action)
  * [Abbreviation of Category](#abbreviation-of-category)
  * [Default Action](#default-action)
  * [Action List and Category List](#action-list-and-category-list)
  * [Hidden Action](#hidden-action)
  * [Hidden Option](#hidden-option)
  * [Important Actions or Options](#important-actions-or-options)
  * [Multiple Option](#multiple-option)
* [Configuratoin and Customization](#configuratoin-and-customization)
  * [Application Configuration](#application-configuration)
  * [Customization of Global Options](#customization-of-global-options)
  * [Customization of Global Option Behaviour](#customization-of-global-option-behaviour)
  * [Custom Hook of Application](#custom-hook-of-application)
  * [Customization of Application Help Message](#customization-of-application-help-message)
  * [Customization of Action Help Message](#customization-of-action-help-message)
  * [Customization of Section Title in Help Message](#customization-of-section-title-in-help-message)
* [Q & A](#q--a)
  * [Q: How to show all backtraces of exception?](#q-how-to-show-all-backtraces-of-exception)
  * [Q: How to specify description to arguments of actions?](#q-how-to-specify-description-to-arguments-of-actions)
  * [Q: How to append some tasks to an existing action?](#q-how-to-append-some-tasks-to-an-existing-action)
  * [Q: How to delete an existing action/alias?](#q-how-to-delete-an-existing-actionalias)
  * [Q: How to re-define an existing action?](#q-how-to-re-define-an-existing-action)
  * [Q: How to show entering into or exitting from actions?](#q-how-to-show-entering-into-or-exitting-from-actions)
  * [Q: How to enable/disable color mode?](#q-how-to-enabledisable-color-mode)
  * [Q: How to define `-vvv` style option?](#q-how-to-define--vvv-style-option)
  * [Q: How to show global option `-L <topic>` in help message?](#q-how-to-show-global-option--l-topic-in-help-message)
  * [Q: How to specify detailed description of options?](#q-how-to-specify-detailed-description-of-options)
  * [Q: How to list only aliases (or actions) excluding actions (or aliases) ?](#q-how-to-list-only-aliases-or-actions-excluding-actions-or-aliases-)
  * [Q: How to change the order of options in help message?](#q-how-to-change-the-order-of-options-in-help-message)
  * [Q: How to add metadata to actions or options?](#q-how-to-add-metadata-to-actions-or-options)
  * [Q: How to remove common help option from all actions?](#q-how-to-remove-common-help-option-from-all-actions)
  * [Q: Is it possible to show details of actions and aliases?](#q-is-it-possible-to-show-details-of-actions-and-aliases)
  * [Q: How to make error messages I18Ned?](#q-how-to-make-error-messages-i18ned)
* [License and Copyright](#license-and-copyright)

<!-- /TOC -->



## Install

```console
$ gem install benry-cmdapp
```



## Basic Usage


### Action

How to define actions:

* (1) Inherit action class.
* (2) Define action methods with `@action.()`.
* (3) Create an application object and run it.

Note:

* Use `@action.()`, not `@action()`.
* Command-line arguments are passed to action method as positional arguments.
* An action class can have several action methods.
* It is ok to define multiple action classes.

File: ex01.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

## (1) Inherit action class.
class MyAction < Benry::CmdApp::Action    # !!!!

  ## (2) Define action methods with `@action.()`.
  @action.("print greeting message")      # !!!!
  def hello(name="world")                 # !!!!
    puts "Hello, #{name}!"
  end

end

## (3) Create an application object and run it.
status_code = Benry::CmdApp.main("sample app", "1.0.0")
exit status_code
## or:
#config = Benry::CmdApp::Config.new("sample app", "1.0.0")
#app = Benry::CmdApp::Application.new(config)
#status_code = app.main()
#exit status_code
```

Output:

```console
[bash]$ ruby ex01.rb hello           # action
Hello, world!

[bash]$ ruby ex01.rb hello Alice     # action + argument
Hello, Alice!
```

Help message of command:

```console
[bash]$ ruby ex01.rb -h     # or `--help`
ex01.rb (1.0.0) --- sample app

Usage:
  $ ex01.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message (of action if specified)
  -V, --version      : print version
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too

Actions:
  hello              : print greeting message
  help               : print help message (of action if specified)
```

Help message of action:

```console
[bash]$ ruby ex01.rb -h hello     # or: ruby ex01.rb --help hello
ex01.rb hello --- print greeting message

Usage:
  $ ex01.rb hello [<name>]
```

* Benry-CmdApp adds `-h` and `--help` options to each action automatically.
  Output of `ruby ex01.rb hello -h` and `ruby ex01.rb -h hello` will be the same.

```console
[bash]$ ruby ex01.rb hello -h     # or: ruby ex01.rb helo --help
ex01.rb hello --- print greeting message

Usage:
  $ ex01.rb hello [<name>]
```


### Method Name and Action Name

Rules between method name and action name:

* Method name `print_` results in action name `print`.
  This is useful to define actions which name is same as Ruby keyword or popular functions.
* Method name `foo_bar_baz` results in action name `foo-bar-baz`.
* Method name `foo__bar__baz` results in action name `foo:bar:baz`.

File: ex02.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  ## 'print_' => 'print'
  @action.("sample #1")
  def print_()                 # !!!!
    puts __method__
  end

  ## 'foo_bar_baz' => 'foo-bar-baz'
  @action.("sample #2")
  def foo_bar_baz()            # !!!!
    puts __method__
  end

  ## 'foo__bar__baz' => 'foo:bar:baz'
  @action.("sample #3")
  def foo__bar__baz()          # !!!!
    puts __method__
  end

end

status_code = Benry::CmdApp.main("test app")
exit status_code
## or:
#config = Benry::CmdApp::Config.new("test app")
#app = Benry::CmdApp::Application.new(config)
#status_code = app.main()
#exit status_code
```

Help message:

```console
[bash]$ ruby ex02.rb --help
ex02.rb --- test app

Usage:
  $ ex02.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message (of action if specified)
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too

Actions:
  foo-bar-baz        : sample #2
  foo:bar:baz        : sample #3
  help               : print help message (of action if specified)
  print              : sample #1
```

Output:

```console
[bash]$ ruby ex02.rb print            # `print_` method
print_

[bash]$ ruby ex02.rb foo-bar-baz      # `foo_bar_baz` method
foo_bar_baz

[bash]$ ruby ex02.rb foo:bar:baz      # `foo__bar__baz` method
foo__bar__baz
```


### Parameter Name in Help Message of Action

In help message of an action, positional parameters of action methods are printed under the name conversion rule.

* Parameter `foo` is printed as `<foo>`.
* Parameter `foo_bar_baz` is printed as `<foo-bar-baz>`.
* Parameter `foo_or_bar_or_baz` is printed as `<foo|bar|baz>`.
* Parameter `foobar__xxx` is printed as `<foobar.xxx>`.

In addition, positional parameters are printed in different way according to its kind.

* If parameter `foo` is required (= doesn't have default value), it will be printed as `<foo>`.
* If parameter `foo` is optional (= has default value), it will be printed as `[<foo>]`.
* If parameter `foo` is variable length (= `*foo` style), it will be printed as `[<foo>...]`.
* If parameter `foo` is required or optional and `foo_` is variable length, it will be printed as `<foo>...`.


File: ex03.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("name conversion test")
  def test1(file_name, file_or_dir, file__html)  # !!!!
    # ...
  end

  @action.("parameter kind test")
  def test2(aaa, bbb, ccc=nil, ddd=nil, *eee)  # !!!!
    # ...
  end

  @action.("parameter combination test")
  def test3(file, *file_)  # !!!!
    files = [file] + file_
    # ...
  end

end

status_code = Benry::CmdApp.main("sample app", "1.0.0")
exit status_code
```

Help message:

```console
[bash]$ ruby ex03.rb -h test1
ex03.rb test1 --- name conversion test

Usage:
  $ ex03.rb test1 <file-name> <file|dir> <file.html>  # !!!!

[bash]$ ruby ex03.rb -h test2
ex03.rb test2 --- parameter kind test

Usage:
  $ ex03.rb test2 <aaa> <bbb> [<ccc> [<ddd> [<eee>...]]]  # !!!!

[bash]$ ruby ex03.rb -h test3
ex03.rb test3 --- parameter combination test

Usage:
  $ ex03.rb test3 <file>...                           # !!!!
```


### Options

* Action can take command-line options.
* Option values specified in command-line are passed to action method as keyword arguments.

File: ex04.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class MyAction < Benry::CmdApp::Action

  @action.("print greeting message")
  @option.(:lang, "-l, --lang=<en|fr|it>", "language")   # !!!!
  def hello(user="world", lang: "en")                    # !!!!
    case lang
    when "en" ; puts "Hello, #{user}!"
    when "fr" ; puts "Bonjour, #{user}!"
    when "it" ; puts "Ciao, #{user}!"
    else
      raise "#{lang}: Unknown language."
    end
  end

end

exit Benry::CmdApp.main("sample app", "1.0.0")
```

Output:

```console
[bash]$ ruby ex04.rb hello
Hello, world!

[bash]$ ruby ex04.rb hello -l fr            # !!!!
Bonjour, world!

[bash]$ ruby ex04.rb hello --lang=it        # !!!!
Ciao, world!
```

* An action can have multiple options.
* Option format can have indentation spaces, for example `'    --help'`.

File: ex05.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class MyAction < Benry::CmdApp::Action

  @action.("print greeting message")
  @option.(:lang  , "-l, --lang=<en|fr|it>", "language")
  @option.(:repeat, "    --repeat=<N>", "repeat <N> times")  # !!!!
  def hello(user="world", lang: "en", repeat: "1")
    #p repeat.class   #=> String                    # !!!!
    repeat.to_i.times do                            # !!!!
      case lang
      when "en" ; puts "Hello, #{user}!"
      when "fr" ; puts "Bonjour, #{user}!"
      when "it" ; puts "Ciao, #{user}!"
      else
        raise "#{lang}: Unknown language."
      end
    end
  end

end

exit Benry::CmdApp.main("sample app", "1.0.0")
```

Output:

```console
[bash]$ ruby ex05.rb hello Alice -l fr --repeat=3
Bonjour, Alice!
Bonjour, Alice!
Bonjour, Alice!
```

Help message:

```console
[bash]$ ruby ex05.rb -h hello
ex05.rb hello --- print greeting message

Usage:
  $ ex05.rb hello [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
      --repeat=<N>   : repeat <N> times   # !!!!
```

* If an option defined but the corresponding keyword argument is missing, error will be raised.
* If an action method accepts any keyword arguments (such as `**kwargs`), nothing will be raised.

```ruby
  ### ERROR: option `:repeat` is defined but keyword arg `repeat:` is missing.
  @action.("greeting message")
  @option.(:lang  , "-l <lang>", "language")
  @option.(:repeat, "-n <N>"   , "repeat N times")
  def hello(user="world", lang: "en")
    ....
  end

  ### NO ERROR: `**kwargs` accepts any keyword arguments.
  @action.("greeting message")
  @option.(:lang  , "-l <lang>", "language")
  @option.(:repeat, "-n <N>"   , "repeat N times")
  def hello(user="world", lang: "en", **kwargs)
    ....
  end
```

For usability reason, Benry-CmdApp supports `--lang=<val>` style of long option
but doesn't support `--lang <val>` style.
Benry-CmdApp regards `--lang <val>` as 'long option without argument'
and 'argument for command'.

```console
[bash]$ ruby ex05.rb hello --lang fr         # ``--lang fr`` != ``--lang=fr``
[ERROR] --lang: Argument required.
```


### Option Definition Format

There are 9 option definition formats.

* When the option takes no value:
  * `-q` --- Short style.
  * `--quiet` --- Long style.
  * `-q, --quiet` --- Short and long style.
* When the option takes a required value:
  * `-f <path>` --- Short style.
  * `--file=<path>` --- Long style.
  * `-f, --file=<path>` --- Short and long style.
* When the option takes an optional value:
  * `-i[<N>]` --- Short style.
  * `--indent[=<N>]` --- Long style.
  * `-i, --indent[=<N>]` --- Short and long style.

File: ex06.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  ## short options
  @action.("short options")
  @option.(:quiet  , "-q"        , "quiet mode")     # none
  @option.(:file   , "-f <file>" , "filename")       # required
  @option.(:indent , "-i[<N>]"   , "indent width")   # optional
  def test1(quiet: false, file: nil, indent: nil)
    puts "quiet=#{quiet.inspect}, file=#{file.inspect}, indent=#{indent.inspect}"
  end

  ## long options
  @action.("long options")
  @option.(:quiet  , "--quiet"        , "quiet mode")     # none
  @option.(:file   , "--file=<file>"  , "filename")       # required
  @option.(:indent , "--indent[=<N>]" , "indent width")   # optional
  def test2(quiet: false, file: nil, indent: nil)
    puts "quiet=#{quiet.inspect}, file=#{file.inspect}, indent=#{indent.inspect}"
  end

  ## short and long options
  @action.("short and long options")
  @option.(:quiet  , "-q, --quiet"        , "quiet mode")    # none
  @option.(:file   , "-f, --file=<file>"  , "filename")      # required
  @option.(:indent , "-i, --indent[=<N>]" , "indent width")  # optional
  def test3(quiet: false, file: nil, indent: nil)
    puts "quiet=#{quiet.inspect}, file=#{file.inspect}, indent=#{indent.inspect}"
  end

end

exit Benry::CmdApp.main("test app")
```

Output:

```console
[bash]$ ruby ex06.rb test1 -q -f readme.txt -i4
quiet=true, file="readme.txt", indent="4"

[bash]$ ruby ex06.rb test2 --quiet --file=readme.txt --indent=4
quiet=true, file="readme.txt", indent="4"

[bash]$ ruby ex06.rb test3 -q -f readme.txt -i4
quiet=true, file="readme.txt", indent="4"
[bash]$ ruby ex06.rb test3 --quiet --file=readme.txt --indent=4
quiet=true, file="readme.txt", indent="4"
```

Optional argument example:

```console
[bash]$ ruby ex06.rb test1 -i                 # ``-i`` results in ``true``
quiet=false, file=nil, indent=true
[bash]$ ruby ex06.rb test1 -i4                # ``-i4`` results in ``4``
quiet=false, file=nil, indent="4"

[bash]$ ruby ex06.rb test2 --indent           # ``--indent`` results in ``true``
quiet=false, file=nil, indent=true
[bash]$ ruby ex06.rb test2 --indent=4         # ``--indent=4`` results in ``4``
quiet=false, file=nil, indent="4"
```

Help message:

```ruby
[bash]$ ruby ex06.rb -h test1
ex06.rb test1 --- short options

Usage:
  $ ex06.rb test1 [<options>]

Options:
  -q                 : quiet mode
  -f <file>          : filename
  -i[<N>]            : indent width

[bash]$ ruby ex06.rb -h test2
ex06.rb test2 --- long options

Usage:
  $ ex06.rb test2 [<options>]

Options:
  --quiet            : quiet mode
  --file=<file>      : filename
  --indent[=<N>]     : indent width

[bash]$ ruby ex06.rb -h test3
ex06.rb test3 --- short and long options

Usage:
  $ ex06.rb test3 [<options>]

Options:
  -q, --quiet        : quiet mode
  -f, --file=<file>  : filename
  -i, --indent[=<N>] : indent width
```


### Option Value Validation

`@option.()` can validate option value via keyword argument.

* `type: <class>` specifies option value class.
  Currently supports `Integer`, `Float`, `TrueClass`, and `Date`.
* `rexp: <rexp>` specifies regular expression of option value.
* `enum: <array>` specifies available values as option value.
* `range: <range>` specifies range of option value.

File: ex07.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class MyAction < Benry::CmdApp::Action

  @action.("print greeting message")
  @option.(:lang  , "-l, --lang=<en|fr|it>", "language",
                  enum: ["en", "fr", "it"],         # !!!!
		  rexp: /\A\w\w\z/)                 # !!!!
  @option.(:repeat, "    --repeat=<N>", "repeat <N> times",
                  type: Integer, range: 1..10)      # !!!!
  def hello(user="world", lang: "en", repeat: 1)
    #p repeat.class   #=> Integer
    repeat.times do
      case lang
      when "en" ; puts "Hello, #{user}!"
      when "fr" ; puts "Bonjour, #{user}!"
      when "it" ; puts "Ciao, #{user}!"
      else
        raise "#{lang}: Unknown language."
      end
    end
  end

end

exit Benry::CmdApp.main("sample app", "1.0.0")
```

Output:

```console
[bash]$ ruby ex07.rb hello -l japan
[ERROR] -l japan: Pattern unmatched.

[bash]$ ruby ex07.rb hello -l ja
[ERROR] -l ja: Expected one of en/fr/it.

[bash]$ ruby ex07.rb hello --repeat=abc
[ERROR] --repeat=abc: Integer expected.

[bash]$ ruby ex07.rb hello --repeat=100
[ERROR] --repeat=100: Too large (max: 10).
```


### Callback for Option Value

`@option.()` can take a block argument which is a callback for option value.
Callback can:

* Do custom validation of option value.
* Convert option value into other value.

File: ex08.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class MyAction < Benry::CmdApp::Action

  @action.("print greeting message")
  @option.(:lang  , "-l, --lang=<en|fr|it>", "language",
                  enum: ["en", "fr", "it", "EN", "FR", "IT"],
		  rexp: /\A\w\w\z/) {|v| v.downcase }    # !!!!
  @option.(:repeat, "    --repeat=<N>", "repeat <N> times",
                  type: Integer) {|v|                    # !!!!
		    v > 0 or raise "Not positive value." # !!!!
                    v                                    # !!!!
                  }                                      # !!!!
  def hello(user="world", lang: "en", repeat: 1)
    repeat.times do
      case lang
      when "en" ; puts "Hello, #{user}!"
      when "fr" ; puts "Bonjour, #{user}!"
      when "it" ; puts "Ciao, #{user}!"
      else
        raise "#{lang}: Unknown language."
      end
    end
  end

end

exit Benry::CmdApp.main("sample app", "1.0.0")
```

Output:

```console
[bash]$ ruby ex08.rb hello -l FR   # converted into lowercase
Bonjour, world!

[bash]$ ruby ex08.rb hello --repeat=0
[ERROR] --repeat=0: Not positive value.
```


### Boolean (On/Off) Option

Benry-CmdApp doesn't support `--[no-]foobar` style option.
Instead, define boolean (on/off) option.

* Specify `type: TrueClass` to `@option.()`.
* Option value `true`, `yes`, and `on` are converted into true.
* Option value `false`, `no`, and `off` are converted into false.

File: ex09.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("flag test")
  @option.(:verbose, "--verbose[=<on|off>]",  # !!!!
                     "verbose mode",
                     type: TrueClass)         # !!!!
  def flagtest(verbose: false)                # !!!!
    puts "verbose=#{verbose}"
  end

end

exit Benry::CmdApp.main("sample app", "1.0.0")
```

Output:

```console
[bash]$ ruby ex09.rb flagtest --verbose=on       # on
verbose=true

[bash]$ ruby ex09.rb flagtest --verbose=off      # off
verbose=false

[bash]$ ruby ex09.rb flagtest --verbose=true     # on
verbose=true

[bash]$ ruby ex09.rb flagtest --verbose=false    # off
verbose=false

[bash]$ ruby ex09.rb flagtest --verbose=yes      # on
verbose=true

[bash]$ ruby ex09.rb flagtest --verbose=no       # off
verbose=false

[bash]$ ruby ex09.rb flagtest --verbose=abc      # error
[ERROR] --verbose=abc: boolean expected.
```

If you want default value of flag to `true`, use `value:` keyword argument.

* `value:` keyword argument in `@option.()` specifies the substitute value
  instead of `true` when no option value specified in command-line.

File: ex10.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("flag test")
  @option.(:verbose, "-q, --quiet", "quiet mode",
                     value: false)                 # !!!!
  def flagtest2(verbose: true)                     # !!!!
    puts "verbose=#{verbose.inspect}"
  end

end

exit Benry::CmdApp.main("git helper")
```

Output:

```console
[bash]$ ruby ex10.rb flagtest2           # true if '--quiet' NOT specified
verbose=true

[bash]$ ruby ex10.rb flagtest2 --quiet   # false if '--quiet' specified
verbose=false

[bash]$ ruby ex10.rb flagtest2 --quiet=on   # error
[ERROR] --quiet=on: Unexpected argument.
```

In above example, `--quiet=on` will be error because option is defined as
`@option.(:verbose, "-q, --quiet", ...)` which means that this option takes no arguments.
If you want to allow `--quiet=on`, specify option argument and `type: TrueClass`.


```ruby
  ...(snip)...

  @action.("flag test")
  @option.(:verbose, "-q, --quiet[=<on|off>]", "quiet mode",  # !!!!
                     type: TrueClass, value: false)           # !!!!
  def flagtest2(verbose: true)
    puts "verbose=#{verbose.inspect}"
  end

  ...(snip)...
```


### Option Set

Option set handles multiple options as a object.
Option set will help you to define same options into multiple actions.

File: ex11.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  optset1 = optionset() {                             # !!!!
    @option.(:host , "-H, --host=<host>" , "host name")
    @option.(:port , "-p, --port=<port>" , "port number", type: Integer)
  }
  optset2 = optionset() {                             # !!!!
    @option.(:user , "-u, --user=<user>" , "user name")
  }

  @action.("connect to postgresql server")
  @optionset.(optset1, optset2)                           # !!!!
  def postgresql(host: nil, port: nil, user: nil)
    puts "psql ...."
  end

  @action.("connect to mysql server")
  @optionset.(optset1, optset2)                           # !!!!
  def mysql(host: nil, port: nil, user: nil)
    puts "mysql ...."
  end

end

exit Benry::CmdApp.main("Sample App")
```

Help message:

```console
[bash]$ ruby ex11.rb -h postgresql       # !!!!
ex11.rb postgresql --- connect to postgresql

Usage:
  $ ex11.rb postgresql [<options>]

Options:
  -H, --host=<host>  : host name         # !!!!
  -p, --port=<port>  : port number       # !!!!
  -u, --user=<user>  : user name         # !!!!

[bash]$ ruby ex11.rb -h mysql            # !!!!
ex11.rb mysql --- connect to mysql

Usage:
  $ ex11.rb mysql [<options>]

Options:
  -H, --host=<host>  : host name         # !!!!
  -p, --port=<port>  : port number       # !!!!
  -u, --user=<user>  : user name         # !!!!
```

Option set object has the following methods.

* `OptionSet#select(:key1, :key2, ...)` ---
  Creates new OptionSet object with copying options which are filtered by the keys specified.
* `OptionSet#exclude(:key1, :key2, ...)` ---
  Creates new OptionSet object with copying options which are filtered by dropping the options that key is included in specified keys.

```ruby
  @action.("connect to postgresql server")
  @optionset.(optset1.select(:host, :port))    # !!!!
  def postgresql(host: nil, port: nil)
    ....
  end

  @action.("connect to mysql server")
  @optionset.(optset1.exclude(:port))          # !!!!
  def mysql(host: nil)
    ....
  end
```


### Copy Options

`@copy_options.()` copies options from other action.

File: ex12.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("connect to postgresql")
  @option.(:host , "-H, --host=<host>" , "host name")
  @option.(:port , "-p, --port=<port>" , "port number", type: Integer)
  @option.(:user , "-u, --user=<user>" , "user name")
  def postgresql(host: nil, port: nil, user: nil)
    puts "psql ...."
  end

  @action.("connect to mysql")
  @copy_options.("postgresql")                 # !!!!!
  def mysql(host: nil, port: nil, user: nil)
    puts "mysql ...."
  end

end

exit Benry::CmdApp.main("Sample App")
```

Help message:

```console
[bash]$ ruby ex12.rb -h mysql       # !!!!
ex12.rb mysql --- connect to mysql

Usage:
  $ ex12.rb mysql [<options>]

Options:
  -H, --host=<host>  : host name
  -p, --port=<port>  : port number
  -u, --user=<user>  : user name
```

If you want to exclude some options from copying, specify `exlude:` keyword argument.
For example, `@copy_options.("hello", exclude: [:help, :lang])` copies all options of `hello` action excluding `:help` and `:lang` options.


### Option Error and Action Error

* `option_error()` returns (not raise) `Benry::CmdApp::OptionError` object.
* `action_error()` returns (not raise) `Benry::CmdApp::ActionError` object.
* These are available in action method.

File: ex13.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("invoke openssl command")
  @option.(:encrypt, "--encrypt", "encrypt a file")
  @option.(:decrypt, "--decrypt", "decrypt a file")
  def openssl(filename, encrypt: false, decrypt: false)
    if encrypt == false && decrypt == false
      raise option_error("Required '--encrypt' or '--decrypt' option.") # !!!!
    end
    opt = encrypt ? "enc" : "dec"
    command = "openssl #{opt} ..."
    result = system command
    if result == false
      raise action_error("Command failed: #{command}")   # !!!!
    end
  end

end

exit Benry::CmdApp.main("Sample App")
```

Output:

```console
[bash]$ ruby ex13.rb openssl file.txt
[ERROR] Required '--encrypt' or '--decrypt' option.  #<== option_error()

[bash]$ ruby ex13.rb openssl --encrypt file.txt
enc: Use -help for summary.
[ERROR] Command failed: openssl enc ...              #<== action_error()
    From ex13.rb:17:in `openssl'
        raise action_error("Command failed: #{command}")
    From ex13.rb:25:in `<main>'
        exit app.main()
```

If you want to show all stacktrace, add `--debug` global option.

```console
[bash]$ ruby ex13.rb --debug openssl --encrypt file.txt
enc: Use -help for summary.
ex13.rb:17:in `openssl': Command failed: openssl enc ... (Benry::CmdApp::ActionError)
	from /home/yourname/cmdapp.rb:988:in `_invoke_action'
	from /home/yourname/cmdapp.rb:927:in `start_action'
	from /home/yourname/cmdapp.rb:1794:in `start_action'
	from /home/yourname/cmdapp.rb:1627:in `handle_action'
	from /home/yourname/cmdapp.rb:1599:in `run'
	from /home/yourname/cmdapp.rb:1571:in `main'
```



## Advanced Feature


### Category of Action

* `category "foo:bar:"` in action class adds prefix `foo:bar:` to each action name.
* Category name should be specified as a prefix string ending with `:`. For example, `category "foo:"` is OK but `category "foo"` will be error.
* Symbol is not allowed. For example, `category :foo` will be error.
* Method name `def baz__test()` with `category "foo:bar:"` results in the action name `foo:bar:baz:test`.

File: ex21.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action
  category "foo:bar:"                # !!!!

  @action.("test action #1")
  def test1()                      # action name: 'foo:bar:test1'
    puts __method__                #=> test1
    puts methods().grep(/test1/)   #=> foo__bar__test1
  end

  @action.("test action #2")
  def baz__test2()                 # action name: 'foo:bar:baz:test2'
    puts __method__                #=> baz__test2
    puts methods().grep(/test2/)   #=> foo__bar__baz__test2
  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex21.rb -l
Actions:
  foo:bar:baz:test2  : test action #2
  foo:bar:test1      : test action #1
  help               : print help message (of action if specified)

[bash]$ ruby ex21.rb foo:bar:test1
test1                         # <== puts __method__
foo__bar__test1               # <== puts methods().grep(/test1/)

[bash]$ ruby ex21.rb foo:bar:baz:test2
baz__test2                    # <== puts __method__
foo__bar__baz__test2          # <== puts methods().grep(/test1/)
```

(INTERNAL MECHANISM):
As shown in the above output, Benry-CmdApp internally renames `test1()` and `baz__test2()` methods within category `foo:bar:` to `foo__bar__test1()` and `foo__bar__baz__test2()` respectively.
`__method__` seems to keep original method name, but don't be fooled, methods are renamed indeed.
Due to this mechanism, it is possible to define the same name methods in different categories with no confliction.

* `category()` can take a description text of category.
  For example, `category "foo:", "Bla bla"` registers `"Bla bla` as a description of category `foo:`.
  Description of category is displayed in list of category list.
  See [Action List and Prefix List](#action-list-and-prefix-list) section for details.


### Nested Category

`category()` can take a block which represents sub-category.

File: ex22.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class GitAction < Benry::CmdApp::Action
  category "git:"                   # top level category

  @action.("show current status in compact format")
  def status(path=".")
    puts "git status -sb #{path}"
  end

  category "commit:" do             # sub level category

    @action.("create a new commit")
    def create(message: nil)
      puts "git commit"
    end

  end

  category "branch:" do             # sub level category

    @action.("create a new branch")
    def create(branch)
      puts "git checkout -b #{branch}"
    end

  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex22.rb -l
Actions:
  git:branch:create  : create a new branch
  git:commit:create  : create a new commit
  git:status         : show current status in compact format
  help               : print help message (of action if specified)
```

Block of `category()` is nestable.

File: ex23.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class GitAction < Benry::CmdApp::Action

  category "git:" do                 # top level category

    @action.("show current status in compact format")
    def status(path=".")
      puts "git status -sb #{path}"
    end

    category "commit:" do            # sub level category

      @action.("create a new commit")
      def create(message: nil)
        puts "git commit"
      end

    end

    category "branch:" do            # sub level category

      @action.("create a new branch")
      def create(branch)
        puts "git checkout -b #{branch}"
      end

    end

  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex23.rb -l
Actions:
  git:branch:create  : create a new branch
  git:commit:create  : create a new commit
  git:status         : show current status in compact format
  help               : print help message (of action if specified)
```


### Category Action or Alias

* `category "foo:bar:", action: "blabla"` defines `foo:bar` action (instead of `foo:bar:blabla`) with `blabla()` method.

File: ex24.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action
  category "foo:bar:", action: "test3"      # !!!!

  @action.("test action #1")
  def test1()                 # action name: 'foo:bar:test1'
    puts __method__
  end

  @action.("test action #3")
  def test3()                 # action name: 'foo:bar'
    puts __method__
  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex24.rb -l
Actions:
  foo:bar            : test action #3    # !!!! not 'foo:bar:test3'
  foo:bar:test1      : test action #1
  help               : print help message (of action if specified)

[bash]$ ruby ex24.rb foo:bar:test1
test1

[bash]$ ruby ex24.rb foo:bar:test3       # !!!! not available because renamed
[ERROR] foo:bar:test3: Action not found.

[bash]$ ruby ex24.rb foo:bar             # !!!! available because renamed
test3
```

<!--
* `category "foo:", alias_for: "blabla"` defines `foo` as an alias for `foo:blabla` action.
  See [Alias for Action](#alias-of-action) section about alias for action.

* Keyword arguments `action:` and `alias_for:` are exclusive.
  It is not allowed to specify both of them at the same time.
  See [Q: What is the difference between category(alias_for:) and category(action:)?](#q-what-is-the-difference-between-categoryalias_for-and-categoryaction) section for details.
-->

* Action name (and also category name) should be specified as a string. Symbol is not allowed.

```ruby
    ## Symbol is not allowed
    category :foo                       #=> error
    category "foo:", action: :blabla    #=> error
```


### Invoke Other Action

* `run_action()` invokes other action.
* `run_once()` invokes other action only once.
  This is equivarent to 'prerequisite task' feature in task runner application.

File: ex25.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("create build dir")
  def prepare()
    puts "rm -rf build"
    puts "mkdir build"
  end

  @action.("build something")
  def build()
    run_once("prepare")        # !!!!
    run_once("prepare")        # skipped because already invoked
    puts "echo 'README' > build/README.txt"
    puts "zip -r build.zip build"
  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex25.rb build
rm -rf build                          # invoked only once!!!!
mkdir build                           # invoked only once!!!!
echo 'README' > build/README.txt
zip -r build.zip build
```

* Action name should be a string. Symbol is not allowed.

```ruby
    ## Error because action name is not a string.
    run_once(:prepare)
```

* When looped action is detected, Benry-CmdApp aborts action.

File: ex26.rb

```ruby
require 'benry/cmdapp'

class LoopedAction < Benry::CmdApp::Action

  @action.("test #1")
  def test1()
    run_once("test2")
  end

  @action.("test #2")
  def test2()
    run_once("test3")
  end

  @action.("test #3")
  def test3()
    run_once("test1")          # !!!!
  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex26.rb test1
[ERROR] test1: Looped action detected.

[bash]$ ruby ex26.rb test3
[ERROR] test3: Looped action detected.
```


### Cleaning Up Block

* `at_end { ... }` registers a clean-up block that is invoked at end of process (not at end of action).
* This is very useful to register clean-up blocks in preparation action.
* Registered blocks are invoked in reverse order of registration.
  For example, `at_end { puts "A" }; at_end { puts "B" }; at_end { puts "C" }` prints "C", "B", and "A" at end of process.

File: ex27.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("create build dir")
  def prepare()
    puts "mkdir -p build"
    ## register cleaning up block in preparation task
    at_end { puts "rm -rf build" }      # !!!!
  end

  @action.("build something")
  def build()
    run_once("prepare")
    puts "echo 'README' > build/README.txt"
    puts "zip -r build.zip build"
  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex27.rb build
mkdir -p build
echo 'README' > build/README.txt
zip -r build.zip build
rm -rf build    # !!!! clean-up block invoked at the end of process !!!!
```


### Alias for Action

Alias provides alternative short name of action.

* `define_alias()` in action class defines an alias with taking action category into account.
* `Benry::CmdApp.define_alias()` defines an alias, without taking category into account.

File: ex28.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class GitAction < Benry::CmdApp::Action
  category "git:"                                   # !!!!

  @action.("show current status in compact mode")
  def status()
    puts "git status -sb"
  end

  define_alias "st", "status"                     # !!!!
  ## or:
  #Benry::CmdApp.define_alias "st", "git:status"  # !!!!

  category "staging:" do                            # !!!!

    @action.("show changes in staging area")
    def show()
      puts "git diff --cached"
    end

    define_alias "staged" , "show"                # !!!!
    ## or:
    #Benry::CmdApp.define_alias "staged", "git:staging:show" # !!!!

  end

end

Benry::CmdApp.define_alias "git", "git:status"    # !!!!

exit Benry::CmdApp.main("sample app")
```

Help message:

```console
[bash]$ ruby ex28.rb -h
ex28.rb --- sample app

Usage:
  $ ex28.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message (of action if specified)
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too

Actions:
  git                : alias for 'git:status'           # !!!!
  git:staging:show   : show changes in staging area
  git:status         : show current status in compact mode
  help               : print help message (of action if specified)
  st                 : alias for 'git:status'           # !!!!
  staged             : alias for 'git:staging:show'     # !!!!
```

Output:

```console
[bash]$ ruby ex28.rb st                # alias name
git status -sb

[bash]$ ruby ex28.rb git:status        # original action name
git status -sb

[bash]$ ruby ex28.rb staged            # alias name
git diff --cached

[bash]$ ruby ex28.rb git:staging:show  # original action name
git diff --cached

[bash]$ ruby ex28.rb git               # alias name
git status -sb
```

* Aliases are printed in the help message of action (if defined).

```console
[bash]$ ruby ex28.rb git:status -h
ex28.rb git:status --- show current status in compact mode

Usage:
  $ ex28.rb git:status

Aliases:                                               # !!!!
  git                : alias for 'git:status'           # !!!!
  st                 : alias for 'git:status'           # !!!!
```

* Both alias and action names should be string. Symbol is not allowed.

```ruby
## Error because alias name is a Symbol.
Benry::CmdApp.define_alias :test, "hello"

## Error because action name is a Symbol.
Benry::CmdApp.define_alias "test", :hello
```

* Target action (second argument of `define_alias()`) can be an array of string
  which contains action name and options.

File: ex29.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class MyAction < Benry::CmdApp::Action

  @action.("print greeting message")
  @option.(:lang, "-l, --lang=<lang>", "language", enum: ["en", "fr", "it"])
  def hello(user="world", lang: "en")
    case lang
    when "en" ; puts "Hello, #{user}!"
    when "fr" ; puts "Bonjour, #{user}!"
    when "it" ; puts "Ciao, #{user}!"
    else
      raise "#{lang}: Unknown language."
    end
  end

end

Benry::CmdApp.define_alias("bonjour", ["hello", "--lang=fr"])        # !!!!
Benry::CmdApp.define_alias("ciao"   , ["hello", "-l", "it", "Bob"])  # !!!!

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex29.rb hello
Hello, world!

[bash]$ ruby ex29.rb bonjour           # !!!!
Bonjour, world!

[bash]$ ruby ex29.rb bonjour Alice     # !!!!
Bonjour, Alice!

[bash]$ ruby ex29.rb ciao              # !!!!
Ciao, Bob!
```

* It is not allowed to define an alias for other alias.

```
## define an alias
Benry::CmdApp.define_alias("hello-it"   , ["hello", "-l", "it"])

## ERROR: define an alias for other alias
Benry::CmdApp.define_alias("ciao"       , "hello-it")   # !!!!
```

<!--
* `category "foo:", alias_for: "bar"` defines new alias `foo` which is an alias for `foo:bar` action.

File: ex30.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class GitAction < Benry::CmdApp::Action
  category "git:", alias_for: "status"

  @action.("show status in compact format")
  def status(path=".")
    system "git status -sb #{path}"
  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex30.rb -l
Actions:
  git                : alias for 'git:status'                     # !!!!
  git:status         : show status in compact format
  help               : print help message (of action if specified)
```
-->

* Global option `-L alias` lists all aliases.
  This option is hidden in default, therefore not shown in help message but available in default (for debug purpose).

```console
[bash]$ ruby ex30.rb -L alias
Aliases:
  git                : alias for 'git:status'
```


### Abbreviation of Category

Abbreviation of category is a shortcut of category prefix.
For example, when `b:` is an abbreviation of a category prefix `git:branch:`, you can invoke `git:branch:create` action by `b:create`.

File: ex31.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class GitAction < Benry::CmdApp::Action

  category "git:" do

    category "branch:" do

      @action.("create a new branch")
      def create(branch)
        puts "git checkout -b #{branch}"
      end

    end

  end

end

## define abbreviation 'b:' of category prefix 'git:branch:'
Benry::CmdApp.define_abbrev("b:", "git:branch:")     # !!!!

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex31.rb b:create topic1    # invokes 'git:branch:create' !!!!
git checkout -b topic1
```

Global option `-L abbrev` lists all abbreviations.
This option is hidden in default, therefore not shown in help message but available in default (for debug purpose).

```console
[bash]$ ruby ex31.rb -L abbrev
Abbreviations:
  b:         =>  git:branch:
```


### Default Action

* `config.default_action = "test1"` defines default action.
  In this case, action `test1` will be invoked if action name not specified in command-line.
* Default action name is shown in help message.

File: ex32.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  def test1()
    puts __method__
  end

end

exit Benry::CmdApp.main("sample app", "1.0.0",
                        default_action: "test1")   # !!!!
## or:
#config = Benry::CmdApp::Config.new("sample app", "1.0.0")
#config.default_action = "test1"     # !!!!
#app = Benry::CmdApp::Application.new(config)
#exit app.main()
```

Output:

```console
[bash]$ ruby ex32.rb test1
test1

[bash]$ ruby ex32.rb               # no action name!!!!
test1
```

Help message:

```console
[bash]$ ruby ex32.rb -h
ex32.rb --- sample app

Usage:
  $ ex32.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message (of action if specified)
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too

Actions: (default: test1)                   # !!!!
  help               : print help message (of action if specified)
  test1              : test action #1
```


### Action List and Category List

When `config.default_action` is not specified, Benry-CmdAction lists action names if action name is not specified in command-line.

File: ex33.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  def test1()
  end

  category "foo:" do

    @action.("test action #2")
    def test2()
    end

  end

  category "bar:" do

    @action.("test action #3")
    def test3()
    end

    category "baz:" do

      @action.("test action #4")
      def test4()
      end

    end

  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex33.rb            # no action name!!!!
Actions:
  bar:baz:test4      : test action #4
  bar:test3          : test action #3
  foo:test2          : test action #2
  help               : print help message (of action if specified)
  test1              : test action #1
```

Command-line option `-l, --list` also prints the same result of the above example.
This is useful if you specify default action name wit `config.default_action`.

Action name list contains alias names, too.
If you want to list only action names (or alias names), specify `-L action` or `-L alias` option.
See [Q: How to list only aliases (or actions) excluding actions (or aliases) ?](#q-how-to-list-only-aliases-or-actions-excluding-actions-or-aliases-) for details.

If category prefix (such as `xxx:`) is specified instead of action name,
Benry-CmdApp lists action names which have that category prefix.

Output:

```console
[bash]$ ruby ex33.rb foo:              # !!!!
Actions:
  foo:test2          : test action #2

[bash]$ ruby ex33.rb bar:              # !!!!
Actions:
  bar:baz:test4      : test action #4
  bar:test3          : test action #3
```

If `:` is specified instead of action name, Benry-CmdApp lists top-level category prefixes of action names and number of actions under the each category prefix.

Outuput:

```console
[bash]$ ruby ex33.rb :                 # !!!!
Categories: (depth=1)
  bar: (2)           # !!! two actions ('bar:test3' and 'bar:baz:test4')
  foo: (1)           # !!! one action ('foo:text2')
```

In the above example, only top-level category prefixes are displayed.
If you specified `::` instead of `:`, second-level category prefixes are displayed,
for example `foo:xxx:` and `foo:yyy:`.
Of course, `:::` displays more level category prefixes.

File: ex34.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class GitAction < Benry::CmdApp::Action
  category "git:"

  category "staging:" do
    @action.("...");  def add(); end
    @action.("...");  def show(); end
    @action.("...");  def delete(); end
  end

  category "branch:" do
    @action.("...");  def list(); end
    @action.("...");  def switch(name); end
  end

  category "repo:" do
    @action.("...");  def create(); end
    @action.("...");  def init(); end

    category "config:" do
      @action.("...");  def add(); end
      @action.("...");  def delete(); end
      @action.("...");  def list(); end
    end

    category "remote:" do
      @action.("...");  def list(); end
      @action.("...");  def set(); end
    end

  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex34.rb :
Categories: (depth=1)
  git: (12)

[bash]$ ruby ex34.rb ::             # !!!!
Categories: (depth=2)
  git: (0)
  git:branch: (2)
  git:repo: (7)
  git:staging: (3)

[bash]$ ruby ex34.rb :::            # !!!!
Categories: (depth=3)
  git: (0)
  git:branch: (2)
  git:repo: (2)
  git:repo:config: (3)
  git:repo:remote: (2)
  git:staging: (3)
```

`category()` can take a description of category as second argument.
Descriptions of category are displayed in the category prefix list.

File: ex35.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  category "foo:", "description of Foo" do
    @action.("test action #2")
    def test2()
    end
  end

  category "bar:", "description of Bar" do
    @action.("test action #3")
    def test3()
    end

    category "baz:", "description fo Baz" do
      @action.("test action #4")
      def test4()
      end
    end
  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex35.rb :                       # !!!!
Categories: (depth=1)
  bar: (2)           : description of Bar    # !!!!
  foo: (1)           : description of Foo    # !!!!
```


### Hidden Action

* If `hidden: true` keyword argument passed to `@action.()`,
  or action method is private, then Benry-CmdApp regards that action as hidden.
* Hidden actions are not shown in help message nor action list by default.
* Hidden actions are shown when `-a` or `--all` option is specified in command-line.

File: ex36.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  def test1()
    puts __method__
  end

  @action.("test action #2", hidden: true)  # !!!!
  def test2()
    puts __method__
  end

  private                      # !!!!

  @action.("test action #3")
  def test3()
    puts __method__
  end

end

exit Benry::CmdApp.main("sample app")
```

Action list (without `-a` nor `--all`):

```console
[bash]$ ruby ex36.rb
Actions:
  help               : print help message (of action if specified)
  test1              : test action #1
```

Action list (with `-a` or `--all`):

```console
[bash]$ ruby ex36.rb --all      # !!!!
Actions:
  help               : print help message (of action if specified)
  test1              : test action #1
  test2              : test action #2          # !!!!
  test3              : test action #3          # !!!!
```


### Hidden Option

* Options defined with `hidden: true` keyword argument are treated as hidden option.
* Hidden options are not shown in help message of action.
* Hidden options are shown when `-a` or `--all` option is specified in command-line.

File: ex37.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action")
  @option.(:verbose, "-v", "verbose mode")
  @option.(:debug , "-D", "debug mode", hidden: true)      # !!!!
  def test1(verbose: false, debug: false)
    puts "verbose=#{verbose}, debug=#{debug}"
  end

end

exit Benry::CmdApp.main("sample app")
```

Help message (without `-a` nor `--all`):

```console
[bash]$ ruby ex37.rb -h test1
ex37.rb test1 --- test action

Usage:
  $ ex37.rb test1 [<options>]

Options:
  -v                 : verbose mode
```

Help message (with `-a` or `--all`)

```console
[bash]$ ruby ex37.rb -h --all test1           # !!!!
ex37.rb test1 --- test action

Usage:
  $ ex37.rb test1 [<options>]

Options:
  -h, --help         : print help message     # !!!!
  -v                 : verbose mode
  -D                 : debug mode             # !!!!
```

In the above example, `-h, --help` option as well as `-D` option is shown.
In fact, Benry-CmdApp automatically adds `-h, --help` option to each action in hidden mode.
Therefore all actions accept `-h, --help` option.

For this reason, you should NOT define `-h` or `--help` options for your actions.


### Important Actions or Options

It is possible to mark actions or options as important or not.

* Actions or options marked as important are emphasized in help message.
* Actions or options marked as not important are weaken in help message.

File: ex38.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("important action", important: true)   # !!!!
  def test1()
  end

  @action.("not important action", important: false)   # !!!!
  def test2()
  end

  @action.("sample")
  @option.(:foo, "--foo", "important option", important: true)
  @option.(:bar, "--bar", "not important option", important: false)
  def test3(foo: nil, bar: nil)
  end

end

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex38.rb -l
Actions:
  help               : print help message (of action if specified)
  test1              : important action      # !!!! bold font !!!!
  test2              : not important action  # !!!! gray color !!!!
  test3              : sample

[bash]$ ruby ex38.rb -h test3
ex38.rb test3 --- sample

Usage:
  $ ex38.rb test3 [<options>]

Options:
  --foo              : important option      # !!!! bold font !!!!
  --bar              : not important option  # !!!! gray color !!!!
```


### Multiple Option

If you need multiple options like `-I` option of Ruby,
pass `multiple: true` to `@option.()`.

File: ex39.rb

```ruby
require 'benry/cmdapp'

class TestAction < Benry::CmdApp::Action

  @action.("multiple option test")
  @option.(:path, "-I <path>", "path", multiple: true)
  def test_(path: [])
    puts "path=#{path.inspect}"     #=> path=["/tmp", "/var/tmp"]
  end

end

exit Benry::CmdApp.main("test app")
```

Output:

```console
[bash]$ ruby ex39.rb test -I /tmp -I /var/tmp     # !!!!
path=["/tmp", "/var/tmp"]                         # !!!!
```



## Configuratoin and Customization


### Application Configuration

`Benry::CmdApp::Config` class configures application behaviour.

* `config.app_desc = "..."` sets command description which is shown in help message. (required)
* `config.app_version = "1.0.0"` enables `-V` and `--version` option, and prints version number if `-V` or `--version` option specified. (default: `nil`)
* `config.app_command = "<command>"` sets command name which is shown in help message. (default: `File.basname($0)`)
* `config.app_name = "<string>"` sets application name which is shown in help message. (default: same as `config.app_command`)
* `config.app_usage = "<text>" (or `["<text1>", "<text2>", ...]`) sets usage string in help message. (default: `" <action> [<arguments>...]"`)
* `config.app_detail = "<text>"` sets detailed description of command which is showin in help message. (default: `nil`)
* `config.backtrace_ignore_rexp = /.../` sets regular expression to ignore backtrace when error raised. (default: `nil`)
* `config.help_description = "<text>"` sets text of 'Description:' section in help message. (default: `nil`)
* `config.help_postamble = {"<Title>:" => "<text>"}` sets postamble of help message, such as 'Example:' or 'Tips:'. (default: `nil`)
* `config.default_action = "<action>"` sets default action name. (default: `nil`)
* `config.option_help = true` enables `-h` and `--help` options. (default: `true`)
* `config.option_version = true` enables `-V` and `--version` options. (default: `true` if `app_version` provided, `false` if else)
* `config.option_list = true` enables `-l` and `--list` options. (default: `true`)
* `config.option_topic = true` enables `-L <topic>` option. (default: `:hidden`)
* `config.option_all = true` enables `-a` and `--all` options which shows private (hidden) actions and options into help message. (default: `true`)
* `config.option_verbose = true` enables `-v` and `--verbose` options which sets `$QUIET_MODE = false`. (default: `false`)
* `config.option_quiet = true` enables `-q` and `--quiet` options which sets `$QUIET_MODE = true`. (default: `false`)
* `config.option_color = true` enables `--color[=<on|off>]` option which sets `$COLOR_MODE = true/false`. This affects to help message colorized or not. (default: `false`)
* `config.option_debug = true` enables `-D` and `--debug` options which sets `$DEBUG_MODE = true`. (default: `:hidden`)
* `config.option_trace = true` enables `-T` and `--trace` options. Entering into and exitting from action are reported when trace mode is on. (default: `false`)
* `config.option_dryrun = true` enables `-X` and `--dryrun` options which sets `$DRYRUN_MODE = true`. (default: `false`)
* `config.format_option = "  %-18s : %s"` sets format of options in help message. (default: `"  %-18s : %s"`)
* `config.format_action = "  %-18s : %s"` sets format of actions in help message. (default: `"  %-18s : %s"`)
* `config.format_usage = "  $ %s"` sets format of usage in help message. (default: `"  $ %s"`)
* `config.format_avvrev = "  %-10s =>  %s"` sets format of abbreviations in output of `-L abbrev` option. (default: `"  %-10s =>  %s"`)
* `config.format_usage = "  $ %s"` sets format of usage in help message. (default: `"  $ %s"`)
* `config.format_category = "  $-18s : %s""` sets format of category prefixes in output of `-L category` option. (default: `nil` which means to use value of `config.format_action`)

File: ex41.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

config = Benry::CmdApp::Config.new("sample app", "1.0.0", app_name: "Sample App")
config.each(sort: false) do |name, val|
  puts "config.%-20s = %s" % [name, val.inspect]
end
```

Output:

```console
[bash]$ ruby ex41.rb
config.app_desc             = "sample app"
config.app_version          = "1.0.0"
config.app_name             = "Sample App"
config.app_command          = "ex41.rb"             # == File.basename($0)
config.app_usage            = nil
config.app_detail           = nil
config.default_action       = nil
config.help_description     = nil
config.help_postamble       = nil
config.format_option        = "  %-18s : %s"
config.format_action        = "  %-18s : %s"
config.format_usage         = "  $ %s"
config.format_category      = nil
config.deco_command         = "\e[1m%s\e[0m"        # bold
config.deco_header          = "\e[1;34m%s\e[0m"     # bold, blue
config.deco_extra           = "\e[2m%s\e[0m"        # gray color
config.deco_strong          = "\e[1m%s\e[0m"        # bold
config.deco_weak            = "\e[2m%s\e[0m"        # gray color
config.deco_hidden          = "\e[2m%s\e[0m"        # gray color
config.deco_debug           = "\e[2m%s\e[0m"        # gray color
config.deco_error           = "\e[31m%s\e[0m"       # red
config.option_help          = true
config.option_version       = true
config.option_list          = true
config.option_topic         = :hidden
config.option_all           = true
config.option_verbose       = false
config.option_quiet         = false
config.option_color         = false
config.option_debug         = :hidden
config.option_trace         = false
config.option_dryrun        = false
config.backtrace_ignore_rexp = nil
config.trace_mode           = nil
```

You may notice that the value of `config.option_debug` is `:hidden`.
If value of `config.option_xxxx` is `:hidden`, then corresponding global option is enabled as hidden option.
Therefore you can see `--debug` option in help message if you add `-h` and `-a` (or `--all`) option.

Help message:

```console
$ ruby ex37.rb -h -a                          # !!!!
ex37.rb --- sample app

Usage:
  $ ex37.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message (of action if specified)
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too
      --debug        : debug mode             # !!!!

Actions:
  help               : print help message (of action if specified)
  test1              : test action
```


### Customization of Global Options

To add custom global options:

* (1) Create a global option schema object.
* (2) Add custom options to it.
* (3) Pass it to `Application.new()`.

File: ex42.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action")
  def test1()
    puts __method__
  end

end

## (1) create global option shema
config = Benry::CmdApp::Config.new("sample app")
schema = Benry::CmdApp::GlobalOptionSchema.new(config)  # !!!!

## (2) add custom options to it
schema.add(:logging, "--logging", "enable logging")    # !!!!

## (3) pass it to ``Application.new()``
app = Benry::CmdApp::Application.new(config, schema)   # !!!!

exit app.main()
```

Help message:

```console
[bash]$ ruby ex42.rb -h
ex42.rb --- sample app

Usage:
  $ ex42.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message (of action if specified)
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too
  --logging          : enable logging          # !!!!

Actions:
  help               : print help message (of action if specified)
  test1              : test action
```

To customize global options entirely:

* (1) Create empty `GlobalOptionSchema` object.
* (2) Add global options as you want.
* (3) Create and execute Application object with it.

File: ex43.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

## (1) Create empty ``GlobalOptionSchema`` object.
schema = Benry::CmdApp::GlobalOptionSchema.new(nil)   # !!!!

## (2) Add global options as you want.
schema.add(:help   , "-h, --help"   , "print help message")
schema.add(:version, "-V, --version", "print version")
schema.add(:list   , "-l, --list"   , "list actions and aliases")
schema.add(:all    , "-a, --all"    , "list hidden actions/options, too")
schema.add(:verbose, "-v, --verbose", "verbose mode")
schema.add(:quiet  , "-q, --quiet"  , "quiet mode")
schema.add(:color  , "--color[=<on|off>]", "enable/disable color mode", type: TrueClass)
schema.add(:debug  , "-D, --debug"  , "set $DEBUG_MODE to true")
schema.add(:trace  , "-T, --trace"  , "report enter into and exit from action")

## (3) Create and execute Application object with it.
config = Benry::CmdApp::Config.new("sample app", "1.0.0")
app = Benry::CmdApp::Application.new(config, schema)  # !!!!
exit app.main()
```

Help message:

```console
[bash]$ ruby ex43.rb -h
ex43.rb (1.0.0) --- sample app

Usage:
  $ ex43.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message
  -V, --version      : print version
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too
  -v, --verbose      : verbose mode
  -q, --quiet        : quiet mode
  --color[=<on|off>] : enable/disable color mode
  -D, --debug        : set $DEBUG_MODE to true
  -T, --trace        : report enter into and exit from action

Actions:
  help               : print help message (of action if specified)
```



### Customization of Global Option Behaviour

* (1) Define subclass of `Application` class.
* (2) Override `#toggle_global_options()` method.
* (3) Create and execute subclass object of `Application`.

File: ex44.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

## (1) Define subclass of ``Application`` class.
class MyApplication < Benry::CmdApp::Application

  ## (2) Override ``#toggle_global_options()`` method.
  def toggle_global_options(global_opts)
    status_code = super
    return status_code if status_code  # `return 0` means "stop process successfully",
                                       # `return 1` means "stop process as failed".
    if global_opts[:logging]
      require 'logger'
      $logger = Logger.new(STDOUT)
    end
    return nil                   # `return nil` means "continue process".
  end

end

## (3) Create and execute subclass object of ``Application``.
config = Benry::CmdApp::Config.new("sample app")
app = MyApplication.new(config)            # !!!!
exit app.main()
```

Of course, prepending custom module to Application class is also effective way.

File: ex45.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

module MyApplicationMod

  def toggle_global_options(global_opts)
    # ....
  end

end

Benry::CmdApp::Application.prepend(MyApplicationMod)   # !!!!

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```


### Custom Hook of Application

* (1) Define subclass of Application class.
* (2) Override `#handle_action()` method.
* (3) Create and execute custom application object.

File: ex46.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action")
  def test1()
    $logger.info("logging message") if $logger
  end

end

## (1) Define subclass of Application class
class MyApplication < Benry::CmdApp::Application   # !!!!

  ## (2) Override method
  def handle_action(action, args)                  # !!!!
    #p @config
    $logger.debug("action=#{action}, args=#{args.inspect}") if $logger
    super                                          # !!!!
  end

end

## (3) create and execute custom application object
config = Benry::CmdApp::Config.new("sample app")
schema = Benry::CmdApp::GlobalOptionSchema.new(config)
schema.add(:logging, "--logging", "enable logging")
app = MyApplication.new(config, schema)             # !!!!
exit app.main()
```


### Customization of Application Help Message

If you want to just add more text into application help message,
set the followings:

.* `config.app_detail = <text>` --- print text before 'Usage:' section.
.* `config.help_description = <text>` --- print text after 'Usage:' section as 'Description:' section.
.* `config.help_postamble = {<head> => <text>}` --- print at end of help message.

File: ex47.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

config = Benry::CmdApp::Config.new("sample app", "1.0.0")
config.app_detail = "See https://...."            # !!!!
config.help_description = "  Bla bla bla"         # !!!!
config.help_postamble = [                         # !!!!
  {"Example:" => "  $ <command> hello Alice\n"},  # !!!!
  "(Tips: ....)",                                 # !!!!
]                                                 # !!!!

app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message:

```console
[bash]$ ruby ex47.rb -h
ex47.rb --- sample app

See https://....                       # !!!!

Usage:
  $ ex47.rb [<options>] <action> [<arguments>...]

Description:                           # !!!!
  Bla bla bla                          # !!!!

Options:
  -h, --help         : print help message (of action if specified)
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too

Actions:
  hello              : test action #1

Example:                                # !!!!
  $ <command> hello Alice               # !!!!

(Tips: ....)                            # !!!!
```

If you want to change behaviour of building command help message:

* (1) Define subclass of `Benry::CmdApp::ApplicationHelpBuilder` class.
* (2) Override methods.
* (3) Create an instance object of the class.
* (4) Pass it to Application object.

File: ex48.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("print greeting message")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

## (1) Define subclass of ``Benry::CmdApp::ApplicationHelpBuilder`` class.
class MyAppHelpBuilder < Benry::CmdApp::ApplicationHelpBuilder

  ## (2) Override methods.
  def build_help_message(gschema, all: false)
    super
  end
  def section_preamble()
    super
  end
  def section_usage()
    super
  end
  def section_options(global_opts_schema, all: false)
    super
  end
  def section_actions(include_aliases=true, all: false)
    super
  end
  def section_postamble()
    super
  end
  ### optional (for `-L <topic>` option)
  #def section_candidates(prefix, all: false); super; end
  #def section_aliases(all: false); super; end
  #def section_abbrevs(all: false); super; end
  #def section_categories(depth=0, all: false); super; end
end

## (3) Create an instance object of the class.
config = Benry::CmdApp::Config.new("sample app")
schema = Benry::CmdApp::GlobalOptionSchema.new(config)
schema.add(:logging, "--logging", "enable logging")
app_help_builder = MyAppHelpBuilder.new(config)      # !!!!

## (4) Pass it to Application object.
app = Benry::CmdApp::Application.new(config, schema, app_help_builder) # !!!!
exit app.main()
```

More simple way:

* (1) Create a module and override methods of `Benry::CmdApp::ApplicationHelpBuilder` class.
* (2) Prepend it to `Benry::CmdApp::ApplicationHelpBuilder` class.
* (3) Create and execute Application object.

File: ex49.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("print greeting message")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

## (1) Create a module and override methods of ``ApplicationHelpBuilder`` class.
module MyHelpBuilderMod
  def build_help_message(gschema, all: false)
    super
  end
  def section_preamble()
    super
  end
  def section_usage()
    super
  end
  def section_options(global_opts_schema, all: false)
    super
  end
  def section_actions(include_aliases=true, all: false)
    super
  end
  def section_postamble()
    super
  end
  ### optional (for `-L <topic>` option)
  #def section_candidates(prefix, all: false); super; end
  #def section_aliases(all: false); super; end
  #def section_abbrevs(all: false); super; end
  #def section_categories(depth=0, all: false); super; end
end

## (2) Prepend it to ``Benry::CmdApp::ApplicationHelpBuilder`` class.
Benry::CmdApp::ApplicationHelpBuilder.prepend(MyHelpBuilderMod)

## (3) Run application.
exit Benry::CmdApp.main("sample app")
```


### Customization of Action Help Message

If you want to just add more text into action help message,
pass the following keyword arguments to `@action.()`.

* `detail: <text>` --- printed before 'Usage:' section.
* `description: <text>` --- printed after 'Usage:' section as 'Description:' section, like `man` command in UNIX.
* `postamble: {<header> => <text>}` --- printed at end of help message as a dedicated section.

File: ex50.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1",
           detail: "See https://....",           # !!!!
           description: "  Bla bla bla",         # !!!!
           postamble: {"Example:" => "  ...."})  # !!!!
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

exit Benry::CmdApp.main("sample app")
```

Help message:

```console
[bash]$ ruby ex50.rb -h hello
ex50.rb hello --- test action #1

See https://....                  # !!!!

Usage:
  $ ex50.rb hello [<user>]

Description:                      # !!!!
  Bla bla bla                     # !!!!

Example:
  ....                            # !!!!
```

If you want to change behaviour of building action help message:

* (1) Define subclass of `ActionHelpBuilder` class.
* (2) Override methods.
* (3) Create an instance object of the class.
* (4) Pass it to Application object.

File: ex51.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("print greeting message")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

## (1) Define subclass of ``ActionHelpBuilder`` class.
class MyActionHelpBuilder < Benry::CmdApp::ActionHelpBuilder
  ## (2) Override methods.
  def build_help_message(metadata, all: false)
    super
  end
  def section_preamble(metadata)
    super
  end
  def section_usage(metadata, all: false)
    super
  end
  def section_description(metadata)
    super
  end
  def section_options(metadata, all: false)
    super
  end
  def section_postamble(metadata)
    super
  end
end

## (3) Create an instance object of the class.
config = Benry::CmdApp::Config.new("sample app")
action_help_builder = MyActionHelpBuilder.new(config)

## (4) Pass it to Application object.
schema = Benry::CmdApp::GlobalOptionSchema.new(config)
app = Benry::CmdApp::Application.new(config, schema, nil, action_help_builder)
exit app.main()
```

Another way:

* (1) Create a module and override methods of `Benry::CmdApp::ActionHelpBuilder` class.
* (2) Prepend it to `Benry::CmdApp::ActionHelpBuilder` class.
* (3) Run application.

File: ex52.rb

```ruby
# coding: utf-8
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("print greeting message")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

## (1) Create a module and override methods of ``ActionHelpBuilder`` class.
module MyActionHelpBuilderMod
  def build_help_message(metadata, all: false)
    super
  end
  def section_preamble(metadata)
    super
  end
  def section_usage(metadata, all: false)
    super
  end
  def section_description(metadata)
    super
  end
  def section_options(metadata, all: false)
    super
  end
  def section_postamble(metadata)
    super
  end
end

## (2) Prepend it to ``Benry::CmdApp::ActionHelpBuilder`` class.
Benry::CmdApp::ActionHelpBuilder.prepend(MyActionHelpBuilderMod)  # !!!!

## (3) Run application.
exit Benry::CmdApp::main("sample app")
```


### Customization of Section Title in Help Message

If you want to change section titles such as 'Options:' or 'Actions:'
in the help message, override the constants representing section titles.

The following constants are defined in `BaseHelperBuilder` class.

```ruby
module Benry::CmdApp
  class BaseHelpBuilder
    HEADER_USAGE       = "Usage:"
    HEADER_DESCRIPTION = "Description:"
    HEADER_OPTIONS     = "Options:"
    HEADER_ACTIONS     = "Actions:"
    HEADER_ALIASES     = "Aliases:"
    HEADER_ABBREVS     = "Abbreviations:"
    HEADER_CATEGORIES  = "Categories:"
```

You can override them in `ApplicationHelpBuilder` or `ActionHelpBuilder`
classes which are subclass of `BaseHandlerBuilder` class.

```ruby
## for example
Benry::CmdApp::ApplicationHelpBuilder::HEADER_ACTIONS = "ACTIONS:"
Benry::CmdApp::ActionHelpBuilder::HEADER_OPTIONS = "OPTIONS:"
```

If you want to change just decoration of section titles,
set `config.deco_header`.

```ruby
config = Benry::CmdApp::Config.new("Test App", "1.0.0")
config.deco_header = "\e[1;34m%s\e[0m"     # bold, blue
#config.deco_header = "\e[1;4m%s\e[0m"     # bold, underline
```



## Q & A


### Q: How to show all backtraces of exception?

A: Add `--deubg` option.
Benry-CmdApp catches exceptions and handles their backtrace
automatically in default, but doesn't catch them when `--debug`
option is specified.


### Q: How to specify description to arguments of actions?

A: Can't. It is possible to specify description to actions or options,
but not possible to arguments of actions.


### Q: How to append some tasks to an existing action?

A: (a) Use method alias, or (b) use prepend.

File: ex61.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

  @action.("test action #2")
  def hi(user="world")
    puts "Hi, #{user}!"
  end

end

## (a) use method alias
class SampleAction               # open existing class
  alias __old_hello hello        # alias for existing method
  def hello(user="world")        # override existing method
    puts "---- >8 ---- >8 ----"
    __old_hello(user)            # call original method
    puts "---- 8< ---- 8< ----"
  end
end

## (b) use prepend
module SampleMod                 # define new module
  def hi(user="world")           # override existing method
    puts "~~~~ >8 ~~~~ >8 ~~~~"
    super                        # call original method
    puts "~~~~ 8< ~~~~ 8< ~~~~"
  end
end
SampleAction.prepend(SampleMod)  # prepend it to existing class

exit Benry::CmdApp.main("sample app")
```

Output:

```console
[bash]$ ruby ex61.rb hello
---- >8 ---- >8 ----
Hello, world!
---- 8< ---- 8< ----

[bash]$ ruby ex61.rb hi Alice
~~~~ >8 ~~~~ >8 ~~~~
Hi, Alice!
~~~~ 8< ~~~~ 8< ~~~~
```


### Q: How to delete an existing action/alias?

A: Call `Benry::CmdApp.undef_action("<action>")` or `Benry::CmdApp.undef_alias("<alias>")`.


### Q: How to re-define an existing action?

A: First remove the existing action, then re-define the action.

File: ex62.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("sample action")
  def hello()                               # !!!!
    puts "Hello, world!"
  end

end

Benry::CmdApp.undef_action("hello")        # !!!!

class OtherAction < Benry::CmdApp::Action

  @action.("other action")                  # !!!!
  def hello()                               # !!!!
    puts "Ciao, world!"
  end

end

exit Benry::CmdApp.main("sample app")
```

Help message:

```console
[bash]$ ruby ex62.rb -h
ex62.rb --- sample app

Usage:
  $ ex62.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message (of action if specified)
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too

Actions:
  hello              : other action       # !!!!
  help               : print help message (of action if specified)
```


### Q: How to show entering into or exitting from actions?

A: Set `config.option_trace = true` and pass `-T` (or `--trace`) option.

File: ex63.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("preparation")
  def prepare()
    puts "... prepare something ..."
  end

  @action.("build")
  def build()
    run_once("prepare")
    puts "... build something ..."
  end

end

exit Benry::CmdApp.main("sample app", "1.0.0",
     			option_trace: true)    # !!!! (or `:hidden`)
```

Output:

```console
[bash]$ ruby ex63.rb --trace build              # !!!!
### enter: build
### enter: prepare
... prepare something ...
### exit:  prepare
... build something ...
### exit:  build
```


### Q: How to enable/disable color mode?

A: Set `config.option_color = true` and pass `--color=on` or `--color=off` option.

File: ex64.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("print greeting message")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

exit Benry::CmdApp.main("sample app",
                        option_color: true)         # !!!!
```

Help message:

```console
[bash]$ ruby ex64.rb -h
ex64.rb --- sample app

Usage:
  $ ex64.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message (of action if specified)
  -l, --list         : list actions and aliases
  -a, --all          : list hidden actions/options, too
  --color[=<on|off>] : enable/disable color      # !!!!

Actions:
  hello              : print greeting message

[bash]$ ruby ex64.rb -h --color=off              # !!!!

[bash]$ ruby ex64.rb -h --color=on               # !!!!
[bash]$ ruby ex64.rb -h --color                  # !!!!
```


### Q: How to define `-vvv` style option?

A: Provide block parameter on `@option.()`.

File: ex65.rb

```ruby
require 'benry/cmdapp'

class TestAction < Benry::CmdApp::Action

  @action.("set verbose level")
  @option.(:verbose, "-v", "verbose level") {|opts, key, val|  # !!!!
    opts[key] ||= 0                                            # !!!!
    opts[key] += 1                                             # !!!!
  }                                                            # !!!!
  def test_(verbose: 0)
    puts "verbose=#{verbose}"
  end

end

exit Benry::CmdApp.main("test app")
```

Output:

```console
[bash]$ ruby ex65.rb test -v              # !!!!
verbose=1
[bash]$ ruby ex65.rb test -vv             # !!!!
verbose=2
[bash]$ ruby ex65.rb test -vvv            # !!!!
verbose=3
```


### Q: How to show global option `-L <topic>` in help message?

A: Set `config.option_topic = true` (default: `:hidden`).


### Q: How to specify detailed description of options?

A: Add `detail:` keyword argument to `@option.()`.

File: ex66.rb

```ruby
require 'benry/cmdapp'

class TestAction < Benry::CmdApp::Action

  @action.("detailed description test")
  @option.(:mode, "-m <mode>", "output mode", detail: <<"END")
   v, verbose: print many output
   q, quiet:   print litte output
   c, compact: print summary output
END
  def test_(mode: nil)
    puts "mode=#{mode.inspect}"
  end

end

exit Benry::CmdApp.main("test app")
```

Help message:

```console
[bash]$ ruby ex66.rb -h test
ex66.rb test --- detailed description test

Usage:
  $ ex66.rb test [<options>]

Options:
  -m <mode>          : output mode
                          v, verbose: print many output
                          q, quiet:   print litte output
                          c, compact: print summary output
```


<!--
### Q: What is the difference between `category(alias_for:)` and `category(action:)`?

A: The former defines an alias, and the latter doesn't.

File: ex67.rb

```ruby
require 'benry/cmdapp'

class AaaAction < Benry::CmdApp::Action
  category "aaa:", alias_for: "print"

  @action.("test #1")
  def print_()
    puts "test"
  end

end

class BbbAction < Benry::CmdApp::Action
  category "bbb:", action: "print"

  @action.("test #2")
  def print_()
    puts "test"
  end

end

exit Benry::CmdApp.main("sample app")
```

Help message:

```console
[bash]$ ruby ex67.rb -h
ex67.rb --- sample app

Usage:
  $ ex67.rb [<options>] <action> [<arguments>...]

Options:
  -h, --help         : print help message (of action if specified)
  -l, --list         : list actions and aliases
  -L <topic>         : topic list (actions|aliases|categories|abbrevs)
  -a, --all          : list hidden actions/options, too

Actions:
  aaa                : alias for 'aaa:print' action   # !!!!
  aaa:print          : test #1
  bbb                : test #2                        # !!!!
  help               : print help message (of action if specified)
```

In the above example, alias `aaa` is defined due to `category(alias_for:)`,
and action `bbb` is not an alias due to `category(action:)`.
-->


### Q: How to list only aliases (or actions) excluding actions (or aliases) ?

A: Specify global option `-L alias` or `-L action`.

```console
[bash]$ ruby gitexample.rb -l
Actions:
  git                : alias for 'git:status'
  git:stage          : put changes of files into staging area
  git:staged         : show changes in staging area
  git:status         : show status in compact format
  git:unstage        : remove changes from staging area
  stage              : alias for 'git:stage'
  staged             : alias for 'git:staged'
  unstage            : alias for 'git:unstage'

### list only aliases (ordered by action name automatically)
[bash]$ ruby gitexample.rb -L alias     # !!!!
Aliases:
  stage              : alias for 'git:stage'
  staged             : alias for 'git:staged'
  git                : alias for 'git:status'
  unstage            : alias for 'git:unstage'

### list only actions
[bash]$ ruby gitexample.rb -L action     # !!!!
Actions:
  git:stage          : put changes of files into staging area
  git:staged         : show changes in staging area
  git:status         : show status in compact format
  git:unstage        : remove changes from staging area
```

Notice that `-L alias` sorts aliases by action names.
This is the intended behaviour.


### Q: How to change the order of options in help message?

A: Call `GlobalOptionSchema#reorder_options()`.

File: ex68.rb

```ruby
require 'benry/cmdapp'

config = Benry::CmdApp::Config.new("sample app", "1.0.0",
  option_verbose:   true,
  option_quiet:     true,
  option_color:     true,
)
schema = Benry::CmdApp::GlobalOptionSchema.new(config)
keys = [:verbose, :quiet, :color, :help, :version, :all, :target, :list]  # !!!!
schema.reorder_options(*keys)               # !!!!
app = Benry::CmdApp::Application.new(config, schema)
## or:
#app = Benry::CmdApp::Application.new(config)
#app.schema.reorder_options(*keys)          # !!!!
exit app.main()
```

Help message:

```console
[bash]$ ruby ex68.rb -h
ex68.rb (1.0.0) --- sample app

Usage:
  $ ex68.rb [<options>] <action> [<arguments>...]

Options:
  -v, --verbose      : verbose mode
  -q, --quiet        : quiet mode
  --color[=<on|off>] : color mode
  -h, --help         : print help message (of action if specified)
  -V, --version      : print version
  -a, --all          : list hidden actions/options, too
  -L <topic>         : topic list (actions|aliases|categories|abbrevs)
  -l, --list         : list actions and aliases

Actions:
  help               : print help message (of action if specified)
```


### Q: How to add metadata to actions or options?

A: Pass `tag:` keyword argument to `@action.()` or `@option.()`.

* `tag:` keyword argument accept any type of value such as symbol, string, array, and so on.
* Currenty, Benry-CmdApp doesn't provide the good way to use it effectively.
  This feature may be used by command-line application or framework based on Benry-CmdApp.

File: ex69.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("print greeting message", tag: :important)            # !!!!
  @option.(:repeat, "-r <N>", "repeat N times", tag: :important) # !!!!
  def hello(user="world", repeat: nil)
    (repeat || 1).times do
      puts "Hello, #{user}!"
    end
  end

end

exit Benry::CmdApp.main("sample app")
```


### Q: How to remove common help option from all actions?

A: Clears `Benry::CmdApp::ACTION_SHARED_OPTIONS` which is an array of option item.

File: ex70.rb

```ruby
require 'benry/cmdapp'

arr = Benry::CmdApp::ACTION_SHARED_OPTIONS
arr.clear()
```


### Q: Is it possible to show details of actions and aliases?

A: Try global option `-L metadata`.
It prints detailed data of actions and aliases in YAML format.


### Q: How to make error messages I18Ned?

A: Currently not supported. May be supported in a future release.




## License and Copyright

* $License: MIT License $
* $Copyright: copyright(c) 2023 kwatch@gmail.com $
