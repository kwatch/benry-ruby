Benry::CmdApp README
====================

($Release: 0.0.0 $)

Benry::CmdApp is a framework to create command-line application.
If you want create command-line application which takes sub-commands
like `git`, `docker`, or `npm`, Benry:CmdApp is the solution.

Base idea:

* Sub-command (= action) is defined as a method in Ruby.
* Commnad-line arguments are passed to action method as positional arguments.
* Command-line options are passed to action method as keyword arguments.

For example:

* `<command> action1` in command-line invokes action method `action1()` in Ruby.
* `<command> action1 arg1 arg2` invokes `action1("arg1", "arg2")`.
* `<command> action1 arg --opt=val` invokes `action1("arg", opt: "val")`.

(Benry::CmdApp requires Ruby >= 2.3)


Table of Contents
-----------------

<!-- TOC -->

* <a href="#install">Install</a>
* <a href="#usage">Usage</a>
  * <a href="#action">Action</a>
  * <a href="#method-name-and-action-name">Method Name and Action Name</a>
  * <a href="#parameter-name-in-help-message-of-action">Parameter Name in Help Message of Action</a>
  * <a href="#options">Options</a>
  * <a href="#option-definition-format">Option Definition Format</a>
  * <a href="#option-value-validation">Option Value Validation</a>
  * <a href="#callback-for-option-value">Callback for Option Value</a>
  * <a href="#boolean-onoff-option">Boolean (On/Off) Option</a>
  * <a href="#substitue-value-instead-of-true">Substitue Value Instead of True</a>
  * <a href="#prefix-of-action-name">Prefix of Action Name</a>
  * <a href="#invoke-other-action">Invoke Other Action</a>
  * <a href="#action-alias">Action Alias</a>
  * <a href="#default-action">Default Action</a>
  * <a href="#default-help">Default Help</a>
  * <a href="#private-hidden-action">Private (Hidden) Action</a>
  * <a href="#private-hidden-option">Private (Hidden) Option</a>
* <a href="#configuratoin-and-customization">Configuratoin and Customization</a>
  * <a href="#application-configuration">Application Configuration</a>
  * <a href="#custom-global-options">Custom Global Options</a>
  * <a href="#custom-hook-of-application">Custom Hook of Application</a>
  * <a href="#customization-of-command-help-message">Customization of Command Help Message</a>
  * <a href="#customization-of-action-help-message">Customization of Action Help Message</a>
  * <a href="#changing-behaviour-of-global-options">Changing Behaviour of Global Options</a>
* <a href="#q--a">Q &amp; A</a>
  * <a href="#q-how-to-append-some-tasks-to-existing-action">Q: How to Append Some Tasks to Existing Action?</a>
  * <a href="#q-how-to-show-entering-into-or-exitting-from-action">Q: How to Show Entering Into or Exitting From Action?</a>
  * <a href="#q-how-to-enabledisable-color-mode">Q: How to Enable/Disable Color Mode?</a>
  * <a href="#q-how-to-copy-all-options-from-other-action">Q: How to Copy All Options from Other Action?</a>
  * <a href="#q-what-is-the-difference-between-prefixalias_of-and-prefixdefault">Q: What is the Difference Between `prefix(alias_of:)` and `prefix(default:)`?</a>
  * <a href="#q-is-it-possible-to-add-add-metadata-to-action-or-option">Q: Is It Possible to Add Add Metadata to Action or Option?</a>
* <a href="#license-and-copyright">License and Copyright</a>

<!-- /TOC -->


Install
=======

```console
$ gem install benry-cmdapp
```



Usage
=====


Action
------

* Inherit action class and define action methods in it.
* An action class can have several action methods.
* It is ok to define multiple action classes.
* Command-line arguments are passed to action method as positional arguments.

File: ex01.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

## action
class MyAction < Benry::CmdApp::Action    # !!!!

  @action.("print greeting message")      # !!!!
  def hello(user="world")                 # !!!!
    puts "Hello, #{user}!"
  end

end

## configuration
config = Benry::CmdApp::Config.new("sample app", "1.0.0")
config.default_help = true

## run application
app = Benry::CmdApp::Application.new(config)
status_code = app.main()
exit status_code
```

Output:

```console
[bash]$ ruby ex01.rb hello
Hello, world!

[bash]$ ruby ex01.rb hello Alice
Hello, Alice!
```

Help message of command:

```console
[bash]$ ruby ex01.rb -h     # or `--help`
ex01.rb (1.0.0) -- sample app

Usage:
  $ ex01.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)
  -V, --version      : print version

Actions:
  hello              : print greeting message
```

Help message of action:

```console
[bash]$ ruby ex01.rb -h hello
ex01.rb hello -- print greeting message

Usage:
  $ ex01.rb hello [<user>]
```


Method Name and Action Name
---------------------------

* Method name `print_` results in action name `print`.
  This is useful to define actions which name is same as Ruby keyword or popular functions.
* Method name `foo_bar_baz` results in action name `foo-bar-baz`.
* Method name `foo__bar__baz` results in action name `foo:bar:baz`.

File: ex02.rb

```ruby
#!/usr/bin/env ruby
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

config = Benry::CmdApp::Config.new("test app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message:

```console
[bash]$ ruby ex02.rb --help
ex02.rb -- test app

Usage:
  $ ex02.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)

Actions:
  foo-bar-baz        : sample #2
  foo:bar:baz        : sample #3
  print              : sample #1
```

Output:

```console
[bash]$ ruby ex02.rb print
print_

[bash]$ ruby ex02.rb foo-bar-baz
foo_bar_baz

[bash]$ ruby ex02.rb foo:bar:baz
foo__bar__baz
```


Parameter Name in Help Message of Action
----------------------------------------

In help message of action, positional parameters of action methods are printed under the name conversion rule.

* Parameter `foo` is printed as `<foo>`.
* Parameter `foo_bar_baz` is printed as `<foo-bar-baz>`.
* Parameter `foo_or_bar_or_baz` is printed as `<foo|bar|baz>`.

In addition, positional parameters are printed in different way according to its kind.

* If parameter `foo` is required (= doesn't have default value), it will be printed as `<foo>`.
* If parameter `foo` is optional (= has default value), it will be printed as `[<foo>]`.
* If parameter `foo` is variable length (= `*foo` style), it will be printed as `[<foo>...]`.


File: ex03.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("parameter names test")
  def test1(aaa, bbb_or_ccc, ddd=nil, eee=nil, *fff)  # !!!!
    # ...
  end

end

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message:

```console
[bash]$ ruby ex03.rb -h test1
hoge.rb test1 -- parameter names test

Usage:
  $ ex03.rb test1 <aaa> <bbb|ccc> [<ddd> [<eee> [<fff>...]]]  # !!!!
```


Options
-------

* Action can take command-line options.
* Option values specified in command-line are passed to actio method as keyword arguments.

File: ex04.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

## action
class MyAction < Benry::CmdApp::Action

  @action.("print greeting message")
  @option.(:lang, "-l, --lang=<en|fr|it>", "language")   # !!!!
  def hello(user="world", lang: "en")                    # !!!!
    case lang
    when "en" ; puts "Hello, #{user}!"
    when "fr" ; puts "Bonjour, #{user}!"
    when "it" ; puts "Ciao, #{user}!"
    else
      raise "#{lang}: unknown language."
    end
  end

end

## configuration
config = Benry::CmdApp::Config.new("sample app", "1.0.0")
config.default_help = true

## run application
app = Benry::CmdApp::Application.new(config)
status_code = app.main()
exit status_code
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
#!/usr/bin/env ruby
require 'benry/cmdapp'

## action
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
        raise "#{lang}: unknown language."
      end
    end
  end

end

## configuration
config = Benry::CmdApp::Config.new("sample app", "1.0.0")
config.default_help = true

## run application
app = Benry::CmdApp::Application.new(config)
status_code = app.main()
exit status_code
```

Output:

```console
[bash]$ ruby ex05.rb hello Alice -l fr --repeat=3
Bonjour, Alice!
Bonjour, Alice!
Bonjour, Alice!
````

Help message:

```console
[bash]$ ruby ex05.rb -h hello
ex05.rb hello -- print greeting message

Usage:
  $ ex05.rb hello [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language        # !!!!
      --repeat=<N>   : repeat <N> times   # !!!!
```

For usability reason, Benry::CmdApp supports `--lang=<val>` style long option
and doesn't support `--lang <val>` style option.
Benry::CmdApp regards `--lang <val>` as 'long option without argument'
and 'argument for command'.

```console
[bash]$ ruby ex05.rb hello --lang fr         # `--lang fr` != `--lang=fr`
[ERROR] --lang: argument required.
```


Option Definition Format
------------------------

* Option definition format should be one of:
** (short option) `-q`  : no values.
** (short option) `-f <file>` : value required.
** (short option) `-i[<width>]` : value is optional.
** (long option) `--quiet`  : no values.
** (long option) `--file=<file>` : value required.
** (long option) `--indent[=<width>]` : value is optional.
** (short & long) `-q, --quiet`  : no values.
** (short & long) `-f, --file=<file>` : value required.
** (short & long) `-i, --indent[=<width>]` : value is optional.

File: ex06.rb

```ruby
#!/usr/bin/env ruby
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

config = Benry::CmdApp::Config.new("test app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
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
[bash]$ ruby ex06.rb test1 -i                 # `-i` results in `true`
quiet=false, file=nil, indent=true
[bash]$ ruby ex06.rb test1 -i4                # `-i4` results in `4`
quiet=false, file=nil, indent="4"

[bash]$ ruby ex06.rb test2 --indent           # `--indent` results in `true`
quiet=false, file=nil, indent=true
[bash]$ ruby ex06.rb test2 --indent=4         # `--indent=4` results in `4`
quiet=false, file=nil, indent="4"
```

Help message:

```ruby
[bash]$ ruby ex06.rb -h test1
ex06.rb test1 -- short options

Usage:
  $ ex06.rb test1 [<options>]

Options:
  -q                 : quiet mode
  -f <file>          : filename
  -i[<N>]            : indent width

[bash]$ ruby ex06.rb -h test2
ex06.rb test2 -- long options

Usage:
  $ ex06.rb test2 [<options>]

Options:
  --quiet            : quiet mode
  --file=<file>      : filename
  --indent[=<N>]     : indent width

[bash]$ ruby ex06.rb -h test3
ex06.rb test3 -- short and long options

Usage:
  $ ex06.rb test3 [<options>]

Options:
  -q, --quiet        : quiet mode
  -f, --file=<file>  : filename
  -i, --indent[=<N>] : indent width
```


Option Value Validation
-----------------------

`@option.()` can validate option value via keyword argument.

* `type: <class>` specifies option value class.
  Currently supports `Integer`, `Float`, `TrueClass`, and `Date`.
* `rexp: <rexp>` specifies regular expression of option value.
* `enum: <array>` specifies available values as option value.

File: ex07.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

## action
class MyAction < Benry::CmdApp::Action

  @action.("print greeting message")
  @option.(:lang  , "-l, --lang=<en|fr|it>", "language",
                  enum: ["en", "fr", "it"],         # !!!!
		  rexp: /\A\w\w\z/)                 # !!!!
  @option.(:repeat, "    --repeat=<N>", "repeat <N> times",
                  type: Integer)                    # !!!!
  def hello(user="world", lang: "en", repeat: 1)
    #p repeat.class   #=> Integer
    repeat.times do
      case lang
      when "en" ; puts "Hello, #{user}!"
      when "fr" ; puts "Bonjour, #{user}!"
      when "it" ; puts "Ciao, #{user}!"
      else
        raise "#{lang}: unknown language."
      end
    end
  end

end

## configuration
config = Benry::CmdApp::Config.new("sample app", "1.0.0")
config.default_help = true

## run application
app = Benry::CmdApp::Application.new(config)
status_code = app.main()
exit status_code
```

Output:

```console
[bash]$ ruby ex07.rb hello -l japan
[ERROR] -l japan: pattern unmatched.

[bash]$ ruby ex07.rb hello -l ja
[ERROR] -l ja: expected one of en/fr/it.

[bash]$ ruby ex07.rb hello --repeat=abc
[ERROR] --repeat=abc: integer expected.
```


Callback for Option Value
-------------------------

`@option.()` can take a block argument which is a callback for option value.
Callback can:

* Do custom validation of option value.
* Convert option value into other value.

File: ex08.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

## action
class MyAction < Benry::CmdApp::Action

  @action.("print greeting message")
  @option.(:lang  , "-l, --lang=<en|fr|it>", "language",
                  enum: ["en", "fr", "it", "EN", "FR", "IT"],
		  rexp: /\A\w\w\z/) {|v| v.downcase }    # !!!!
  @option.(:repeat, "    --repeat=<N>", "repeat <N> times",
                  type: Integer) {|v|                    # !!!!
		    v > 0 or raise "not positive value." # !!!!
                    v                                    # !!!!
                  }                                      # !!!!
  def hello(user="world", lang: "en", repeat: 1)
    repeat.times do
      case lang
      when "en" ; puts "Hello, #{user}!"
      when "fr" ; puts "Bonjour, #{user}!"
      when "it" ; puts "Ciao, #{user}!"
      else
        raise "#{lang}: unknown language."
      end
    end
  end

end

## configuration
config = Benry::CmdApp::Config.new("sample app", "1.0.0")
config.default_help = true

## run application
app = Benry::CmdApp::Application.new(config)
status_code = app.main()
exit status_code
```

Output:

```console
[bash]$ ruby ex08.rb hello -l FR
Bonjour, world!

[bash]$ ruby ex08.rb hello --repeat=0
[ERROR] --repeat=0: not positive value.
```


Boolean (On/Off) Option
-----------------------

Benry::CmdApp doesn't support `--[no-]foobar` style option.
Instead, define boolean (on/off) option.

* Specify `type: TrueClass` to `@option.()`.
* Option value `true`, `yes`, and `on` are converted into true.
* Option value `false`, `no`, and `off` are converted into false.

File: ex09.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

## action
class MyAction < Benry::CmdApp::Action

  @action.("print greeting message")
  @option.(:lang  , "-l, --lang=<en|fr|it>", "language",
                  enum: ["en", "fr", "it", "EN", "FR", "IT"],
		  rexp: /\A\w\w\z/)
  @option.(:repeat, "    --repeat=<N>", "repeat <N> times",
                  type: Integer)
  @option.(:upper,  "-U, --upper[=<on|off>]", "upper case",     # !!!!
                  type: TrueClass)                              # !!!!
  def hello(user="world", lang: "en", repeat: 1, upper: false)  # !!!!
    repeat.times do
      case lang
      when "en" ; s = "Hello, #{user}!"
      when "fr" ; s = "Bonjour, #{user}!"
      when "it" ; s = "Ciao, #{user}!"
      else
        raise "#{lang}: unknown language."
      end
      puts(upper ? s.upcase : s)               # !!!!
    end
  end

end

## configuration
config = Benry::CmdApp::Config.new("sample app", "1.0.0")
config.default_help = true

## run application
app = Benry::CmdApp::Application.new(config)
status_code = app.main()
exit status_code
```

Output:

```console
[bash]$ ruby ex09.rb --upper         # on
HELLO, WORLD!

[bash]$ ruby ex09.rb --upper=on      # on
HELLO, WORLD!

[bash]$ ruby ex09.rb --upper=off     # off
Hello, world!

[bash]$ ruby ex09.rb --upper=off     # off
Hello, world!

[bash]$ ruby ex09.rb --upper=abc     # error
[ERROR] --upper=abc: boolean expected.
```


Substitue Value Instead of True
-------------------------------

* `value:` keyword arg in `@option.()` specifies the substitute value
  instead of `true` when no option value specified in command-line.

File: ex10.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  ## when '-x' option specified in command-line, `true` will be
  ## passed to `flag` paramer. this is an ordinal behaviour.
  @action.("flag test #1")
  @option.(:flag, "-x", "ON/off")
  def flagtest1(flag: false)
    puts "flag=#{flag.inspect}"
  end

  ## when '-x' option specified in command-line, `false` will be
  ## passed to `flag` paramer due to `value: false`.
  @action.("flag test #2")
  @option.(:flag, "-x", "on/OFF", value: false)       # !!!!
  def flagtest2(flag: true)                           # !!!!
    puts "flag=#{flag.inspect}"
  end

end

config = Benry::CmdApp::Config.new("git helper")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex10.rb flagtest1          # false if '-x' NOT specified
flag=false

[bash]$ ruby ex10.rb flagtest1 -x       # true if '-x' specified
flag=true

[bash]$ ruby ex10.rb flagtest2          # true if '-x' NOT specified
flag=true

[bash]$ ruby ex10.rb flagtest2 -x       # false if '-x' specified
flag=false
```


Prefix of Action Name
---------------------

* `prefix: "foo:bar"` in action class adds prefix `foo:bar:` to each action name.
* Method name `def baz__test()` with `prefix: "foo:bar"` results in action name `foo:bar:baz:test`.

File: ex11.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action
  prefix "foo:bar"            # !!!!

  @action.("test action #1")
  def test1()                 # action name: 'foo:bar:test1'
    puts __method__
  end

  @action.("test action #2")
  def baz__test2()            # action name: 'foo:bar:baz:test2'
    puts __method__
  end

end

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex11.rb foo:bar:test1
test1

[bash]$ ruby ex11.rb foo:bar:baz:test2
baz__test2
```

Help message:

```console
[bash]$ ruby ex11.rb -h
ex11.rb -- sample app

Usage:
  $ ex11.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)

Actions:
  foo:bar:baz:test2  : test action #2
  foo:bar:test1      : test action #1
```

* `prefix: "foo:bar", default: :test` defines `foo:bar` action (intead of `foo:bar:test`) with `test()` method.

File: ex12.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action
  prefix "foo:bar", default: :test3_      # !!!!
  ## or:
  #prefix "foo:bar", default: "test3"     # !!!!

  @action.("test action #1")
  def test1()                 # action name: 'foo:bar:test1'
    puts __method__
  end

  @action.("test action #3")
  def test3_()                # action name: 'foo:bar'
    puts __method__
  end

end

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex12.rb foo:bar:test1
test1

[bash]$ ruby ex12.rb foo:bar:test3
[ERROR] foo:bar:test2: unknown action.

[bash]$ ruby ex12.rb foo:bar
test3_
```

Help message:

```console
[bash]$ ruby ex12.rb -h
ex12.rb -- sample app

Usage:
  $ ex12.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)

Actions:
  foo:bar            : test action #3
  foo:bar:test1      : test action #1
```


Invoke Other Action
-------------------

* `run_action!()` invokes other action.
* `run_action_once()` invokes other action only once.
  This is equivarent to 'prerequisite task' feature in task runner application.

File: ex13.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("create build dir")
  def prepare()
    puts "rm -rf build"
    puts "mkdir build"
  end

  @action.("build something")
  def build()
    run_action_once("prepare")        # !!!!
    run_action_once("prepare")        # skipped because already invoked
    puts "echo 'README' > build/README.txt"
    puts "zip -r build.zip build"
  end

end

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex13.rb build
rm -rf build                          # !!!!
mkdir build                           # !!!!
echo 'README' > build/README.txt
zip -r build.zip build
```

* When looped action is detected, Benry::CmdApp aborts action.

File: ex14.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class LoopedAction < Benry::CmdApp::Action

  @action.("test #1")
  def test1()
    run_action_once("test2")
  end

  @action.("test #2")
  def test2()
    run_action_once("test3")
  end

  @action.("test #3")
  def test3()
    run_action_once("test1")          # !!!!
  end

end

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex14.rb test1
[ERROR] test1: looped action detected.

[bash]$ ruby ex14.rb test3
[ERROR] test3: looped action detected.
```


Action Alias
------------

* Alias of action provides alternative short name of action.

File: ex15.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action
  prefix "foo:bar"

  @action.("test action #1")
  def test1()                 # action name: 'foo:bar:test1'
    puts __method__
  end

end

Benry::CmdApp.action_alias "test", "foo:bar:test1"   # !!!!

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex15.rb test
test1

[bash]$ ruby ex15.rb foo:bar:test1
test1
```

Help message:

```console
[bash]$ ruby ex15.rb -h
ex15.rb -- sample app

Usage:
  $ ex15.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)

Actions:
  foo:bar:test1      : test action #1
  test               : alias to 'foo:bar:test1' action
```


Default Action
--------------

* `config.default = "test1"` defines default action.
  In this case, action `test1` will be invoked if action name not specified in command-line.
* Default action name is shown in help message.

File: ex17.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  def test1()
    puts __method__
  end

end

config = Benry::CmdApp::Config.new("sample app")
config.default_action = "test1"     # !!!!
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex17.rb test1
test1

[bash]$ ruby ex17.rb               # !!!!
test1
```

Help message:

```console
[bash]$ ruby ex17.rb -h
ex17.rb -- sample app

Usage:
  $ ex17.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)

Actions: (default: test1)                   # !!!!
  test1              : test action #1
```


Default Help
------------

* `config.default_help = true` prints help message if action not specified in command-line.
* This is very useful when you don't have proper default action. It's recommended.
* `config.default_action` is prior than `config.default_help`.

File: ex18.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  def test1()
    puts __method__
  end

end

config = Benry::CmdApp::Config.new("sample app")
config.default_help = true     # !!!!
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex18.rb            # !!!!
ex18.rb -- sample app

Usage:
  $ ex18.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)

Actions:
  test1              : test action #1
```


Private (Hidden) Action
-----------------------

* If action method is private, Benry::CmdApp regards that action as private.
* Private actions are hidden in help message.
* Private actions are shown when `-a` or `--all` option enabled and specified.

File: ex20.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  def test1()
    puts __method__
  end

  @action.("test action #2")
  def test2()
    puts __method__
  end
  private :test2               # !!!! private method !!!!

  private                      # !!!! private method !!!!

  @action.("test action #3")
  def test3()
    puts __method__
  end

end

config = Benry::CmdApp::Config.new("sample app")
config.option_all = true       # !!!! enable '-a, --all' option !!!!
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message (without `-a` nor `--all`):

```console
[bash]$ ruby ex20.rb -h
ex20.rb -- sample app

Usage:
  $ ex20.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)
  -a, --all          : list all actions/options including private (hidden) ones

Actions:
  test1              : test action #1
```

Help message (with `-a` or `--all`):

```console
[bash]$ ruby ex20.rb -h --all      # !!!!
ex20.rb -- sample app

Usage:
  $ ex20.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)
  -a, --all          : list all actions/options including private (hidden) ones

Actions:
  test1              : test action #1
  test2              : test action #2          # !!!!
  test3              : test action #3          # !!!!
```


Private (Hidden) Option
-----------------------

* Options which name stars with `_` are treated as private option.
* Private options are hidden in help message of action.
* Private options are shown when `-a` or `--all` option enabled and specified.

File: ex21.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action")
  @option.(:verbose, "-v", "verbose mode")
  @option.(:_debug , "-D", "debug mode")      # !!!!
  def test1(verbose: false, _debug: false)
    puts "verbose=#{verbose}, _debug=#{_debug}"
  end

end

config = Benry::CmdApp::Config.new("sample app")
config.option_all = true       # !!!! enable '-a, --all' option !!!!
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message (without `-a` nor `--all`):

```console
[bash]$ ruby ex21.rb -h test1
ex21.rb test1 -- test action

Usage:
  $ ex21.rb test1 [<options>]

Options:
  -v                 : verbose mode
```

Help message (with `-a` or `--all`)

```console
[bash]$ ruby ex21.rb -h --all test1           # !!!!
ex21.rb test1 -- test action

Usage:
  $ ex21.rb test1 [<options>]

Options:
  -v                 : verbose mode
  -D                 : debug mode             # !!!!
```



Configuratoin and Customization
===============================


Application Configuration
-------------------------

`Benry::CmdApp::Config` class configures application behaviour.

* `config.app_desc = "..."` sets command description which is shown in help message. (required)
* `config.app_version = "1.0.0"` enables `-V` and `--version` option, and prints version number if `-V` or `--version` option specified. (default: `nil`)
* `config.app_command = "<command>"` sets command name which is shown in help message. (default: `File.basname($0)`)
* `config.app_detail = "<text>"` sets detailed description of command which is showin in help message. (default: `nil`)
* `config.default_action = "<action>"` sets default action name. (default: `nil`)
* `config.default_help = true` prints help message if no action names specified in command-line. (default: `false`)
* `config.option_help = true` enables `-h` and `--help` options. (default: `true`)
* `config.option_all = true` enables `-a` and `--all` options which shows private (hidden) actions and options into help message. (default: `false`)
* `config.option_verbose = true` enables `-v` and `--verbose` options which sets `$VERBOSE_MODE = true`. (default: `false`)
* `config.option_quiet = true` enables `-q` and `--quiet` options which sets `$QUIET_MODE = true`. (default: `false`)
* `config.option_color = true` enables `--color[=<on|off>]` option which sets `$COLOR_MODE = true/false`. This affects to help message colorized or not. (default: `false`)
* `config.option_debug = true` enables `-D` and `--debug` options which sets `$DEBUG_MODE = true`. (default: `false`)
* `config.option_trace = true` enables `-T` and `--trace` options which sets `$TRACE_MODE = true`. Entering into and exitting from action are reported when trace mode is on. (default: `false`)
* `config.help_sections = [["title", "<text>"], ...]` adds section title and text into help message. (default: `[]`)
* `config.help_postamble = "<text>"` sets postamble text in help message, such as 'Examples:' or 'Tips:'. (default: `nil`)
* `config.format_help = "  %-18s : %s"` sets format of options and actions in help message. (default: `"  \e[1m%-18s\e[0m : %s"`)
* `config.format_usage = "  $ %s %s"` sets format of usage in help message. (default: `"  $ \e[1m%s\e[0m %s"`)
* `config.format_heading = "[%s]"` sets format of heading in help message. (default: `"\e[34m%s\e[0m"`)

File: ex22.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

config = Benry::CmdApp::Config.new("sample app", "1.0.0")
#config.default_help = true

config.class.instance_methods(false).each do |name|
  next if name =~ /=$/
  next if ! config.class.method_defined?("#{name}=")
  val = config.__send__(name)
  puts "%-25s = %s" % ["config.#{name}", val.inspect]
end
```

Output:

```console
[bash]$ ruby ex22.rb
config.app_desc           = "sample app"
config.app_version        = "1.0.0"
config.app_name           = "ex22.rb"
config.app_command        = "ex22.rb"
config.app_detail         = nil
config.default_action     = nil
config.default_help       = false
config.option_help        = true
config.option_all         = false
config.option_debug       = false
config.option_verbose     = false
config.option_quiet       = false
config.option_color       = false
config.option_trace       = false
config.help_sections      = []
config.help_postamble     = nil
config.format_help        = "  \e[1m%-18s\e[0m : %s"
config.format_usage       = "  $ \e[1m%s\e[0m %s"
config.format_heading     = "\e[34m%s\e[0m"
```


Custom Global Options
---------------------

* (1) Create global option schema object.
* (2) Add custom options to it.
* (3) Pass it to `Application.new()`.

File: ex23.rb

```ruby
#!/usr/bin/env ruby
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

## (3) pass it to `Application.new()`
app = Benry::CmdApp::Application.new(config, schema)   # !!!!

exit app.main()
```

Help message:

```console
[bash]$ ruby ex23.rb -h
ex23.rb -- sample app

Usage:
  $ ex23.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)
  --logging          : enable logging          # !!!!

Actions:
  test1              : test action
```


Custom Hook of Application
--------------------------

* (1) Define subclass of Application class.
* (2) Override callback method.
* (3) Create and execute custom application object.

File: ex24.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action")
  def test1()
    $logger.info("logging message") if $logger
  end

end

## (1) Define subclass of Application class
class MyApplication < Benry::CmdApp::Application   # !!!!

  ## (2) Override callback method
  def do_callback(args, global_opts)               # !!!!
    #p @config
    #p @schema
    if global_opts[:logging]
      require 'logger'
      $logger = Logger.new(STDOUT)
    end
    ## if return :SKIP, action skipped (not invoked).
    #return :SKIP
  end

  ## or:
  #def do_handle_global_options(args, global_opts)
  #  if global_opts[:logging]
  #    require 'logger'
  #    $logger = Logger.new(STDOUT)
  #  end
  #  super
  #end

end

## (3) create and execute custom application object
config = Benry::CmdApp::Config.new("sample app")
schema = Benry::CmdApp::GlobalOptionSchema.new(config)
schema.add(:logging, "--logging", "enable logging")
app = MyApplication.new(config, schema)             # !!!!
exit app.main()
```

* [EXPERIMENTAL] Instead of defining subclass of Application, you can pass callback block to Application object.

File: ex25.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action")
  def test1()
    $logger.info("logging message") if $logger
  end

end

config = Benry::CmdApp::Config.new("sample app")
schema = Benry::CmdApp::GlobalOptionSchema.new(config)
schema.add(:logging, "--logging", "enable logging")
app = MyApplication.new(config, schema) do   # !!!!
  |args, global_opts, config|                # !!!!
  if global_opts[:logging]                   # !!!!
    require 'logger'                         # !!!!
    $logger = Logger.new(STDOUT)             # !!!!
  end                                        # !!!!
  #:SKIP                                     # !!!!
end                                          # !!!!
exit app.main()
```


Customization of Command Help Message
-------------------------------------

If you want to just add more text into command help message,
set `config.app_detail`, `config.help_sections`, and/or `config.help_postamble`.

File: ex26.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

config = Benry::CmdApp::Config.new("sample app")
config.app_detail = "Document: https://...."      # !!!!
config.help_sections = [                          # !!!!
  ["Example:", "  $ <command> hello Alice"],      # !!!!
]                                                 # !!!!
config.help_postamble = "(Tips: ....)"            # !!!!
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message:

```console
[bash]$ ruby ex26.rb -h
ex26.rb -- sample app

Document: https://....                      # !!!!

Usage:
  $ ex26.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)

Actions:
  hello              : test action #1

Example:                                    # !!!!
  $ <command> hello Alice                   # !!!!

(Tips: ....)                                # !!!!
```

If you want to change behaviour of building command help message:

* (1) Define subclass of `Benry::CmdApp::CommandHelpBuilder` class.
* (2) Override methods.
* (3) Create an instance object of the class.
* (4) Pass it to Application object.

File: ex27.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("greeting message")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

## (1) Define subclass of `Benry::CmdApp::CommandHelpBuilder` class.
class MyCommandHelpBuilder < Benry::CmdApp::CommandHelpBuilder

  ## (2) Override methods.
  def build_help_message(all=false, format=nil)
    super
  end
  def build_preamble(all=false)
    super
  end
  def build_usage(all=false)
    super
  end
  def build_options(all=false, format=nil)
    super
  end
  def build_actions(all=false, format=nil)
    super
  end
  def build_postamble(all=false)
    super
  end
  def heading(str)
    super
  end
end

## (3) Create an instance object of the class.
config = Benry::CmdApp::Config.new("sample app")
schema = Benry::CmdApp::GlobalOptionSchema.new(config)
schema.add(:logging, "--logging", "enable logging")
help_builder = MyCommandHelpBuilder.new(config, schema)     # !!!!

## (4) Pass it to Application object.
app = Benry::CmdApp::Application.new(config, schema, help_builder) # !!!!
exit app.main()
```

More simple way:

* (1) Create a module and override methods of `Benry::CmdApp::CommandHelpBuilder` class.
* (2) Prepend it to `Benry::CmdApp::CommandHelpBuilder` class.
* (3) Create and execute Application object.

File: ex28.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("greeting message")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

## (1) Create a module and override methods of `CommandHelpBuilder` class.
module MyCommandHelpBuilder
  def build_help_message(all=false, format=nil)
    super
  end
  def build_preamble(all=false)
    super
  end
  def build_usage(all=false)
    super
  end
  def build_options(all=false, format=nil)
    super
  end
  def build_actions(all=false, format=nil)
    super
  end
  def build_postamble(all=false)
    super
  end
  def heading(str)
    super
  end
end

## (2) Prepend it to `Benry::CmdApp::CommandHelpBuilder` class.
Benry::CmdApp::CommandHelpBuilder.prepend(MyCommandHelpBuilder)

## (3) Create and execute Application object.
config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```


Customization of Action Help Message
-------------------------------------

If you want to just add more text into action help message,
pass `detail:` and/or `postamble:` keyword arguments to `@action.()`.

File: ex29.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1",
           detail: "Document: https://....",      # !!!!
           postamble: "(Tips: ....)")             # !!!!
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message:

```console
[bash]$ ruby ex29.rb -h
ex29.rb hello -- test action #1

Document: https://....                  # !!!!

Usage:
  $ ex29.rb hello [<user>]

(Tips: ....)                            # !!!!
```

If you want to change behaviour of building action help message:

* (1) Create a module and override methods of `Benry::CmdApp::ActionHelpBuilder` class.
* (2) Prepend it to `Benry::CmdApp::ActionHelpBuilder` class.
* (3) Create and execute Application object.

File: ex30.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("greeting message")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

## (1) Create a module and override methods of `ActionHelpBuilder` class.
module MyActionHelpBuilder
  def build_help_message(command, all=false)
    super
  end
  def build_preamble(command, all=false)
    super
  end
  def build_usage(command, all=false)
    super
  end
  def build_options(command, all=false)
    super
  end
  def build_postamble(command, all=false)
    super
  end
  def heading(str)
    super
  end
end

## (2) Prepend it to `Benry::CmdApp::ActionHelpBuilder` class.
Benry::CmdApp::ActionHelpBuilder.prepend(MyActionHelpBuilder)

## (3) Create and execute Application object.
config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```


Changing Behaviour of Global Options
------------------------------------

To change behaviour of global options (such as `-v/--verbose`,
`-q/--quiet`, `-D/--debug`, `-T/--trace`, and `--color`), override
`#do_toggle_global_switches()` of `Benry::CmdApp::Application` class.

File: ex31.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

class MyApplication < Benry::CmdApp::Application

  def do_toggle_global_switches(_args, global_opts)
    ## here is original code
    #global_opts.each do |key, val|
    #  case key
    #  when :quiet   ; $QUIET_MODE   = val
    #  when :verbose ; $VERBOSE_MODE = val
    #  when :color   ; $COLOR_MODE   = val
    #  when :debug   ; $DEBUG_MODE   = val
    #  when :trace   ; $TRACE_MODE   = val
    #  else          ; # do nothing
    #  end
    #end
  end

end

config = Benry::CmdApp::Config.new("sample app")
app = MyApplication.new(config)            # !!!!
exit app.main()
```

Of course, prepending custom module to Application class is also effective way.

File: ex32.rb

```ruby
#!/usr/bin/env ruby
require 'benry/cmdapp'

module MyApplicationMod

  def do_toggle_global_switches(_args, global_opts)
    # ....
  end

end

Benry::CmdApp::Application.prepend(MyApplicationMod)   # !!!!

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```


Q & A
=====


Q: How to Append Some Tasks to Existing Action?
-----------------------------------------------

A: (a) Use method alias, or (b) use prepend.

File: ex41.rb

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
  alias __old_hello hello        # alias of existing method
  def hello(user="world")        # override existing method
    puts "---- >8 ---- >8 ----"
    __old_hello(user)            # call original method
    puts "---- 8< ---- 8< ----"
  end
end

## (b) use prepend
module SampleMod                 # define new module
  def hi(user="world")           # override existing method
    puts "==== >8 ==== >8 ===="
    super                        # call original method
    puts "==== 8< ==== 8< ===="
  end
end
SampleAction.prepend(SampleMod)  # prepend it to existing class

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex41.rb hello
---- >8 ---- >8 ----
Hello, world!
---- 8< ---- 8< ----

[bash]$ ruby ex41.rb hi Alice
==== >8 ==== >8 ====
Hi, Alice!
==== 8< ==== 8< ====
```


Q: How to Show Entering Into or Exitting From Action?
-----------------------------------------------------

A: Set `config.option_trace = true` and pass `-T` (or `--trace`) option.

File: ex42.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("preparation")
  def prepare()
    puts "... prepare something ..."
  end

  @action.("build")
  def build()
    run_action_once("prepare")
    puts "... build something ..."
  end

end

config = Benry::CmdApp::Config.new("sample app")
config.option_trace = true                          # !!!!
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Output:

```console
[bash]$ ruby ex42.rb -T build           # !!!!
## enter: build
## enter: prepare
... prepare something ...
## exit:  prepare
... build something ...
## exit:  build
```


Q: How to Enable/Disable Color Mode?
------------------------------------

A: Set `config.option_color = true` and pass `--color=on` or `--color=off` option.

File: ex43.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("greeting message")
  def hello(user="world")
    puts "Hello, #{user}!"
  end

end

config = Benry::CmdApp::Config.new("sample app")
config.option_color = true                       # !!!!
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message:

```console
[bash]$ ruby ex43.rb -h
ex43.rb -- sample app

Usage:
  $ ex43.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)
  --color[=<on|off>] : enable/disable color      # !!!!

Actions:
  hello              : greeting message

[bash]$ ruby ex43.rb -h --color=off              # !!!!

[bash]$ ruby ex43.rb -h --color=on               # !!!!
```


Q: How to Copy All Options from Other Action?
---------------------------------------------

A: Use `@copy_options.()`.

File: ex44.rb

```ruby
require 'benry/cmdapp'

class SampleAction < Benry::CmdApp::Action

  @action.("test action #1")
  @option.(:verbose, "-v, --verbose", "verbose mode")
  @option.(:file, "-f, --file=<file>", "filename")
  @option.(:indent, "-i, --indent[=<N>]", "indent")
  def test1(verbose: false, file: nil, indent: nil)
    puts "verbose=#{verbose}, file=#{file}, indent=#{indent}"
  end

  @action.("test action #2")
  @copy_options.("test1")         # !!!! copy options from test1 !!!!
  @option.(:debug, "-D, --debug", "debug mode")
  def test2(verbose: false, file: nil, indent: nil, debug: false)
    puts "verbose=#{verbose}, file=#{file}, indent=#{indent}, debug=#{debug}"
  end

end

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message of `test2` action:

```console
[bash]$ ruby ex44.rb -h test2
ex44.rb test2 -- test action #2

Usage:
  $ ex44.rb test2 [<options>]

Options:
  -v, --verbose      : verbose mode     # copied!!
  -f, --file=<file>  : filename         # copied!!
  -i, --indent[=<N>] : indent           # copied!!
  -D, --debug        : debug mode
```


Q: What is the Difference Between `prefix(alias_of:)` and `prefix(default:)`?
-----------------------------------------------------------------------------

A: The former defines an alias, and the latter doesn't.

File: ex45.rb

```ruby
require 'benry/cmdapp'

class AaaAction < Benry::CmdApp::Action
  prefix "aaa", alias_of: :print_        # (or) alias_of: "print"

  @action.("test #1")
  def print_()
    puts "test"
  end

end

class BbbAction < Benry::CmdApp::Action
  prefix "bbb", default: :print_         # (or) default: "print"

  @action.("test #2")
  def print_()
    puts "test"
  end

end

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```

Help message:

```console
[bash]$ ruby ex45.rb
ex45.rb -- sample app

Usage:
  $ ex45.rb [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)

Actions:
  aaa                : alias of 'aaa:print' action    # !!!!
  aaa:print          : test #1
  bbb                : test #2                        # !!!!
```

In the above example, alias `aaa` is defined due to `prefix(alias_of:)`,
and action `bbb` is not an alias due to `prefix(default:)`.


Q: Is It Possible to Add Add Metadata to Action or Option?
----------------------------------------------------------

A: Yes. Pass `tag:` keyword argument to `@action.()` or `@option.()`.

* `tag:` keyword argument accept any type of value such as symbol, string, array, and so on.
* Currenty, Benry::CmdApp doesn't provide the good way to use it effectively.
  This feature is supported for command-line application or framework based on Benry::CmdApp.

File: ex46.rb

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

config = Benry::CmdApp::Config.new("sample app")
app = Benry::CmdApp::Application.new(config)
exit app.main()
```



License and Copyright
=====================

$License: MIT License $

$Copyright: copyright(c) 2023 kuwata-lab.com all rights reserved $
