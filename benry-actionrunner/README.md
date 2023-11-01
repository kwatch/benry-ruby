# Benry-ActionRunner

($Release: 0.0.0 $)


## What's this?

Benry-ActionRunner is a task runner.
Similar to Rake, but much improved over Rake.

The main feature of Benry-ActionRunner compared to Rake is that each actions can take options and arguments.
For example, `arun hello -l fr Alice` runs `hello` action with an option `-l fr` and an argument `Alice`.

* Document: <https://kwatch.github.io/benry-ruby/benry-actionrunner.html>
* GitHub: <https://github.com/kwatch/benry-ruby/tree/main/benry-actionrunner>
* Changes: <https://github.com/kwatch/benry-ruby/blob/main/benry-actionrunner/CHANGES.md>

(Benry-ActionRunner requires Ruby >= 2.3)



### Table of Contents

<!-- TOC -->

* [What's this?](#whats-this)
* [Install](#install)
* [Example](#example)
* [Basic Features](#basic-features)
  * [Action](#action)
  * [Arguments](#arguments)
  * [Options](#options)
  * [Validation for Option Value](#validation-for-option-value)
  * [Boolean Option](#boolean-option)
  * [Prefix of Actions](#prefix-of-actions)
  * [Nested Prefix](#nested-prefix)
  * [Alias of Action](#alias-of-action)
  * [Prefix Action and Prefix Alias](#prefix-action-and-prefix-alias)
  * [Prerequisite Action](#prerequisite-action)
  * [Other Topics](#other-topics)
  * [Available Commands](#available-commands)
* [Advanced Features](#advanced-features)
* [License and Copyright](#license-and-copyright)

<!-- /TOC -->



## Install

```console
$ gem install benry-actionrunner
$ arun --version
1.0.0
```


## Example

```console
[bash]$ arun -h | less          # print help message
[bash]$ arun -g                 # generate action file ('Actionfile.rb')
[bash]$ less Actionfile.rb      # read content of action file
[bash]$ arun                    # list actions (or: `arun -l`)
[bash]$ arun -h hello           # show help message of 'hello' action
[bash]$ arun hello Alice        # run 'hello' action with arguments
Hello, Alice!
[bash]$ arun hello Alice -l fr  # run 'hello' action with args and options
Bonjour, Alice!
[bash]$ arun xxxx:              # list actions starting with 'xxxx:'
[bash]$ arun :                  # list prefixes of actions (or '::', ':::')
```


## Basic Features


### Action

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class MyAction < Action

  @action.("print greeting message")
  def hello()
    puts "Hello, world!"
  end

end
```

Output:

```console
[bash]$ ls Actionfile.rb
Actionfile.rb

[bash]$ arun hello
Hello, world!
```

It is not allowed to override existing method by action method.
For example, you can't define `print()` or `test()` method as action method
because these methods are defined in parent or ancestor class.
In this case, please rename action methods to `print_()` or `test_()`.
These action methods are treated as action name `print` or `test`.


### Arguments

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class MyAction < Action

  @action.("print greeting message")
  def hello(name="world")
    puts "Hello, #{name}!"
  end

end
```

Output:

```console
[bash]$ arun hello Alice
Hello, Alice!
```

Arguments are displayed in help message of actions.

```console
[bash]$ arun -h hello
arun hello --- print greeting message

Usage:
  $ arun hello [<options>] [<name>]
```


### Options

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class MyAction < Action

  @action.("print greeting message")
  @option.(:lang, "-l, --lang=<lang>", "language (en/fr/it)")
  @option.(:repeat, "-n <N>", "repeat N times")
  def hello(name="world", lang: "en", repeat: 1)
    repeat.times do
      case lang
      when "en" ; puts "Hello, #{name}!"
      when "fr" ; puts "Bonjour, #{name}!"
      when "it" ; puts "Chao, #{name}!"
      else      ; raise "#{lang}: Unknown language."
      end
    end
  end

end
```

Output:

```console
[bash]$ arun hello -l fr Alice        # or: arun hello Alice -l fr
Bonjour, Alice!

[bash]$ arun hello --lang=it Alice    # or: arun hello Alice --lang=it
Chao, Alice!
```

Available option formats:

* No arguments
  * `-h` --- short
  * `--help`  --- long
  * `-h, --help` --- both
* Argument required
  * `-f <file>`  --- short
  * `--file=<file>`  --- long
  * `-f, --file=<file>`  --- both
* Optional argument
  * `-i[<width>]` --- short
  * `--indent[=<width>]` --- long
  * `-i, --indent[=<width>]` --- both

Notice: `--lang it` style option is not supported for usability reason.
Use `--lang=it` style instead.


### Validation for Option Value

Keyword arguments of `@option.()`:

* `type: Integer` --- Option value should be an integer.
* `rexp: /^\d+$/   --- Option value should match to pattern.
* `enum: ["A", "B", "C"]` --- Option value should be one of "A", "B", or "C".
* `range: 1..10    --- Option value should be between 1 and 10.

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class MyAction < Action

  @action.("print greeting message")
  @option.(:lang, "-l, --lang=<lang>", "language", enum: ["en", "fr", "it"])
  @option.(:repeat, "-n <N>", "repeat N times", type: Integer, range: 1..5)
  def hello(name="world", lang: "en", repeat: 1)
    repeat.times do
      case lang
      when "en" ; puts "Hello, #{name}!"
      when "fr" ; puts "Bonjour, #{name}!"
      when "it" ; puts "Chao, #{name}!"
      else      ; raise "#{lang}: Unknown language."
      end
    end
  end

end
```

Output:

```console
[bash]$ arun hello -l po Alice
[ERROR] -l po: Expected one of en/fr/it.

[bash]$ arun hello -n 99 Alice
[ERROR] -n 99: Too large (max: 5)
```


### Boolean Option

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class MyAction < Action

  @action.("print greeting message")
  @option.(:lang, "-l, --lang=<lang>", "language", enum: ["en", "fr", "it"])
  @option.(:repeat, "-n <N>", "repeat N times", type: Integer, range: 1..5)
  @option.(:color, "-c, --color[=<on|off>]", "color mode", type: TrueClass)
  def hello(name="world", lang: "en", repeat: 1, color: false)
    if color
      name = "\e[32m#{name}\e[0m"
    end
    repeat.times do
      case lang
      when "en" ; puts "Hello, #{name}!"
      when "fr" ; puts "Bonjour, #{name}!"
      when "it" ; puts "Chao, #{name}!"
      else      ; raise "#{lang}: Unknown language."
      end
    end
  end

end
```

Output:

```console
[bash]$ arun hello --color=on Alice
Hello, Alice!                          # displayed with color

[bash]$ arun hello --color Alice
Hello, Alice!                          # displayed with color
```


### Prefix of Actions

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class GitAction < Action
  prefix "git:"     # should be "git:", not "git" !!!

  @action.("show current status in compact format")
  def status(path=".")
    sys "git status -sb #{path}"     # `sys` is like `system` or `sh`.
  end

end

### or:
#class GitAction < Action
#  @action.("show current status in compact format")
#  def git__status(path=".")
#    sys "git status -sb #{path}"
#  end
#end
```

Output:

```console
[bash]$ arun -l
Actions:
  git:status         : show current status in compact format
  help               : print help message (of action if specified)

[bash]$ arun git:status
$ git status -sb .
```


### Nested Prefix

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class GitAction < Action

  prefix "git:" do

    prefix "commit:" do

      @action.("create a commit of current changes")
      def create(msg); sys "git commit -m '#{msg}'"; end

    end

    prefix "branch:" do

      @action.("create a new branch")
      def create(name); sys "git checkout -b #{name}" ; end

      @action.("switch current branch")
      def switch(name); sys "git checkout #{name}"; end

    end

  end

end
```

Output:

```console
[bash]$ arun -l
Actions:
  git:branch:create  : create a new branch
  git:branch:switch  : switch current branch
  git:commit:create  : create a commit of current changes
  help               : print help message (of action if specified)
```


### Alias of Action

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class GitAction < Action

  prefix "git:" do

    prefix "commit:" do

      @action.("create a commit of current changes")
      def create(msg); sys "git commit -m '#{msg}'"; end

    end

    prefix "branch:" do

      @action.("create a new branch")
      def create(name); sys "git checkout -b #{name}" ; end

      @action.("switch current branch")
      def switch(name); sys "git checkout #{name}"; end

    end

  end

end

define_alias "ci"   , "git:commit:create"
define_alias "fork" , "git:branch:create"
define_alias "sw"   , "git:branch:switch"
```

Output:

```console
[bash]$ arun -l
Actions:
  ci                 : alias of 'git:commit:create'
  fork               : alias of 'git:branch:create'
  git:branch:create  : create a new branch
  git:branch:switch  : switch current branch
  git:commit:create  : create a commit of current changes
  help               : print help message (of action if specified)
  sw                 : alias of 'git:branch:switch'

[bash]$ arun fork topic-foo      # same as `arun git:branch:create topic-foo`
[bash]$ arun sw topic-foo        # same as `arun git:branch:switch topic-foo`
```


### Prefix Action and Prefix Alias

Rename `git:status` action to `git` (= prefix name):

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class GitAction < Action
  prefix "git:", action: "status"

  @action.("show current status in compact format")
  def status(path=".")
    sys "git status -sb #{path}"     # `sys` is like `system` or `sh`.
  end

end
```

Output: (`git:status` is renamed to `git`)

```console
[bash]$ arun -l
Actions:
  git                : show current status in compact format
  help               : print help message (of action if specified)
```

Define an alias of `git:status` task as `git` (= prefix name):

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class GitAction < Action
  prefix "git:", alias_of: "status"

  @action.("show current status in compact format")
  def status(path=".")
    sys "git status -sb #{path}"     # `sys` is like `system` or `sh`.
  end

end
```

Output: (`git` is an alias of `git:status`)

```console
[bash]$ arun -l
Actions:
  git                : alias of 'git:status'
  git:status         : show current status in compact format
  help               : print help message (of action if specified)
```


### Prerequisite Action

Prerequisite Action is not supported.
Instead, use `run_once()` which invokes other action only once.

File: Actionfile.rb

```ruby
# coding: utf-8
require 'benry/actionrunner'
include Benry::ActionRunner

class BuildAction < Action

  @action.("setup something")
  def setup()
    puts ".... setup ...."
    ## register teardown block which will be invoked at end of process.
    at_end {
      puts ".... teardown ...."
    }
  end

  @action.("build something")
  def build()
    run_once "setup"        # invoke other action only once
    run_once "setup"        # !!! not invoked !!!
    #run_action "setup"     # run anyway
    puts ".... build ...."
  end

end
```

Output:

```console
[bash]$ arun build
.... setup ....
.... build ....
.... teardown ....
```



### Other Topics


### Available Commands

In action methods, UNIX-like commands are available.
These commands are implemented in [Benry-UnixCommand](https://kwatch.github.io/benry-ruby/benry-unixcommand.html) and different from FileUtils.rb.
For example:

* `mv "*.txt", to: "dir"` instead of `mv Dir["*.txt"], "dir"`.
* `cp :p, "*.txt", to: "dir"` instead of `cp_p Dir["*.txt"], "dir"`.
* `rm :rf, "dir/*"` instead of `rm_rf Dir["dir/*"]`.
* `mkdir :p, "dir"` instead of `mkdir_p "dir"`.
* `sys "command"` instead of `sh "command"` or `system "command"`.

See the document of Benry-UnixCommand for details:
 <https://kwatch.github.io/benry-ruby/benry-unixcommand.html>


#### Search Actionfile in Parent or Higher Directory

In contrast to Rake, Benry-ActionRunner doesn't automatically look for action file in the parent or higher directory (this is for security reason).
If you want Benry-ActionRunner to behave like Rake, add `-u` and `-p` options.

* `-u` --- search for action file in parent or upper directory.
* `-p` --- change current directory to where action file exists.

If you want to add these options always, set environment variable `$ACTIONRUNNER_OPTION`.

```console
[bash]$ ls Actionfile.rb
Actionfile.rb

[bash]$ mkdir -p foo/bar/
[bash]$ cd foo/bar/           # Change current directory.
[bash]$ arun -l               # Error because action file not found here.
[ERROR] Action file ('Actionfile.rb') not found. Create it by `arun -g` command firstly.

[bash]$ arun -l -up           # Search 'Actionfile.rb' and change current directory.
Actions:
  hello              : print greeting message
  help               : print help message (of action if specified)

[bash]$ export ACTIONRUNNER_OPTION="-up"
[bash]$ arun -l               # No need to add `-up`.
$ cd ../..
Actions:
  build              : build something
  help               : print help message (of action if specified)
  setup              : setup something
```


#### Hidden Action or Option

```ruby
  @action.("preparation", hidden: true)
  @option.(:debug, "--debug", "enable debug mode", hidden: true)
  def preparation()
    ....
  end
```

Hidden actions and options are not displayed in help message.
If you want to display hidden actions or options, add `-a` or `--all` option.

```console
[bash]$ arun -la          # show all actions including hidden ones
[bash]$ arun -la hello    # show all options of action including hidden ones
```


#### Delete Action/Alias

```ruby
undef_alias("fork")                    ## delete an alias
undef_action("git:branch:create")      ## delete an action
```


#### Default Action

```ruby
CONFIG.default_action = "xxxx"
```



## Advanced Features

Benry-ActionRunner is empowerd by Benry-CmdApp.
Many features of Benry-ActionRunner is derived from Benry-CmdApp.

If you are looking for any features not written in this document,
see the document of Benry-CmdApp framework:
 <https://kwatch.github.io/benry-ruby/benry-cmdapp.html>



## License and Copyright

$License: MIT License $

$Copyright: copyright(c) 2023 kwatch@gmail.com $
