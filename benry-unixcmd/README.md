benry-unixcmd Gem README
========================

($Release: 0.0.0 $)

benry-unixcmd gem implements popular UNIX commands, like FileUtils.

Features compared to FileUtils:

* supports file patterns (`*`, `.`, `{}`) directly.
* provides `cp :r`, `mv :p`, `rm :rf`, ... instead of `cp_r`, `mv_p`, `rm_rf`, ...
* prints command prompt `$ ` before command echoback.
* provides `pushd` which is similar to `cd` but supports nested calls naturally.
* implements `capture2`, `capture2e`, and `capture3` which calls
  `Popen3.capture2`, `Popen3.capture2`, and `Popen3.capture3` respectively.
* supports `touch -r reffile`.
* provides `atomic_symlink!` command which switches symlink atomically.

(benry-unixcmd gem requires Ruby >= 2.3)



Install
=======

```
$ gem install benry-unixcmd
```

File: ex1.rb

```ruby
require 'benry/unixcmd'      # !!!!!
include Benry::UnixCommand   # !!!!!

output = capture2 "ls -al"   # run command and return output
#print output
```

Result:

```terminal
[localhost] ruby ex1.rb
$ ls -al
```



Command Reference
=================



`echo`
------

File: ex-echo1.rb

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

echo "aa", "bb", "cc"

echo :n, "aa"        # not print "\n"
echo "bb"
```

Result:

```terminal
[localhost]$ ruby ex_echo1.rb
$ echo aa bb cc
aa bb cc
$ echo -n aa
aa$ echo bb
bb
```

Options:

* `echo :n` -- don't print "\n".



`echoback`
----------

* `echoback "command"` prints `$ command` string into stdout.
* `echoback "command"` indents command if in block of `cd` or `pushd`.

File: ex-echoback1.rb

```
require 'benry/unixcmd'
include Benry::UnixCommand

echoback "command 123"
cd "dir1" do
  echoback "command 456"
  cd "dir2" do
    echoback "command 789"
  end
end
```

Result:

```terminal
[localhost]$ ruby ex_echoback1.rb
$ command 123
$ cd dir1
$  command 456
$  cd dir2
$   command 789
$  cd -
$ cd -
```



`cp`
----

* `cp "x", "y"` copies `x` to new file `y'. Fails when `y` already exists.
* `cp! "x", "y"` is similar to above, but overwrites `y` even if it exists.
* `cp "x", "y", to: "dir"` copies `x` and `y` into `dir`.
* `cp "x", "y", "dir"` will be error! (use `to: "dir"` instead.)
* Glob patten such as `*`, `**`, `?`, and `{}` are available.
* (See [FAQ](#faq) about `to:` keyword option.)

<!--
File: ex-cp1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## copy file to newfile
cp  "file1.txt", "newfile.txt"      # error if newfile.txt already exists.
cp! "file1.txt", "newfile.txt"      # overrides newfile.txt if exists.

## copy dir to newdir recursively
cp :r, "dir1", "newdir"             # error if newdir already exists.

## copy files to existing directory
cp :pr, "file*.txt", "lib/**/*.rb", to: "dir1"   # error if dir1 not exist.
```

Options:

* `cp :p` -- preserves timestamps and permission.
* `cp :r` -- copies files and directories recursively.
* `cp :l` -- creates hard links instead of copying files.
* `cp :f` -- ignores non-existing source files.
             Notice that this is different from `cp -f` of unix command.



`mv`
----

* `mv "x", "y"` renames `x` to `y`. Fails when `y` already exists.
* `mv! "x", "y"` is similar to above, but overwrites `y` even if it exists.
* `mv "x", "y", to: "dir"` moves `x` and `y` into `dir`.
* `mv "x", "y", "dir"` will be error! (use `to: "dir"` instead.)
* Glob patten such as `*`, `**`, `?`, and `{}` are available.
* (See [FAQ](#faq) about `to:` keyword option.)

<!--
File: ex-mv1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## rename file
mv  "file1.txt", "newfile.txt"      # error if newfile.txt already exists.
mv! "file1.txt", "newfile.txt"      # overrides newfile.txt if exists.

## rename directory
mv "dir1", "newdir"                 # error if newdir already exists.

## move files and directories to existing directory
mv "file*.txt", "lib", to: "dir1"   # error if dir1 not exist.

## ignore non-existing files.
mv     "foo*.txt", to: "dir1"       # error if foo*.txt not exist.
mv :f, "foo*.txt", to: "dir1"       # not error even if foo*.txt not exist.
```

Options:

* `mv :f` -- ignores non-existing source files.



`rm`
----

* `rm "x", "y"` removes file `x` and `y`.
* `rm :r, "dir1"` removes directory recursively.
* `rm "dir1"` will raise error because `:r` option not specified.
* `rm foo*.txt` will raise error if `foo*.txt` not exists.
* `rm :f foo*.txt` will not raise error even if `foo*.txt` not exists.
* Glob patten such as `*`, `**`, `?`, and `{}` are available.

<!--
File: ex-rm1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## remove files
rm  "foo*.txt", "bar*.txt"          # error if files not exist.
rm :f, "foo*.txt", "bar*.txt"       # not error even if files not exist.

## remove directory
rm :r,  "dir1"                      # error if dir1 not exist.
rm :rf, "dir1"                      # not error even if dir1 not exist.
```

Options:

* `rm :r` -- remove files and directories recursively.
* `rm :f` -- ignores non-existing files and directories.



`mkdir`
-------

* `mkdir "x", "y"` creates `x` and `y` directories.
* `mkdir :p, "x/y/z"` creates `x/y/z` directory.
* `mkdir "x"` will be error if `x` already exists.
* `mkdir :p, "x"` will not be error even if `x` already exists.
* `mkdir :m, 0775, "x"` creates new directory with permission 0775.

<!--
File: ex-mkdir1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## creates new directory
mkdir "newdir"

## creates new directory with path
mkdir :p, "dir/x/y/z"

## creats new directory with specific permission
mkdir :m, 0755, "newdir"
```

Options:

* `mkdir :p` -- creates intermediate path.
* `mkdir :m, 0XXX` -- specifies directory permission.



`rmdir`
-------

* `rmdir "x", "y"` removed empty directores.
* Raises error when directory not empty.

<!--
File: ex-rmdir1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## remove empty directory
rmdir "dir"     # error if directory not empty.
```

Options:

* (no options)



`ln`
----

* `ln "x", "y"` creates hard link.
* `ln :s, "x", "y"` creates symbolic link. Error if `y` already exists.
* `ln! :s, "x", "y"` overwrites existing symbolic link `y`.
* `ln "files*.txt', to: "dir"` creates hard links into `dir`.
* `ln "files*.txt', "dir"` will be error! (use `to: "dir"` instead.)
* (See [FAQ](#faq) about `to:` keyword option.)

<!--
File: ex-ln1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## create hard link
ln "foo1.txt", "dir/foo1.txt"

## create symbolic link
ln :s, "foo1.txt", "dir/foo1.txt"     # error if dir/foo1.txt alreay exists.
ln! :s, "foo1.txt", "dir/foo1.txt"    # overwrites dir/foo1.txt if exists.

## create symbolic link into directory.
ln :s, "foo1.txt", to: "dir"

## error! use `to: "dir"` instead.
ln :s, "foo1.txt", "dir"
```



`atomic_symlink!`
-----------------

* `atomic_symlink! "x", "y"` creates symbolic link atomically.

<!--
File: ex-atomic_symlink1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## create symbolic link atomically
atomic_symlink! "src-20200101", "src"

## the above is same as the following
tmp = "src.#{rand().to_s[2..6]}"      # random name
File.symlink("src-20200101", tmp)     # create symblink with random name
File.rename(tmp, "src")               # rename symlink atomically
```

Options:

* (no options)



`touch`
-------

* `touch "x"` updates timestamp of file.
* `touch :r, "reffile", "x"` uses timestamp of `reffile` instead current timestamp.

<!--
File: ex-touch1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## updates timestamp of files to current timestamp.
touch "files*.txt"

## copy timestamp from reffile to other files.
touch :r, "reffile", "files*.txt"
```

Options:

* `touch :a` -- updates only access time.
* `touch :m` -- updates only modification time.
* `touch :r reffile` -- uses timestamp of `reffile` instead of current timestamp.



`chmod`
-------

* `chmod 0644 "x"` changes file permission.
* `chmod :R, "a+r", "dir"` changes permissions recursively.
* Permission can be `0644` sytle, or `u+w` style.

<!--
File: ex-chmod1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## change permissions of files.
chmod 0644, "file*.txt"
chmod "a+r", "file*.txt"

## change permissions recursively.
chmod :R, 0644, "dir"
chmod :R, "a+r", "dir"
```

Optionns:

* `chmod :R` -- changes permissions recursively.



`chown`
-------

* `chown "user:group", "x", "y"` changes owner and group of files.
* `chown "user", "x", "y"` changes owner of files.
* `chown ":group", "x", "y"` changes group of files.
* `chown :R, "user:group", "dir"` changes owner and group recursively.

<!--
File: ex-chown1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## change owner and/or group.
chown "user1:group1", "file*.txt"     # change both owner and group
chown "user1",        "file*.txt"     # change owner
chown ":group1",      "file*.txt"     # change group
```

Optionns:

* `chown :R` -- changes owner and/or group recursively.



`pwd`
-----

* `pwd()` prints current working directory path.

<!--
File: ex-pwd1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## prints current working directory
pwd()
```

Options:

* (no options)



`store`
-------

* `store "x", "y", to: "dir", ` copies files under `x` and `y` to `dir` keeping file path.
  For example, `x/foo/bar.rb` will be copied as `dir/x/foo/bar.rb`.
* `store!` overwrites existing files while `store` doesn't.

<!--
File: ex-store1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## copies files into builddir, keeping file path
store "lib/**/*.rb", "test/**/*.rb", to: "builddir"
```

Options:

* `store :p` -- preserves timestamps, permission, file owner and group.
* `store :l` -- creates hard link instead of copying file.
* `store :f` -- ignores non-existing files.



`sh`
----

* `sh "ls -al"` runs `ls -al` command.
* `sh` raises error when command failed.
* `sh!` ignores error even when command failed.

<!--
File: ex-sh1.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## run `ls -al` command
sh "ls -al"     # may raise error when command failed
sh! "ls -al"    # ignore error even when command filed
```

Options:

* (no options)



`capture2`
----------

* `capture2 "ls -al"` runs `ls -al` and returns output of the command.
* `capture2 "cat -n", stdin_data: "A\nB\n"` run `cat -n` command and uses `"A\nB\n"` as stdin data.
* `caputre "ls foo"` will raise error when command failed.
* `caputre! "ls foo"` ignores error even when command failed, and returns command output and process status object.
* `capture2()` invokes `Popen3.capture2()` internally. All keyword arguments are available.

<!--
File: ex-capture2.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## run command and get output of the command.
output = capture2 "ls -l foo.txt"                  # error if command failed
output, process_status = capture2 "ls -l foot.xt"  # ignore error even command failed
puts process_status.exitstatus

## run command with stdin data.
input = "AA\nBB\nCC\n"
output = capture2 "cat -n", stdin_data: input
```

Options:

* see [`Popen3.capture2()` manual page](https://docs.ruby-lang.org/en/master/Open3.html#method-c-capture2).



`capture2e`
-----------

* almost same as `capture2`, but output contains both stdout and stderr.

<!--
File: ex-capture2e.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## run command and get output of the command, including stderr.
output = capture2e "time ls -al"
output, process_status = capture2e! "time ls -al"  # ignore error even command failed
puts process_status.exitstatus
```

Options:

* see [`Popen3.capture2e()` manual page](https://docs.ruby-lang.org/en/master/Open3.html#method-c-capture2e).



`capture3`
----------

* almost same as `capture3`, but returns both stdout output and stderr output.

<!--
File: ex-capture3.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

## run command and get output of both stdout and stderr separately
output, error = capture3 "time ls -al"
output, error, process_status = capture3! "time ls -al"  # ignore error even command failed
puts process_status.exitstatus

## run command with stdin data.
input = "AA\nBB\nCC\n"
output, error = capture3 "cat -n", stdin_data: input
```

Options:

* see [`Popen3.capture3()` manual page](https://docs.ruby-lang.org/en/master/Open3.html#method-c-capture3).



`time`
------

* `time do ... end` invokes block and prints elapsed time into stderr.

File: ex-time1.rb

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

time do
  sh "zip -qr9 dir1.zip dir1"
end
```

Result:

```termianl
[localhost]$ ruby ex-time1.rb
$ zip -qr9 dir1.zip dir1

        1.511s real       1.501s user       0.006s sys
```



FAQ
====



Why `mv` or `cp` requires `to:` option?
---------------------------------------

Because UNIX command has bad interface which causes unexpected result.

For example, `mv` command of UNIX has two function: **rename** and **move**.

* rename: `mv foo bar` (if `bar` is a file or not exist)
* move: `mv foo bar` (if directory `bar` already exists)

Obviously, rename function and move function are same form.
This causes unexpected result easily due to, for example, typo.

```terminal
### Assume that you want rename 'foo' file to 'bar'.
### But if 'bar' exists as directory, mv command moves 'foo' into 'bar'.
### In this case, mv command should be error.
$ mv foo bar
```

To avoid this unexpected result, `mv()` command of Benry::UnixCommand handles two functions in different forms.

* rename: `mv "foo", "bar"` (error if directory `bar` exists)
* move: `mv "foo", to: "bar"` (error if 'bar' is a file or not exist)

In the same reason, `cp()` and `ln()` of Benry::UnixCommand also requires `to:` option.



How to use in Rakefile?
-----------------------

File: Rakefile

```ruby
require 'benry/unixcmd'      # !!!!!
include Benry::UnixCommand   # !!!!!
Rake::DSL.prepend Benry::UnixCommand  # !!!!!

task :example do
  mkdir :p, "foo/bar/baz"
  here = Dir.pwd()
  pushd "foo/bar/baz" do
    output = capture2 "pwd"
    puts output.sub(here+"/", "")
  end
end
```

Result:

```terminal
[localhost]$ rake example
$ mkdir -p foo/bar/baz
$ pushd foo/bar/baz
$  pwd
foo/bar/baz
$ popd    # back to /home/yourname
```



How to change prompt string?
----------------------------

File: ex-prompt1.rb

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

def prompt()                  # !!!!!
  "myname@localhost>"         # !!!!!
end                           # !!!!!

sh "date"
```

Result:

```terminal
[localhost]$ ruby ex-prompt1.rb
myname@localhost> date
Wed Jan 15 20:23:07 UTC 2021
```



How to make prompt colored?
---------------------------

<!--
File: ex-prompt2.rb
-->

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

def prompt()
  s = "myname@localhost>"
  "\e[0;31m#{s}\e[0m"    # red
  #"\e[0;32m#{s}\e[0m"    # green
  #"\e[0;33m#{s}\e[0m"    # yellow
  #"\e[0;34m#{s}\e[0m"    # blue
  #"\e[0;35m#{s}\e[0m"    # magenta
  #"\e[0;36m#{s}\e[0m"    # cyan
  #"\e[0;37m#{s}\e[0m"    # white
end

sh "date"
```



How to disable command echoback?
--------------------------------

File: ex-quiet1.rb

```ruby
require 'benry/unixcmd'
include Benry::UnixCommand

BENRY_ECHOBACK = false            # !!!!!

sh "date"
```

Result:

```terminal
$ ruby ex-quiet1.rb
Wed Jan  1 22:29:55 UTC 2020      # no echoback, only output
```



License and Copyright
=====================

$License: MIT License $

$Copyright: copyright(c) 2021 kuwata-lab.com all rights reserved $