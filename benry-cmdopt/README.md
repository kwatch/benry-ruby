Benry::Cmdopt README
====================

($Release: 0.0.0 $)

Benry::Cmdopt is a command option parser library, like `optparse.rb`.

Compared to `optparse.rb`, Benry::Cmdopt is easy to use, easy to extend,
and easy to understahnd.

(Benry::Cmdopt requires Ruby >= 2.3)


Why not `optparse.rb`?
======================

* Source code of `optparse.rb` is very large and complicated, because
  `OptParse` class does everything about command option parsing.
  It is hard to customize or extend `OptionParser` class.

  On the other hand, `benry/cmdopt.rb` consists of several classes
  (schema class, parser class, and facade class).
  Therefore it is easy to understand and extend these classes.

  File `optparse.rb` contains 1234 lines (without comments), while
  `benry/cmdopt.rb` (v1.1.0) contains only 361 lines (without comments).

* `optparse.rb` regards `-x` as a short cut of `--xxx` automatically
  even if you have not defined `-x` option.
  That is, short options which are not defined can be available unexpectedly.
  This feature is hard-coded in `OptionParser#parse_in_order()`
  and hard to be disabled.

  On the other hand, `benry/cmdopt.rb` doesn't behave this way.
  `-x` option is available only when `-x` is defined.

* `optparse.rb` can handle both `--name=val` and `--name val` styles.
  The later style is ambiguous; you may wonder whether `--name` takes
  `val` as argument or `--name` takes no argument (and `val` is command
  argument).

  Therefore the `--name=val` style is better than the `--name val` style.

  `optparse.rb` cannot disable `--name val` style.
  `benry/cmdopt.rb` supports only `--name=val` style.

* `optparse.rb` enforces you to catch `OptionParser::ParseError` exception.
  That is, you must know error class name.

  `benry/cmdopt.rb` provides error handler without exception class name.
  You don't need to know error class name on error handling.

```ruby
### optparse.rb
require 'optparse'
parser = OptionParser.new
parser.on('-f', '--file=<FILE>', "filename")
opts = {}
begin
  parser.parse!(ARGV, into: opts)
rescue OptionParser::ParseError => ex   # specify error class
  $stderr.puts "ERROR: #{ex.message}"
  exit 1
end

### benry/cmdopt.rb
require 'benry/cmdopt'
cmdopt = Benry::Cmdopt.new
cmdopt.add(:file, '-f, --file=<FILE>', "filename")
opts = cmdopt.parse(ARGV) do |err|  # error handling wihtout error class name
  $stderr.puts "ERROR: #{err.message}"
  exit 1
end
```

* `optparse.rb` uses long option name as hash key automatically, but
  it doesn't provide the way to specify hash key of short-only option.

  `benry/cmdopt.rb` can specify hash key of short-only option.

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
cmdopt = Benry::Cmdopt.new
cmdopt.add(:verbose, '-v, --verbose', "verbose mode") # short and long
cmdopt.add(:quiet  , '-q'           , "quiet mode")   # short-only
#
opts = cmdopt.parse(['-v'])   # short option
p opts  #=> {:verbose=>true}  # independent hash key of option name
#
opts = cmdopt.parse(['-q'])   # short option
p opts  #=> {:quiet=>true}    # independent hash key of option name
```

* `optparse.rb` adds `-h` and `--help` options automatically, and
  terminates current process when `-v` or `--version` specified in terminal.
  It is hard to remove these options.

  On the other hand, `benry/cmdopt.rb` does not add these options.
  benry/cmdopt.rb` does nothing extra.

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

  On the other hand, `benry/cmdopt.rb` does not add these options.
  benry/cmdopt.rb` does nothing extra.

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

* `optparse.rb` generates help message with too wide option name
  by default. You must specify proper width.

  `benry/cmdopt.rb` calculates proper width automatically.
  You don't need to specify proper width in many case.

```ruby
### optparse.rb
require 'optparse'
banner = "Usage: blabla <options>"
parser = OptionParser.new(banner)  # or OptionParser.new(banner, 25)
parser.on('-f', '--file=<FILE>', "filename")
parser.on('-m <MODE>'          , "verbose/quiet")
puts parser.help
### output
# Usage: blabla <options>
#     -f, --file=<FILE>                filename
#     -m <MODE>                        verbose/quiet

### benry/cmdopt.rb
require 'benry/cmdopt'
cmdopt = Benry::Cmdopt.new()
cmdopt.add(:file, '-f, --file=<FILE>', "filename")
cmdopt.add(:mode, '-m <MODE>'        , "verbose/quiet")
puts "Usage: blabla <options>"
puts cmdopt.option_help()
### output (calculated proper width)
# Usage: blabla <options>
#   -f, --file=<FILE>    : filename
#   -m <MODE>            : verbose/quiet
```


Usage
=====


Define, parse, and print help
-----------------------------

```ruby
require 'benry/cmdopt'

## define
cmdopt = Benry::Cmdopt.new
cmdopt.add(:help   , '-h, --help'   , "print help message")
cmdopt.add(:version, '    --version', "print version")

## parse with error handling
options = cmdopt.parse(ARGV) do |err|
  $stderr.puts "ERROR: #{err.message}"
  exit(1)
end
p options     # ex: {:help => true, :version => true}
p ARGV        # options are removed from ARGV

## help
if options[:help]
  puts "Usage: foobar [<options>] [<args>...]"
  puts ""
  puts "Options:"
  puts cmdopt.option_help()
  ## or
  #format = "  %-20s : %s"
  #cmdopt.each_option_help {|opt, help| puts format % [opt, help] }
end
```


Command option parameter
------------------------

```ruby
## required parameter
cmdopt.add(:file, '-f, --file=<FILE>', "filename")
cmdopt.add(:file, '    --file=<FILE>', "filename")
cmdopt.add(:file, '-f <FILE>'        , "filename")

## optional parameter
cmdopt.add(:file, '-f, --file[=<FILE>]', "filename")
cmdopt.add(:file, '    --file[=<FILE>]', "filename")
cmdopt.add(:file, '-f[<FILE>]'         , "filename")
```

Notice that `"--file <FILE>"` style is not supported.
Please use `"--file=<FILE>"` style.


Argument varidation
-------------------

```ruby
## type
cmdopt.add(:indent , '-i <N>', "indent width", type: Integer)
## pattern
cmdopt.add(:indent , '-i <N>', "indent width", pattern: /\A\d+\z/)
## enum
cmdopt.add(:indent , '-i <N>', "indent width", enum: [2, 4, 8])
## callback
cmdopt.add(:indent , '-i <N>', "indent width") {|val|
  val =~ /\A\d+\z/  or
    raise "integer expected."  # raise without exception class.
  val.to_i                     # convert argument value.
}
```


Available types
---------------

* Integer   (`/\A[-+]?\d+\z/`)
* Float     (`/\A[-+]?(\d+\.\d*\|\.\d+)z/`)
* TrueClass (`/\A(true|on|yes|false|off|no)\z/`)
* Date      (`/\A\d\d\d\d-\d\d?-\d\d?\z/`)


Multiple parameters
-------------------

```ruby
cmdopt.add(:lib , '-I <NAME>', "library name") {|optdict, key, val|
  arr = optdict[key] || []
  arr << val
  arr
}
```


Hidden option
-------------

If help string of command otpion is nil, it will not included
in help message.

```ruby
require 'benry/cmdopt'
cmdopt = Benry::Cmdopt.new
cmdopt.add(:verbose, '-v, --verbose', "verbose mode")
cmdopt.add(:debug  , '-d[<LEVEL>]'  , nil, type: Integer) # hidden
puts cmdopt.option_help()
### output ('-d' is not included)
#  -v, --verbose        : verbose mode
```


Not supported
-------------

* default value
* `--no-xxx` style option
* bash/zsh completion


Internal classes
================

* `Benry::Cmdopt::Schema` -- command option schema.
* `Benry::Cmdopt::Parser` -- command option parser.
* `Benry::Cmdopt::Facade` -- facade object including schema and parser.

```ruby
require 'benry/cmdopt'

## define schema
schema = Benry::Cmdopt::Schema.new
schema.add(:help  , '-h, --help'            , "show help message")
schema.add(:file  , '-f, --file=<FILE>'     , "filename")
schema.add(:indent, '-i, --indent[=<WIDTH>]', "enable indent", type: Integer)

## parse options
parser = Benry::Cmdopt::Parser.new(schema)
argv = ['-hi2', '--file=blabla.txt', 'aaa', 'bbb']
opts = parser.parse(argv) do |err|
  $stderr.puts "ERROR: #{err.message}"
  exit 1
end
p opts   #=> {:help=>true, :indent=>2, :file=>"blabla.txt"}
p argv   #=> ["aaa", "bbb"]
```

Notice that `Benry::Cmdopt.new()` returns facade object.

```ruby
require 'benry/cmdopt'

cmdopt = Benry::Cmdopt.new()             # new facade object
cmdopt.add(:help, '-h', "help message")  # same as schema.add(...)
opts = cmdopt.parse(ARGV)                # same as parser.parse(...)
```


License and Copyright
=====================

$License: MIT License $

$Copyright: copyright(c) 2021 kuwata-lab.com all rights reserved $
