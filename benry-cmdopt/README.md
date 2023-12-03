# Benry-CmdOpt

($Release: 0.0.0 $)



## What's This?

Benry-CmdOpt is a command option parser library, like `optparse.rb`
(Ruby standard library).

Compared to `optparse.rb`, Benry-CmdOpt is easy to use, easy to extend,
and easy to understahnd.

* Document: <https://kwatch.github.io/benry-ruby/benry-cmdopt.html>
* GitHub: <https://github.com/kwatch/benry-ruby/tree/main/benry-cmdopt>
* Changes: <https://github.com/kwatch/benry-ruby/tree/main/benry-cmdopt/CHANGES.md>

Benry-CmdOpt requires Ruby >= 2.3.



### Table of Contents

<!-- TOC -->

* [What's This?](#whats-this)
* [Why not `optparse.rb`?](#why-not-optparserb)
* [Install](#install)
* [Usage](#usage)
  * [Define, Parse, and Print Help](#define-parse-and-print-help)
  * [Command Option Parameter](#command-option-parameter)
  * [Argument Validation](#argument-validation)
  * [Boolean (on/off) Option](#boolean-onoff-option)
  * [Alternative Value](#alternative-value)
  * [Multiple Value Option](#multiple-value-option)
  * [Hidden Option](#hidden-option)
  * [Global Options with Sub-Commands](#global-options-with-sub-commands)
  * [Detailed Description of Option](#detailed-description-of-option)
  * [Option Tag](#option-tag)
  * [Important Options](#important-options)
  * [Not Supported](#not-supported)
* [Internal Classes](#internal-classes)
* [License and Copyright](#license-and-copyright)

<!-- /TOC -->



## Why not `optparse.rb`?

* `optparse.rb` can handle both `--name=val` and `--name val` styles.
  The later style is ambiguous; you may wonder whether `--name` takes
  `val` as argument or `--name` takes no argument (and `val` is command
  argument).

  Therefore the `--name=val` style is better than the `--name val` style.

  `optparse.rb` cannot disable `--name val` style.
  `benry/cmdopt.rb` supports only `--name=val` style.

* `optparse.rb` regards `-x` and `--x` as a short cut of `--xxx` automatically
  even if you have not defined `-x` option.
  That is, short options which are not defined can be available unexpectedly.
  This feature is hard-coded in `OptionParser#parse_in_order()`
  and hard to be disabled.

  In contact, `benry/cmdopt.rb` doesn't behave this way.
  `-x` option is available only when `-x` is defined.
  `benry/cmdopt.rb` does nothing superfluous.

* `optparse.rb` uses long option name as hash key automatically, but
  it doesn't provide the way to specify hash key for short-only option.

  `benry/cmdopt.rb` can specify hash key for short-only option.

```ruby
### optparse.rb
require 'optparse'
parser = OptionParser.new
parser.on('-v', '--verbose', "verbose mode") # short and long option
parser.on('-q',              "quiet mode")   # short-only option
#
opts = {}
parser.parse!(['-v'], into: opts) # short option
p opts  #=> {:verbose=>true}      # hash key is long option name
#
opts = {}
parser.parse!(['-q'], into: opts) # short option
p opts  #=> {:q=>true}            # hash key is short option name

### benry/cmdopt.rb
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new
cmdopt.add(:verbose, '-v, --verbose', "verbose mode") # short and long
cmdopt.add(:quiet  , '-q'           , "quiet mode")   # short-only
#
opts = cmdopt.parse(['-v'])   # short option
p opts  #=> {:verbose=>true}  # independent hash key of option name
#
opts = cmdopt.parse(['-q'])   # short option
p opts  #=> {:quiet=>true}    # independent hash key of option name
```

* `optparse.rb` provides severay ways to validate option values, such as
  type class, Regexp as pattern, or Array/Set as enum. But it doesn't
  accept Range object. This means that, for examle, it is not simple to
  validate whether integer or float value is positive or not.

  In contract, `benry/cmdopt.rb` accepts Range object so it is very simple
  to validate whether integer or float value is positive or not.

```ruby
### optparse.rb
parser = OptionParser.new
parser.on('-n <N>', "number", Integer, (1..))  #=> NoMethodError

### benry/cmdopt.rb
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new
cmdopt.add(:number, "-n <N>", "number", type: Integer, range: (1..)) #=> ok
```

* `optparse.rb` accepts Array or Set object as enum values. But values
  of enum should be a String in spite that type class specified.
  This seems very strange and not intuitive.

  `benry/cmdopt.rb` accepts integer values as enum when type class is Integer.

```ruby
### optparse.rb
parser = OptionParser.new
parser.on('-n <N>', "number", Integer, [1, 2, 3])      # wrong
parser.on('-n <N>', "number", Integer, ['1','2','3'])  # ok (but not intuitive)

### benry/cmdopt.rb
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new
cmdopt.add(:number, "-n <N>", "number", type: Integer, enum: [1, 2, 3]) # very intuitive
```

* `optparse.rb` doesn't report error even when options are duplicated.
  This specification makes debugging hard.

  `benry/cmdopt.rb` reports error when options are duplicated.

```ruby
require 'optparse'

options = {}
parser = OptionParser.new
parser.on('-v', '--version') { options[:version] = true }
parser.on('-v', '--verbose') { options[:verbose] = true }  # !!!!
argv = ["-v"]
parser.parse!(argv)
p options     #=> {:verbose=>true}, not {:version=>true}
```

* `optparse.rb` adds `-h` and `--help` options automatically, and
  terminates current process when `-h` or `--help` specified in command-line.
  It is hard to remove these options.

  In contract, `benry/cmdopt.rb` does not add these options.
  `benry/cmdopt.rb` does nothing superfluous.

```ruby
require 'optparse'
parser = OptionParser.new
## it is able to overwrite '-h' and/or '--help',
## but how to remove or disable these options?
opts = {}
parser.on('-h <host>', "hostname") {|v| opts[:host] = v }
parser.parse(['--help'])  # <== terminates current process!!
puts 'xxx'   #<== not printed because current process alreay terminated
```

* `optparse.rb` adds `-v` and `--version` options automatically, and
  terminates current process when `-v` or `--version` specified in terminal.
  It is hard to remove these options.
  This behaviour is not desirable because `optparse.rb` is just a library,
  not framework.

  In contract, `benry/cmdopt.rb` does not add these options.
  `benry/cmdopt.rb` does nothing superfluous.

```ruby
require 'optparse'
parser = OptionParser.new
## it is able to overwrite '-v' and/or '--version',
## but how to remove or disable these options?
opts = {}
parser.on('-v', "verbose mode") { opts[:verbose] = true }
parser.parse(['--version'])  # <== terminates current process!!
puts 'xxx'   #<== not printed because current process alreay terminated
```

* `optparse.rb` generates help message automatically, but it doesn't
  contain `-h`, `--help`, `-v`, nor `--version`.
  These options are available but not shown in help message. Strange.

* `optparse.rb` generate help message which contains command usage string
  such as `Usage: <command> [options]`. `optparse.rb` should NOT include
  it in help message because it is just a library, not framework.
  If you want to change '[options]' to '[<options>]', you must manipulate
  help message string by yourself.

  `benry/cmdopt.rb` doesn't include extra text (such as usage text) into
  help message. `benry/cmdopt.rb` does nothing superfluous.

* `optparse.rb` generates help message with too wide option name
  by default. You must specify proper width.

  `benry/cmdopt.rb` calculates proper width automatically.
  You don't need to specify proper width in many case.

```ruby
### optparse.rb
require 'optparse'
banner = "Usage: blabla <options>"
parser = OptionParser.new(banner)  # or: OptionParser.new(banner, 25)
parser.on('-f', '--file=<FILE>', "filename")
parser.on('-m <MODE>'          , "verbose/quiet")
puts parser.help
### output
# Usage: blabla <options>
#     -f, --file=<FILE>                filename
#     -m <MODE>                        verbose/quiet

### benry/cmdopt.rb
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new()
cmdopt.add(:file, '-f, --file=<FILE>', "filename")
cmdopt.add(:mode, '-m <MODE>'        , "verbose/quiet")
puts "Usage: blabla [<options>]"
puts cmdopt.to_s()
### output (calculated proper width)
# Usage: blabla [<options>]
#   -f, --file=<FILE>    : filename
#   -m <MODE>            : verbose/quiet
```

* `optparse.rb` enforces you to catch `OptionParser::ParseError` exception.
  That is, you must know the error class name.

  `benry/cmdopt.rb` provides error handler without exception class name.
  You don't need to know the error class name on error handling.

```ruby
### optparse.rb
require 'optparse'
parser = OptionParser.new
parser.on('-f', '--file=<FILE>', "filename")
opts = {}
begin
  parser.parse!(ARGV, into: opts)
rescue OptionParser::ParseError => err   # specify error class
  abort "ERROR: #{err.message}"
end

### benry/cmdopt.rb
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new
cmdopt.add(:file, '-f, --file=<FILE>', "filename")
opts = cmdopt.parse(ARGV) do |err|  # error handling wihtout error class name
  abort "ERROR: #{err.message}"
end
```

* The source code of "optparse.rb" is quite large and complex for a command
  option parser library. The reason is that one large `OptParse` class
  does everything related to parsing command options. Bad class design.
  Therefore it is hard to customize or extend `OptionParser` class.

  In contract, `benry/cmdopt.rb` consists of several classes
  (schema class, parser class, and facade class).
  Therefore it is easy to understand and extend these classes.

  In fact, file `optparse.rb` and `optparse/*.rb` (in Ruby 3.2)
  contains total 1298 lines (except comments and blanks), while
  `benry/cmdopt.rb` (v2.3.0) contains only 467 lines (except both, too).



## Install

```
$ gem install benry-cmdopt
```



## Usage


### Define, Parse, and Print Help

```ruby
require 'benry/cmdopt'

## define
cmdopt = Benry::CmdOpt.new
cmdopt.add(:help   , '-h, --help'   , "print help message")
cmdopt.add(:version, '    --version', "print version")

## parse with error handling
options = cmdopt.parse(ARGV) do |err|
  abort "ERROR: #{err.message}"
end
p options     # ex: {:help => true, :version => true}
p ARGV        # options are removed from ARGV

## help
if options[:help]
  puts "Usage: foobar [<options>] [<args>...]"
  puts ""
  puts "Options:"
  puts cmdopt.to_s()
  ## or: puts cmdopt.to_s(20)              # width
  ## or: puts cmdopt.to_s("  %-20s : %s")  # format
  ## or:
  #format = "  %-20s : %s"
  #cmdopt.each_option_and_desc {|opt, help| puts format % [opt, help] }
end
```

You can set `nil` to option name only if long option specified.

```ruby
## both are same
cmdopt.add(:help, "-h, --help", "print help message")
cmdopt.add(nil  , "-h, --help", "print help message")
```


### Command Option Parameter

```ruby
## required parameter
cmdopt.add(:file, '-f, --file=<FILE>', "filename")   # short & long
cmdopt.add(:file, '    --file=<FILE>', "filename")   # long only
cmdopt.add(:file, '-f <FILE>'        , "filename")   # short only

## optional parameter
cmdopt.add(:indent, '-i, --indent[=<N>]', "indent width")  # short & long
cmdopt.add(:indent, '    --indent[=<N>]', "indent width")  # long only
cmdopt.add(:indent, '-i[<N>]'           , "indent width")  # short only
```

Notice that `"--file <FILE>"` style is **not supported for usability reason**.
Use `"--file=<FILE>"` style instead.

(From a usability perspective, the former style should not be supported.
 `optparse.rb` is wrong because it supports both styles
 and doesn't provide the way to disable the former style.)


### Argument Validation

```ruby
## type (class)
cmdopt.add(:indent , '-i <N>', "indent width", type: Integer)
## pattern (regular expression)
cmdopt.add(:indent , '-i <N>', "indent width", rexp: /\A\d+\z/)
## enum (Array or Set)
cmdopt.add(:indent , '-i <N>', "indent width", enum: ["2", "4", "8"])
## range (endless range such as ``1..`` available)
cmdopt.add(:indent , '-i <N>', "indent width", range: (0..8))
## callback
cmdopt.add(:indent , '-i <N>', "indent width") {|val|
  val =~ /\A\d+\z/  or
    raise "Integer expected."  # raise without exception class.
  val.to_i                     # convert argument value.
}
```

(For backward compatibilidy, keyword parameter `pattern:` is available
 which is same as `rexp:`.)

`type:` keyword argument accepts the following classes.

* Integer   (`/\A[-+]?\d+\z/`)
* Float     (`/\A[-+]?(\d+\.\d*\|\.\d+)z/`)
* TrueClass (`/\A(true|on|yes|false|off|no)\z/`)
* Date      (`/\A\d\d\d\d-\d\d?-\d\d?\z/`)

Notice that Ruby doesn't have Boolean class.
Benry-CmdOpt uses TrueClass instead.

In addition:

* Values of `enum:` or `range:` should match to type class specified by `type:`.
* When `type:` is not specified, then String class will be used instead.

```ruby
## ok
cmdopt.add(:lang, '-l <lang>', "language", enum: ["en", "fr", "it"])

## error: enum values are not Integer
cmdopt.add(:lang, '-l <lang>', "language", enum: ["en", "fr", "it"], type: Integer)

## ok
cmdopt.add(:indent, '-i <N>', "indent", range: (0..), type: Integer)

## error: beginning value of range is not a String
cmdopt.add(:indent, '-i <N>', "indent", range: (0..))
```


### Boolean (on/off) Option

Benry-CmdOpt doens't support `--no-xxx` style option for usability reason.
Use boolean option instead.

ex3.rb:

```ruby
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new()
cmdopt.add(:foo, "--foo[=on|off]", "foo feature", type: TrueClass)  # !!!!
## or:
#cmdopt.add(:foo, "--foo=<on|off>", "foo feature", type: TrueClass)
options = cmdopt.parse(ARGV)
p options
```

Output example:

```terminal
$ ruby ex3.rb --foo           # enable
{:foo=>true}
$ ruby ex3.rb --foo=on        # enable
{:foo=>true}
$ ruby ex3.rb --foo=off       # disable
{:foo=>false}
```


### Alternative Value

Benry-CmdOpt supports alternative value.

```ruby
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new
cmdopt.add(:help1, "-h", "help")
cmdopt.add(:help2, "-H", "help", value: "HELP")   # !!!!!

options = cmdopt.parse(["-h", "-H"])
p options[:help1]   #=> true          # normal
p options[:help2]   #=> "HELP"        # alternative value
```

This is useful for boolean option.

```ruby
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new
cmdopt.add(:flag1, "--flag1[=<on|off>]", "f1", type: TrueClass)
cmdopt.add(:flag2, "--flag2[=<on|off>]", "f2", type: TrueClass, value: false)  # !!!!

## when `--flag2` specified, got `false` value.
options = cmdopt.parse(["--flag1", "--flag2"])
p options[:flag1]   #=> true
p options[:flag2]   #=> false (!!!!!)
```


### Multiple Value Option

Release 2.4 or later supports `multiple: true` keyword arg.

```ruby
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new

cmdopt.add(:inc , '-I <path>', "include path", multiple: true)  # !!!!
options = cmdopt.parse(["-I", "/foo", "-I", "/bar", "-I/baz"])
p options   #=> {:inc=>["/foo", "/bar", "/baz"]}
```

On older version:

```ruby
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new

cmdopt.add(:inc , '-I <path>', "include path") {|options, key, val|
  arr = options[key] || []
  arr << val
  arr
  ## or:
  #(options[key] || []) << val
}

options = cmdopt.parse(["-I", "/foo", "-I", "/bar", "-I/baz"])
p options   #=> {:inc=>["/foo", "/bar", "/baz"]}
```


### Hidden Option

Benry-CmdOpt regards the following options as hidden.

* Keyword argument `hidden: true` is passed to `.add()` method.
* Or description is nil.

Hidden options are not included in help message.

```ruby
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new
cmdopt.add(:help   , '-h', "help message")
cmdopt.add(:logging, '-L', "logging", hidden: true)  # hidden
cmdopt.add(:debug  , '-D', nil)                      # hidden (desc is nil)
puts cmdopt.to_s()

### output (neither '-L' nor '-D' is shown because hidden options)
#  -h             : help message
```

To show all options including hidden ones, add `all: true` to `cmdopt.to_s()`.

```ruby
...(snip)...
puts cmdopt.to_s(all: true)   # or: cmdopt.to_s(nil, all: true)

### output
#  -h             : help message
#  -L             : logging
#  -D             : 
```


### Global Options with Sub-Commands

`parse()` accepts boolean keyword argument `all`.

* `parse(argv, all: true)` parses even options placed after arguments. This is the default.
* `parse(argv, all: false)` only parses options placed before arguments.

```ruby
require 'benry/cmdopt'
cmdopt = Benry::CmdOpt.new()
cmdopt.add(:help   , '--help'   , "print help message")
cmdopt.add(:version, '--version', "print version")

## `parse(argv, all: true)` (default)
argv = ["--help", "arg1", "--version", "arg2"]
options = cmdopt.parse(argv, all: true)          # !!!
p options       #=> {:help=>true, :version=>true}
p argv          #=> ["arg1", "arg2"]

## `parse(argv, all: false)`
argv = ["--help", "arg1", "--version", "arg2"]
options = cmdopt.parse(argv, all: false)         # !!!
p options       #=> {:help=>true}
p argv          #=> ["arg1", "--version", "arg2"]
```

This is useful when parsing global options of sub-commands, like Git command.

```ruby
require 'benry/cmdopt'

argv = ["-h", "commit", "xxx", "-m", "yyy"]

## parse global options
cmdopt = Benry::CmdOpt.new()
cmdopt.add(:help, '-h', "print help message")
global_opts = cmdopt.parse(argv, all: false)   # !!!false!!!
p global_opts       #=> {:help=>true}
p argv              #=> ["commit", "xxx", "-m", "yyy"]

## get sub-command
sub_command = argv.shift()
p sub_command       #=> "commit"
p argv              #=> ["xxx", "-m", "yyy"]

## parse sub-command options
cmdopt = Benry::CmdOpt.new()
case sub_command
when "commit"
  cmdopt.add(:message, '-m <message>', "commit message")
else
  # ...
end
sub_opts = cmdopt.parse(argv, all: true)       # !!!true!!!
p sub_opts          #=> {:message => "yyy"}
p argv              #=> ["xxx"]
```


### Detailed Description of Option

`#add()` method in `Benry::CmdOpt` or `Benry::CmdOpt::Schema` supports `detail:` keyword argument which takes detailed description of option.

```ruby
require 'benry/cmdopt'

cmdopt = Benry::CmdOpt.new()
cmdopt.add(:mode, "-m, --mode=<MODE>", "output mode", detail: <<"END")
  v, verbose: print many output
  q, quiet:   print litte output
  c, compact: print summary output
END
puts cmdopt.to_s()
## or:
#cmdopt.each_option_and_desc do |optstr, desc, detail|
#  puts "  %-20s : %s\n" % [optstr, desc]
#  puts detail.gsub(/^/, ' ' * 25) if detail
#end
```

Output:

```
  -m, --mode=<MODE>    : output mode
                           v, verbose: print many output
                           q, quiet:   print litte output
                           c, compact: print summary output
```


### Option Tag

`#add()` method in `Benry::CmdOpt` or `Benry::CmdOpt::Schema` supports `tag:` keyword argument.
You can use it for any purpose.

```ruby
require 'benry/cmdopt'

cmdopt = Benry::CmdOpt.new()
cmdopt.add(:help, "-h, --help", "help message", tag: "important")  # !!!
cmdopt.add(:version, "--version", "print version", tag: nil)
cmdopt.schema.each do |item|
  puts "#{item.key}: tag=#{item.tag.inspect}"
end

## output:
#help: tag="important"
#version: tag=nil
```


### Important Options

You can specify that the option is important or not.
Pass `important: true` or `important: false` keyword argument to `#add()` method of `Benry::CmdOpt` or `Benry::CmdOpt::Schema` object.

The help message of options is decorated according to value of `important:` keyword argument.

* Printed in bold font when `important: true` specified to the option.
* Printed in gray color when `important: false` specified to the option.

```ruby
require 'benry/cmdopt'

cmdopt = Benry::CmdOpt.new()
cmdopt.add(:help   , "-h", "help message")
cmdopt.add(:verbose, "-v", "verbose mode", important: true)   # !!!
cmdopt.add(:debug  , "-D", "debug mode"  , important: false)  # !!!
puts cmdopt.option_help()

## output:
#  -h       : help message
#  -v       : verbose mode      # bold font
#  -D       : debug mode        # gray color
```


### Not Supported

* default value when the option not specified in command-line
* `--no-xxx` style option
* bash/zsh completion (may be supported in the future)
* I18N of error message (may be supported in the future)



## Internal Classes

* `Benry::CmdOpt::Schema` ... command option schema.
* `Benry::CmdOpt::Parser` ... command option parser.
* `Benry::CmdOpt::Facade` ... facade object including schema and parser.

```ruby
require 'benry/cmdopt'

## define schema
schema = Benry::CmdOpt::Schema.new
schema.add(:help  , '-h, --help'            , "show help message")
schema.add(:file  , '-f, --file=<FILE>'     , "filename")
schema.add(:indent, '-i, --indent[=<WIDTH>]', "enable indent", type: Integer)

## parse options
parser = Benry::CmdOpt::Parser.new(schema)
argv = ['-hi2', '--file=blabla.txt', 'aaa', 'bbb']
opts = parser.parse(argv) do |err|
  abort "ERROR: #{err.message}"
end
p opts   #=> {:help=>true, :indent=>2, :file=>"blabla.txt"}
p argv   #=> ["aaa", "bbb"]
```

Notice that `Benry::CmdOpt.new()` returns a facade object.

```ruby
require 'benry/cmdopt'

cmdopt = Benry::CmdOpt.new()             # new facade object
cmdopt.add(:help, '-h', "help message")  # same as schema.add(...)
opts = cmdopt.parse(ARGV)                # same as parser.parse(...)
```

Notice that `cmdopt.is_a?(Benry::CmdOpt)` results in false.
Use `cmdopt.is_a?(Benry::CmdOpt::Facade)` instead if necessary.



## License and Copyright

$License: MIT License $

$Copyright: copyright(c) 2021 kwatch@gmail.com $
