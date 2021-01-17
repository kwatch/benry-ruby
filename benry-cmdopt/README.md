Benry::Cmdopt README
====================

($Release: 0.0.0 $)

Benry::Cmdopt is a command option parser library, like `optparse.rb`.

Compared to `optparse.rb`:

* Easy to use, easy to extend, easy to understand.
* Not add `-h` nor `--help` automatically.
* Not add `-v` nor `--version` automatically.
* Not regard `-x` as short cut of `--xxx`.
  (`optparser.rb` regards `-x` as short cut of `--xxx` automatically.)
* Provides very simple feature to build custom help message.
* Separates command option schema class from parser class.

(Benry::Cmdopt requires Ruby >= 2.3)


Usage
=====


Define, parse, and print help
-----------------------------

```ruby
require 'benry/cmdopt'

## define
cmdopt = Benry::Cmdopt.new
cmdopt.add(:help   , "-h, --help"   , "print help message")
cmdopt.add(:version, "    --version", "print version")

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
  puts cmdopt.build_option_help()
  ## or
  #format = "  %-20s : %s"
  #cmdopt.each_option_help {|opt, help| puts format % [opt, help] }
end
```


Command option parameter
------------------------

```ruby
## required parameter
cmdopt.add(:file, "-f, --file=<FILE>", "filename")
cmdopt.add(:file, "    --file=<FILE>", "filename")
cmdopt.add(:file, "-f <FILE>"        , "filename")

## optional parameter
cmdopt.add(:file, "-f, --file[=<FILE>]", "filename")
cmdopt.add(:file, "    --file[=<FILE>]", "filename")
cmdopt.add(:file, "-f[<FILE>]"         , "filename")
```


Argument varidation
-------------------

```ruby
## type
cmdopt.add(:indent , "-i <N>", "indent width", type: Integer)
## pattern
cmdopt.add(:indent , "-i <N>", "indent width", pattern: /\A\d+\z/)
## enum
cmdopt.add(:indent , "-i <N>", "indent width", enum: [2, 4, 8])
## callback
cmdopt.add(:indent , "-i <N>", "indent width") {|val|
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
cmdopt.add(:lib , "-I <NAME>", "library names") {|optdict, key, val|
  arr = optdict[key] || []
  arr << val
  arr
}
```


Not support
-----------

* default value
* `--no-xxx` style option


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
p opts   #=> [:help=>true, :indent=>2, :file=>"blabla.txt"]
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
