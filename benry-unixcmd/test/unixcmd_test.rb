# -*- coding: utf-8 -*-

libpath = File.class_eval { join(dirname(dirname(__FILE__)), 'lib') }
$LOAD_PATH << libpath unless $LOAD_PATH.include?(libpath)

require 'oktest'
require 'stringio'
require 'etc'

require 'benry/unixcmd'
require 'fileutils'


Oktest.scope do


  topic Benry::UnixCommand do
    include Benry::UnixCommand

    before_all do
      FileUtils.rm_rf "tmpdir"
      FileUtils.mkdir "tmpdir"
    end

    after_all do
      FileUtils.rm_rf "tmpdir"
    end

    before do
      @_backto = Dir.pwd
      Dir.chdir "tmpdir"
      File.write("foo1.txt", "FOO1")
      File.write("foo2.txt", "FOO2")
      FileUtils.mkdir "d1"
      File.write("d1/bar.txt", "BAR")
      FileUtils.mkdir "d1/d2"
      File.write("d1/d2/baz.txt", "BAZ")
    end

    after do
      Dir.chdir @_backto
      FileUtils.rm_rf Dir.glob("tmpdir/*")
    end

    def same_content?(file1, file2)
      ok {File.read(file1)} == File.read(file2)
    end

    def capture
      bkup = [$stdout, $stderr]
      $stdout = sout = StringIO.new
      $stderr = serr = StringIO.new
      yield sout, serr
      return sout.string, serr.string
    ensure
      $stdout, $stderr = bkup
    end


    topic 'prompt()' do
      spec "[!uilyk] returns prompt string." do
        ok {prompt()}  == "$"
      end
    end

    topic 'prompt!()' do
      spec "[!q992e] adds indentation after prompt." do
        ok {prompt!(0)} == "$ "
        ok {prompt!(1)} == "$  "
        ok {prompt!(2)} == "$   "
        ok {prompt!(3)} == "$    "
      end
    end


    topic 'echoback()' do
      spec "[!x7atu] prints argument string into $stdout with prompt." do
        sout, serr = capture_sio() do
          echoback "foo bar baz"
        end
        ok {sout} == "$ foo bar baz\n"
        ok {serr} == ""
      end
    end


    topic 'echo()' do
      spec "[!mzbdj] echoback command arguments." do
        sout, serr = capture_sio do
          echo "foo", "bar"
        end
        ok {sout} == ("$ echo foo bar\n"\
                      "foo bar\n")
      end
      spec "[!cjggd] prints arguments." do
        sout, serr = capture_sio do
          echo "abc", 123, true, nil
        end
        ok {sout} == ("$ echo abc 123 true \n"\
                      "abc 123 true \n")
      end
      spec "[!vhpw3] not print newline at end if '-n' option specified." do
        sout, serr = capture_sio do
          echo :n, "abc"
        end
        ok {sout} == ("$ echo -n abc\n"\
                      "abc")
      end
    end


    topic 'sys()' do
      spec "[!rqe7a] echoback command and arguments." do
        sout, serr = capture_sio do
          sys "echo foo bar >/dev/null"
        end
        ok {sout} == "$ echo foo bar >/dev/null\n"
      end
      spec "[!agntr] returns process status if command succeeded." do
        sout, serr = capture_sio do
          ret = sys "echo foo bar >/dev/null"
          ok {ret}.is_a?(Process::Status)
          ok {ret.exitstatus} == 0
        end
      end
      spec "[!clfig] yields block if command failed." do
        sout, serr = capture_sio do
          called = false
          stat = sys "false" do |stat|
            called = true
          end
          ok {called} == true
          ok {stat.exitstatus} == 1
        end
      end
      spec "[!deu3e] not yield block if command succeeded." do
        sout, serr = capture_sio do
          called = false
          ret = sys "true" do |stat|
            called = true
          end
          ok {called} == false
          ok {ret.exitstatus} == 0
        end
      end
      spec "[!chko8] block argument is process status." do
        sout, serr = capture_sio do
          arg = nil
          ret = sys "false" do |stat|
            arg = stat
            true
          end
          ok {arg}.is_a?(Process::Status)
          ok {arg}.same?(ret)
        end
      end
      spec "[!0yy6r] (sys) not raise error if block result is truthy" do
        sout, serr = capture_sio do
          pr = proc { sys "false" do true end }
          ok {pr}.NOT.raise?(ArgumentError)
          pr = proc { sys "false" do false end }
          ok {pr}.raise?(RuntimeError, "Command failed with status (1): false")
        end
      end
      spec "[!xsspi] (sys) raises error if command failed." do
        sout, serr = capture_sio do
          pr = proc { sys "grep -q ^FOOBAR foo1.txt" }
          ok {pr}.raise?(RuntimeError, "Command failed with status (1): grep -q ^FOOBAR foo1.txt")
        end
      end
    end

    topic 'sys!()' do
      spec "[!tbfii] (sys!) returns process status if command failed." do
        sout, serr = capture_sio do
          ret = sys! "grep -q ^FOOBAR foo1.txt"
          ok {ret}.is_a?(Process::Status)
          ok {ret.exitstatus} == 1
        end
      end
    end


    topic 'ruby()' do
      spec "[!98qro] echoback command and args." do
        sout, serr = capture_sio do
          ruby "-e", "x=0"
        end
        ok {sout} == "$ #{RbConfig.ruby} -e x=0\n"
      end
      spec "[!u5f5l] run ruby command." do
        sout, serr = capture_sio do
          ruby "-e 'File.write(\"out1\", \"ABC\")'"
          ruby "-e", "File.write(\"out2\", \"XYZ\")"
        end
        ok {sout} == ("$ #{RbConfig.ruby} -e 'File.write(\"out1\", \"ABC\")'\n"\
                      "$ #{RbConfig.ruby} -e File.write(\"out2\", \"XYZ\")\n")
        ok {File.read("out1")} == "ABC"
        ok {File.read("out2")} == "XYZ"
      end
      spec "[!2jano] returns process status object if ruby command succeeded." do
        sout, serr = capture_sio do
          ret = ruby "-e", "x = 1"
          ok {ret}.is_a?(Process::Status)
          ok {ret.exitstatus} == 0
        end
      end
      spec "[!69clt] (ruby) error when ruby command failed." do
        sout, serr = capture_sio do
          pr = proc { ruby "-e '1/0' 2> err1" }
          ok {pr}.raise?(RuntimeError, "Command failed with status (1): #{RbConfig.ruby} -e '1/0' 2> err1")
          ok {File.read("err1")} =~ /ZeroDivisionError/
        end
      end
    end

    topic 'ruby!()' do
      spec "[!z1f03] (ruby!) ignores error even when ruby command failed." do
        sout, serr = capture_sio do
          ret = nil
          pr = proc { ret = ruby! "-e '1/0' 2> err1" }
          ok {pr}.NOT.raise?(RuntimeError)
          ok {File.read("err1")} =~ /ZeroDivisionError/
          ok {ret}.is_a?(Process::Status)
          ok {ret.exitstatus} == 1
        end
      end
    end


    topic 'popen2()', tag: 'open3' do
      spec "[!8que2] calls 'Open3.popen2()'." do
        expected = ("     1	AA\n"\
                    "     2	BB\n"\
                    "     3	CC\n")
        #
        sout, serr = capture_sio do
          arr = popen2("cat -n")
          ok {arr}.length(3)
          stdin, stdout, wait_thread = arr
          stdin.write("AA\nBB\nCC\n")
          stdin.close()
          output = stdout.read()
          ok {output} == expected
        end
        ok {sout} == "$ cat -n\n"
        ok {serr} == ""
        #
        sout, serr = capture_sio do
          output2 = popen2("cat -n") do |*args|
            ok {args}.length(3)
            stdin, stdout, wait_thread = args
            stdin.write("AA\nBB\nCC\n")
            stdin.close()
            stdout.read()
          end
          ok {output2} == expected
        end
        ok {sout} == "$ cat -n\n"
        ok {serr} == ""
      end
    end

    topic 'popen2e()', tag: 'open3' do
      spec "[!s6g1r] calls 'Open3.popen2e()'." do
        expected = ("     1	AA\n"\
                    "     2	BB\n"\
                    "     3	CC\n"\
                    "        0.00 real         0.00 user         0.00 sys\n")
        #
        sout, serr = capture_sio do
          arr = popen2e("time cat -n")
          ok {arr}.length(3)
          stdin, stdout, wait_thread = arr
          stdin.write("AA\nBB\nCC\n")
          stdin.close()
          output = stdout.read()
          ok {output} == expected
        end
        ok {sout} == "$ time cat -n\n"
        ok {serr} == ""
        #
        sout, serr = capture_sio do
          output2 = popen2e("time cat -n") do |*args|
            ok {args}.length(3)
            stdin, stdout, wait_thread = args
            stdin.write("AA\nBB\nCC\n")
            stdin.close()
            stdout.read()
          end
          ok {output2} == expected
        end
        ok {sout} == "$ time cat -n\n"
        ok {serr} == ""
      end
    end

    topic 'popen3()', tag: 'open3' do
      spec "[!evlx7] calls 'Open3.popen3()'." do
        expected1 = ("     1	AA\n"\
                     "     2	BB\n"\
                     "     3	CC\n")
        expected2 = "        0.00 real         0.00 user         0.00 sys\n"
        #
        sout, serr = capture_sio do
          arr = popen3("time cat -n")
          ok {arr}.length(4)
          stdin, stdout, stderr, wait_thread = arr
          stdin.write("AA\nBB\nCC\n")
          stdin.close()
          ok {stdout.read()} == expected1
          ok {stderr.read()} == expected2
        end
        ok {sout} == "$ time cat -n\n"
        ok {serr} == ""
        #
        sout, serr = capture_sio do
          output, error = popen3("time cat -n") do |*args|
            ok {args}.length(4)
            stdin, stdout, stderr, wait_thread = args
            stdin.write("AA\nBB\nCC\n")
            stdin.close()
            [stdout.read(), stderr.read()]
          end
          ok {output} == expected1
          ok {error}  == expected2
        end
        ok {sout} == "$ time cat -n\n"
        ok {serr} == ""
      end
    end

    topic 'capture2()', tag: 'open3' do
      spec "[!5p4dw] calls 'Open3.capture2()'." do
        expected = ("     1	AA\n"\
                    "     2	BB\n"\
                    "     3	CC\n")
        #
        sout, serr = capture_sio do
          output = capture2("cat -n", stdin_data: "AA\nBB\nCC\n")
          ok {output} == expected
        end
        ok {sout} == "$ cat -n\n"
        ok {serr} == ""
      end
      spec "[!2s1by] error when command failed." do
        sout, serr = capture_sio do
          pr = proc { capture2("grep -q FOOBAR foo1.txt") }
          ok {pr}.raise?(RuntimeError, "Command failed with status (1): grep -q FOOBAR foo1.txt")
        end
        ok {sout} == "$ grep -q FOOBAR foo1.txt\n"
        ok {serr} == ""
      end
    end

    topic 'capture2e()', tag: 'open3' do
      spec "[!jgn71] calls 'Open3.capture2e()'." do
        expected = ("     1	AA\n"\
                    "     2	BB\n"\
                    "     3	CC\n"\
                    "        0.00 real         0.00 user         0.00 sys\n")
        #
        sout, serr = capture_sio do
          output = capture2e("time cat -n", stdin_data: "AA\nBB\nCC\n")
          ok {output} == expected
        end
        ok {sout} == "$ time cat -n\n"
        ok {serr} == ""
      end
      spec "[!qr3ka] error when command failed." do
        sout, serr = capture_sio do
          pr = proc { capture2e("grep -q FOOBAR foo1.txt") }
          ok {pr}.raise?(RuntimeError, "Command failed with status (1): grep -q FOOBAR foo1.txt")
        end
        ok {sout} == "$ grep -q FOOBAR foo1.txt\n"
        ok {serr} == ""
      end
    end

    topic 'capture3()', tag: 'open3' do
      spec "[!n91rh] calls 'Open3.capture3()'." do
        expected1 = ("     1	AA\n"\
                     "     2	BB\n"\
                     "     3	CC\n")
        expected2 =  "        0.00 real         0.00 user         0.00 sys\n"
        #
        sout, serr = capture_sio do
          output, error = capture3("time cat -n", stdin_data: "AA\nBB\nCC\n")
          ok {output} == expected1
          ok {error}  == expected2
        end
        ok {sout} == "$ time cat -n\n"
        ok {serr} == ""
      end
      spec "[!thnyv] error when command failed." do
        sout, serr = capture_sio do
          pr = proc { capture3("grep -q FOOBAR foo1.txt") }
          ok {pr}.raise?(RuntimeError, "Command failed with status (1): grep -q FOOBAR foo1.txt")
        end
        ok {sout} == "$ grep -q FOOBAR foo1.txt\n"
        ok {serr} == ""
      end
    end

    topic 'capture2!()', tag: 'open3' do
      spec "[!357e1] ignore errors even if command failed." do
        sout, serr = capture_sio do
          output, process_status = capture2!("grep -q FOOBAR foo1.txt")
          ok {process_status.exitstatus} == 1
          ok {output} == ""
        end
        ok {sout} == "$ grep -q FOOBAR foo1.txt\n"
        ok {serr} == ""
      end
    end

    topic 'capture2e!()', tag: 'open3' do
      spec "[!o0b7c] ignore errors even if command failed." do
        sout, serr = capture_sio do
          output, process_status = capture2e!("grep -q FOOBAR blabla.txt")
          ok {process_status.exitstatus} == 2
          ok {output} == "grep: blabla.txt: No such file or directory\n"
        end
        ok {sout} == "$ grep -q FOOBAR blabla.txt\n"
        ok {serr} == ""
      end
    end

    topic 'capture3()', tag: 'open3' do
      spec "[!rwfiu] ignore errors even if command failed." do
        sout, serr = capture_sio do
          output, error, process_status = capture3!("grep -q FOOBAR blabla.txt")
          ok {process_status.exitstatus} == 2
          ok {output} == ""
          ok {error}  == "grep: blabla.txt: No such file or directory\n"
        end
      end
    end


    topic 'cd()' do
      spec "[!gnmdg] expands file pattern." do
        sout, serr = capture_sio do
          here = Dir.pwd
          cd "d?"
          ok {Dir.pwd} == File.join(here, "d1")
        end
      end
      spec "[!v7bn7] error when pattern not matched to any file." do
        sout, serr = capture_sio do
          pr = proc { cd "blabla*" }
          ok {pr}.raise?(ArgumentError, "cd: blabla*: directory not found.")
        end
      end
      spec "[!08wuv] error when pattern matched to multiple files." do
        sout, serr = capture_sio do
          pr = proc { cd "foo*" }
          ok {pr}.raise?(ArgumentError, "cd: foo*: unexpectedly matched to multiple filenames (foo1.txt, foo2.txt).")
        end
      end
      spec "[!hs7u8] error when argument is not a directory name." do
        sout, serr = capture_sio do
          pr = proc { cd "foo1.txt" }
          ok {pr}.raise?(ArgumentError, "cd: foo1.txt: Not a directory.")
        end
      end
      spec "[!cg5ns] changes current directory." do
        here = Dir.pwd
        begin
          sout, serr = capture_sio() do
            cd "d1/d2"
            ok {Dir.pwd} == here + "/d1/d2"
          end
          ok {Dir.pwd} == here + "/d1/d2"
          ok {sout} == <<-END.gsub(/^ */, '')
            $ cd d1/d2
          END
          ok {serr} == ""
        ensure
          Dir.chdir(here)
        end
      end
      spec "[!uit6q] if block given, then back to current dir." do
        here = Dir.pwd
        sout, serr = capture_sio() do
          cd "d1" do
            ok {Dir.pwd} == here + "/d1"
            cd "d2" do
              ok {Dir.pwd} == here + "/d1/d2"
            end
            ok {Dir.pwd} == here + "/d1"
          end
          ok {Dir.pwd} == here
        end
        ok {sout} == <<-END.gsub(/^ */, '')
          $ cd d1
          $  cd d2
          $  cd -
          $ cd -
        END
        ok {serr} == ""
      end
      spec "[!cg298] returns path before changing directory." do
        here = Dir.pwd
        path = nil
        ret = nil
        capture_sio() do
          ret = cd "d1/d2" do
            path = Dir.pwd
          end
        end
        ok {ret} == here
        ok {ret} != path
      end
    end


    topic 'pushd()' do
      spec "[!nvkha] expands file pattern." do
        sout, serr = capture_sio do
          here = Dir.pwd
          pushd "d?" do
            ok {Dir.pwd} == File.join(here, "d1")
          end
        end
      end
      spec "[!q3itn] error when pattern not matched to any file." do
        sout, serr = capture_sio do
          pr = proc { pushd "blabla*" do end }
          ok {pr}.raise?(ArgumentError, "pushd: blabla*: directory not found.")
        end
      end
      spec "[!hveaj] error when pattern matched to multiple files." do
        sout, serr = capture_sio do
          pr = proc { pushd "foo*" do end }
          ok {pr}.raise?(ArgumentError, "pushd: foo*: unexpectedly matched to multiple filenames (foo1.txt, foo2.txt).")
        end
      end
      spec "[!y6cq9] error when argument is not a directory name." do
        sout, serr = capture_sio do
          pr = proc { pushd "foo1.txt" do end }
          ok {pr}.raise?(ArgumentError, "pushd: foo1.txt: Not a directory.")
        end
      end
      #
      spec "[!7ksfd] replaces home path with '~'." do
        home = home2 = nil
        sout, serr = capture_sio do
          home = File.expand_path("~")
          ok {home} != "~"
          pushd home do
            puts Dir.pwd
            home2 = Dir.pwd
            pushd "/" do
              puts Dir.pwd
            end
          end
        end
        skip_when home != home2, "home directory may be a symbolic link"
        ok {sout} =~ /^\$  popd    \# back to ~$/
      end
      spec "[!xl6lg] raises error when block not given." do
        pr = proc { pushd "d1/d2" }
        ok {pr}.raise?(ArgumentError, "pushd: requires block argument.")
      end
      spec "[!rxtd0] changes directory and yields block." do
        here = Dir.pwd
        path = nil
        sout, serr = capture_sio do
          pushd "d1/d2" do
            path = Dir.pwd
          end
        end
        home = File.expand_path('~')
        here2 = here.start_with?(home) ? here.sub(home, '~') : here
        ok {path} != nil
        ok {path} != here
        ok {path} == File.join(here, "d1/d2")
        ok {sout} == ("$ pushd d1/d2\n"\
                      "$ popd    # back to #{here2}\n")
      end
      spec "[!9jszw] back to origin directory after yielding block." do
        here = Dir.pwd
        path = nil
        sout, serr = capture_sio do
          pushd "d1/d2" do
            path = Dir.pwd
          end
        end
        ok {path} != nil
        ok {path} != here
        ok {Dir.pwd} == here
      end
    end


    topic 'cp()' do

      spec "[!mtuec] echoback copy command and arguments." do
        sout, serr = capture_sio do
          cp "foo1.txt", "foo9.txt"
        end
        ok {sout} == "$ cp foo1.txt foo9.txt\n"
        #
        sout, serr = capture_sio do
          cp :pr, "foo*.txt", to: "d1"
        end
        ok {sout} == "$ cp -pr foo*.txt d1\n"
      end

      case_when "[!u98f8] when `to:` keyword arg not specified..." do
        spec "[!u39p0] error when number of arguments is not 2." do
          sout, serr = capture_sio do
            pr = proc { cp() }
            ok {pr}.raise?(ArgumentError, "cp: requires two arguments.")
            pr = proc { cp "foo1.txt" }
            ok {pr}.raise?(ArgumentError, "cp: requires two arguments.")
            pr = proc { cp "foo1.txt", "foo2.txt", "foo3.txt" }
            ok {pr}.raise?(ArgumentError, "cp: too much arguments.")
          end
        end
        spec "[!fux6x] error when source pattern matched to multiple files." do
          sout, serr = capture_sio do
            pr = proc { cp "foo?.txt", "blabla.txt" }
            ok {pr}.raise?(ArgumentError, "cp: foo?.txt: unexpectedly matched to multiple files (foo1.txt, foo2.txt).")
          end
        end
        spec "[!y74ux] error when destination pattern matched to multiple files." do
          sout, serr = capture_sio do
            pr = proc { cp "d1/bar.txt", "foo*.txt" }
            ok {pr}.raise?(ArgumentError, "cp: foo*.txt: unexpectedly matched to multiple files (foo1.txt, foo2.txt).")
          end
        end
        #
        spec "[!qfidz] error when destination is a directory." do
          sout, serr = capture_sio do
            pr = proc { cp "foo1.txt", "d1" }
            ok {pr}.raise?(ArgumentError, "cp: d1: cannot copy into directory (requires `to: 'd1'` keyword option).")
          end
        end
        spec "[!073so] (cp) error when destination already exists to avoid overwriting it." do
          sout, serr = capture_sio do
            pr = proc { cp "foo1.txt", "foo2.txt" }
            ok {pr}.raise?(ArgumentError, "cp: foo2.txt: file already exists (to overwrite it, call `cp!` instead of `cp`).")
          end
        end
        spec "[!0tw8r] error when source is a directory but '-r' not specified." do
          sout, serr = capture_sio do
            pr = proc { cp "d1", "d9" }
            ok {pr}.raise?(ArgumentError, "cp: d1: is a directory (requires `:-r` option).")
          end
        end
        spec "[!lf6qi] error when target already exists." do
          sout, serr = capture_sio do
            dummy_dir("d9")
            pr = proc { cp :r, "d1", "d9" }
            ok {pr}.raise?(ArgumentError, "cp: d9: already exists.")
          end
        end
        spec "[!4xxpe] error when source is a special file." do
          sout, serr = capture_sio do
            pr = proc { cp :r, "/dev/null", "d9" }
            ok {pr}.raise?(ArgumentError, "cp: /dev/null: cannot copy special file.")
          end
        end
        spec "[!lr2bj] error when source file not found and '-f' option not specified." do
          sout, serr = capture_sio do
            pr = proc { cp "blabla.txt", "blabla2.txt" }
            ok {pr}.raise?(ArgumentError, "cp: blabla.txt: not found.")
          end
        end
        spec "[!urh40] do nothing if source file not found and '-f' option specified." do
          sout, serr = capture_sio do
            cp :f, "blabla.txt", "blabla2.txt"
            ok {"blabla2.txt"}.not_exist?
            cp :f, "bla*.txt", "blabla2.txt"
            ok {"blabla2.txt"}.not_exist?
          end
        end
        spec "[!kqgdl] copy a directory recursively if '-r' option specified." do
          sout, serr = capture_sio do
            ok {"d9"}.not_exist?
            cp :r, "d1", "d9"
            ok {"d9"}.dir_exist?
            ok {"d9/bar.txt"}.file_exist?
            ok {"d9/d2/baz.txt"}.file_exist?
            #
            cp :r, "foo1.txt", "blabla.txt"
            ok {"blabla.txt"}.file_exist?
          end
        end
        spec "[!ko4he] copy a file into new file if '-r' option not specifieid." do
          sout, serr = capture_sio do
            cp "foo1.txt", "blabla.txt"
            ok {"blabla.txt"}.file_exist?
          end
        end
        spec "[!lac46] keeps file mtime if '-p' option specified." do
          sout, serr = capture_sio do
            ctime1 = File.ctime("d1/bar.txt")
            mtime1 = File.mtime("d1/bar.txt")
            atime1 = File.atime("d1/bar.txt")
            #mtime2 = mtime1 - 900
            #atime2 = atime1 - 600
            mtime2 = (x = mtime1 - 900; Time.new(x.year, x.month, x.day, x.hour, x.min, x.sec))
            atime2 = (x = atime1 - 600; Time.new(x.year, x.month, x.day, x.hour, x.min, x.sec))
            #
            File.utime(atime2, mtime2, "d1/bar.txt")
            cp :p, "d1/bar.txt", "blabla.txt"
            ok {File.atime("blabla.txt")} != atime1
            ok {File.atime("blabla.txt")} != atime2
            ok {File.mtime("blabla.txt")} != mtime1
            ok {File.mtime("blabla.txt")} == mtime2   # !!!
            ok {File.ctime("blabla.txt")} != ctime1
            #
            cp :pr, "d1", "d9"
            ok {File.atime("d9/bar.txt")} != atime1
            ok {File.atime("d9/bar.txt")} != atime2
            ok {File.mtime("d9/bar.txt")} != mtime1
            ok {File.mtime("d9/bar.txt")} == mtime2   # !!!
            ok {File.ctime("d9/bar.txt")} != ctime1
          end
        end
        spec "[!d49vw] not keep file mtime if '-p' option not specified." do
          sout, serr = capture_sio do
            ctime1 = File.ctime("d1/bar.txt")
            mtime1 = File.mtime("d1/bar.txt")
            atime1 = File.atime("d1/bar.txt")
            #mtime2 = mtime1 - 900
            #atime2 = atime1 - 600
            mtime2 = (x = mtime1 - 900; Time.new(x.year, x.month, x.day, x.hour, x.min, x.sec))
            atime2 = (x = atime1 - 600; Time.new(x.year, x.month, x.day, x.hour, x.min, x.sec))
            #
            File.utime(atime2, mtime2, "d1/bar.txt")
            cp "d1/bar.txt", "blabla.txt"
            ok {File.atime("blabla.txt")} != atime1
            ok {File.atime("blabla.txt")} != atime2
            ok {File.mtime("blabla.txt")} != mtime1
            ok {File.mtime("blabla.txt")} != mtime2   # !!!
            ok {File.ctime("blabla.txt")} != ctime1
            #
            cp :r, "d1", "d9"
            ok {File.atime("d9/bar.txt")} != atime1
            ok {File.atime("d9/bar.txt")} != atime2
            ok {File.mtime("d9/bar.txt")} != mtime1
            ok {File.mtime("d9/bar.txt")} != mtime2   # !!!
            ok {File.ctime("d9/bar.txt")} != ctime1
          end
        end
        spec "[!ubthp] creates hard link instead of copy if '-l' option specified." do
          sout, serr = capture_sio do
            cp     "foo1.txt", "foo8.txt"
            ok {File.identical?("foo1.txt", "foo8.txt")} == false
            cp :l, "foo1.txt", "foo9.txt"
            ok {File.identical?("foo1.txt", "foo9.txt")} == true
          end
        end
        spec "[!yu51t] error when copying supecial files such as character device." do
          sout, serr = capture_sio do
            pr = proc { cp "/dev/null", "null" }
            ok {pr}.raise?(ArgumentError, "cp: /dev/null: cannot copy special file.")
          end
        end
      end

      case_else "[!z8xce] when `to:` keyword arg specified..." do
        spec "[!ms2sv] error when destination directory not exist." do
          sout, serr = capture_sio do
            pr = proc { cp "foo?.txt", to: "dir9" }
            ok {pr}.raise?(ArgumentError, "cp: dir9: directory not found.")
          end
        end
        spec "[!q9da3] error when destination pattern matched to multiple filenames." do
          sout, serr = capture_sio do
            pr = proc { cp "d1", to: "foo?.txt" }
            ok {pr}.raise?(ArgumentError, "cp: foo?.txt: unexpectedly matched to multiple filenames (foo1.txt, foo2.txt).")
          end
        end
        spec "[!lg3uz] error when destination is not a directory." do
          sout, serr = capture_sio do
            pr = proc { cp "d1", to: "foo1.txt" }
            ok {pr}.raise?(ArgumentError, "cp: foo1.txt: Not a directory.")
          end
        end
        spec "[!slavo] error when file not exist but '-f' option not specified." do
          sout, serr = capture_sio do
            pr = proc { cp "blabla", to: "d1" }
            ok {pr}.raise?(ArgumentError, "cp: blabla: file or directory not found (add '-f' option to ignore missing files).")
          end
        end
        spec "[!1ceaf] (cp) error when target file or directory already exists." do
          sout, serr = capture_sio do
            dummy_file("d1/foo1.txt", "tmp")
            pr = proc { cp "foo?.txt", to: "d1" }
            ok {pr}.raise?(ArgumentError, "cp: d1/foo1.txt: file or directory already exists (to overwrite it, call 'cp!' instead of 'cp').")
          end
        end
        #
        spec "[!bi897] error when copying directory but '-r' option not specified." do
          sout, serr = capture_sio do
            dummy_dir("d9")
            pr = proc { cp "d1", to: "d9" }
            ok {pr}.raise?(ArgumentError, "cp: d1: cannot copy directory (add '-r' option to copy it).")
          end
        end
        spec "[!654d2] copy files recursively if '-r' option specified." do
          sout, serr = capture_sio do
            dummy_dir("d9")
            ok {"d9"}.dir_exist?
            cp :r, "foo*.txt", "d1", to: "d9"
            ok {"d9/foo1.txt"}.file_exist?
            ok {"d9/foo2.txt"}.file_exist?
            ok {"d9/d1/bar.txt"}.file_exist?
            ok {"d9/d1/d2/baz.txt"}.file_exist?
          end
        end
        spec "[!i5g8r] copy files non-recursively if '-r' option not specified." do
          sout, serr = capture_sio do
            dummy_dir("d9")
            ok {"d9"}.dir_exist?
            cp "foo*.txt", "d1/**/*.txt", to: "d9"
            ok {"d9/foo1.txt"}.file_exist?
            ok {"d9/foo2.txt"}.file_exist?
            ok {"d9/bar.txt"}.file_exist?
            ok {"d9/baz.txt"}.file_exist?
          end
        end
        spec "[!k8gyx] keeps file timestamp (mtime) if '-p' option specified." do
          sout, serr = capture_sio do
            ctime1 = File.ctime("d1/bar.txt")
            mtime1 = File.mtime("d1/bar.txt")
            atime1 = File.atime("d1/bar.txt")
            #mtime2 = mtime1 - 30
            #atime2 = atime1 - 90
            mtime2 = (x = mtime1 - 900; Time.new(x.year, x.month, x.day, x.hour, x.min, x.sec))
            atime2 = (x = atime1 - 600; Time.new(x.year, x.month, x.day, x.hour, x.min, x.sec))
            File.utime(atime2, mtime2, "d1/bar.txt")
            #
            dummy_dir("d9")
            cp :p, "foo*.txt", "d1/**/*.txt", to: "d9"
            ok {File.ctime("d9/bar.txt")} != ctime1
            ok {File.mtime("d9/bar.txt")} != mtime1
            ok {File.mtime("d9/bar.txt")} == mtime2   # !!!
            ok {File.atime("d9/bar.txt")} != atime1
            ok {File.atime("d9/bar.txt")} != atime2
            #
            cp :pr, "d1", to: "d9"
            ok {File.ctime("d9/d1/bar.txt")} != ctime1
            ok {File.mtime("d9/d1/bar.txt")} != mtime1
            ok {File.mtime("d9/d1/bar.txt")} == mtime2   # !!!
            ok {File.atime("d9/d1/bar.txt")} != atime1
            ok {File.atime("d9/d1/bar.txt")} != atime2
          end
        end
        spec "[!zoun9] not keep file timestamp (mtime) if '-p' option not specified." do
          sout, serr = capture_sio do
            ctime1 = File.ctime("d1/bar.txt")
            mtime1 = File.mtime("d1/bar.txt")
            atime1 = File.atime("d1/bar.txt")
            mtime2 = mtime1 - 30
            atime2 = atime1 - 90
            File.utime(atime2, mtime2, "d1/bar.txt")
            #
            dummy_dir("d9")
            cp "foo*.txt", "d1/**/*.txt", to: "d9"
            ok {File.ctime("d9/bar.txt")} != ctime1
            ok {File.mtime("d9/bar.txt")} != mtime1
            ok {File.mtime("d9/bar.txt")} != mtime2   # !!!
            ok {File.atime("d9/bar.txt")} != atime1
            ok {File.atime("d9/bar.txt")} != atime2
            #
            cp :r, "d1", to: "d9"
            ok {File.ctime("d9/d1/bar.txt")} != ctime1
            ok {File.mtime("d9/d1/bar.txt")} != mtime1
            ok {File.mtime("d9/d1/bar.txt")} != mtime2   # !!!
            ok {File.atime("d9/d1/bar.txt")} != atime1
            ok {File.atime("d9/d1/bar.txt")} != atime2
          end
        end
        spec "[!p7ah8] creates hard link instead of copy if '-l' option specified." do
          sout, serr = capture_sio do
            cp :l, "foo*.txt", to: "d1"
            ok {File.identical?("foo1.txt", "d1/foo1.txt")} == true
            ok {File.identical?("foo2.txt", "d1/foo2.txt")} == true
          end
        end
        spec "[!e90ii] error when copying supecial files such as character device." do
          sout, serr = capture_sio do
            pr = proc { cp "/dev/null", to: "d1" }
            ok {pr}.raise?(ArgumentError, "cp: /dev/null: cannot copy characterSpecial file.")
          end
        end
      end

    end


    topic 'cp!()' do
      spec "[!cpr7l] (cp!) overwrites existing destination file." do
        sout, serr = capture_sio do
          dummy_file("foo9.txt", "")
          ok {"foo9.txt"}.file_exist?
          cp! "foo1.txt", "foo9.txt"
          ok {"foo9.txt"}.file_exist?
          ok {File.read("foo9.txt")} == File.read("foo1.txt")
          #
          pr = proc { cp "foo1.txt", "foo9.txt" }
          ok {pr}.raise?(ArgumentError, "cp: foo9.txt: file already exists (to overwrite it, call `cp!` instead of `cp`).")
        end
      end
      spec "[!melhx] (cp!) overwrites existing files." do
        sout, serr = capture_sio do
          dummy_dir("d9")
          dummy_file("d9/foo1.txt", "")
          ok {"d9/foo1.txt"}.file_exist?
          cp! "foo1.txt", to: "d9"
          ok {"d9/foo1.txt"}.file_exist?
          ok {File.read("d9/foo1.txt")} == File.read("foo1.txt")
          #
          pr = proc { cp "foo1.txt", to: "d9" }
          ok {pr}.raise?(ArgumentError, "cp: d9/foo1.txt: file or directory already exists (to overwrite it, call 'cp!' instead of 'cp').")
        end
      end
    end


    topic 'mv()' do

      spec "[!ajm59] echoback command and arguments." do
        sout, serr = capture_sio do
          mv "foo1.txt", "foo9.txt"
          mv "foo2.txt", to: "d1"
        end
        ok {sout} == ("$ mv foo1.txt foo9.txt\n"\
                      "$ mv foo2.txt d1\n")
      end

      case_when "[!g732t] when `to:` keyword argument not specified..." do
        spec "[!0f106] error when number of arguments is not 2." do
          sout, serr = capture_sio do
            pr = proc { mv() }
            ok {pr}.raise?(ArgumentError, "mv: requires two arguments.")
            pr = proc { mv "foo1.txt" }
            ok {pr}.raise?(ArgumentError, "mv: requires two arguments.")
            pr = proc { mv "foo1.txt", "foo2.txt", "foo3.txt" }
            ok {pr}.raise?(ArgumentError, "mv: too much arguments.")
          end
        end
        spec "[!xsti2] error when source pattern matched to multiple files." do
          sout, serr = capture_sio do
            pr = proc { mv "foo?.txt", "blabla.txt" }
            ok {pr}.raise?(ArgumentError, "mv: foo?.txt: unexpectedly matched to multiple files (foo1.txt, foo2.txt).")
          end
        end
        spec "[!4wam3] error when destination pattern matched to multiple files." do
          sout, serr = capture_sio do
            pr = proc { mv "d1/bar.txt", "foo*.txt" }
            ok {pr}.raise?(ArgumentError, "mv: foo*.txt: unexpectedly matched to multiple files (foo1.txt, foo2.txt).")
          end
        end
        #
        spec "[!ude1j] cannot move file into existing directory." do
          sout, serr = capture_sio do
            pr = proc { mv "foo1.txt", "d1" }
            ok {pr}.raise?(ArgumentError, "mv: cannot move file 'foo1.txt' into directory 'd1' without 'to:' keyword option.")
          end
        end
        spec "[!2aws0] cannt rename directory into existing file or directory." do
          sout, serr = capture_sio do
            pr = proc { mv "d1", "foo1.txt" }
            ok {pr}.raise?(ArgumentError, "mv: cannot rename directory 'd1' to existing file or directory.")
          end
        end
        spec "[!3fbpu] (mv) error when destination file already exists." do
          sout, serr = capture_sio do
            pr = proc { mv "foo1.txt", "foo2.txt" }
            ok {pr}.raise?(ArgumentError, "mv: foo2.txt: already exists (to overwrite it, call `mv!` instead of `mv`).")
          end
        end
        spec "[!397kn] do nothing when file or directory not found but '-f' option specified." do
          sout, serr = capture_sio do
            mv :f, "blabla.txt", "blabla2.txt"
            ok {"blabla2.txt"}.not_exist?
          end
        end
        spec "[!1z89i] error when source file or directory not found." do
          sout, serr = capture_sio do
            pr = proc { mv "blabla.txt", "blabla2.txt" }
            ok {pr}.raise?(ArgumentError, "mv: blabla.txt: not found.")
          end
        end
        spec "[!9eqt3] rename file or directory." do
          sout, serr = capture_sio do
            s = File.read("foo1.txt")
            mv "foo1.txt", "blabla.txt"
            ok {"foo1.txt"}.not_exist?
            ok {"blabla.txt"}.file_exist?
            ok {File.read("blabla.txt")} == s
            #
            mv "d1", "d9"
            ok {"d1"}.not_exist?
            ok {"d9"}.dir_exist?
          end
        end
      end

      case_else "[!iu87y] when `to:` keyword argument specified..." do
        spec "[!wf6pc] error when destination directory not exist." do
          sout, serr = capture_sio do
            pr = proc { mv "foo?.txt", to: "dir9" }
            ok {pr}.raise?(ArgumentError, "mv: dir9: directory not found.")
          end
        end
        spec "[!8v4dn] error when destination pattern matched to multiple filenames." do
          sout, serr = capture_sio do
            pr = proc { mv "d1", to: "foo?.txt" }
            ok {pr}.raise?(ArgumentError, "mv: foo?.txt: unexpectedly matched to multiple filenames (foo1.txt, foo2.txt).")
          end
        end
        spec "[!ppr6n] error when destination is not a directory." do
          sout, serr = capture_sio do
            pr = proc { mv "d1", to: "foo1.txt" }
            ok {pr}.raise?(ArgumentError, "mv: foo1.txt: Not a directory.")
          end
        end
        spec "[!bjqwi] error when file not exist but '-f' option not specified." do
          sout, serr = capture_sio do
            pr = proc { mv "blabla", to: "d1" }
            ok {pr}.raise?(ArgumentError, "mv: blabla: file or directory not found (add '-f' option to ignore missing files).")
          end
        end
        spec "[!k21ns] (mv) error when target file or directory already exists." do
          sout, serr = capture_sio do
            dummy_file("d1/foo1.txt", "tmp")
            pr = proc { mv "foo?.txt", to: "d1" }
            ok {pr}.raise?(ArgumentError, "mv: d1/foo1.txt: file or directory already exists (to overwrite it, call 'mv!' instead of 'mv').")
          end
        end
        #
        spec "[!ri2ia] move files into existing directory." do
          sout, serr = capture_sio do
            mv "foo?.txt", to: "d1/d2"
            ok {"foo1.txt"}.not_exist?
            ok {"foo2.txt"}.not_exist?
            ok {"d1/d2/foo1.txt"}.file_exist?
            ok {"d1/d2/foo2.txt"}.file_exist?
          end
        end
      end

    end


    topic 'mv!()' do
      spec "[!zpojx] (mv!) overwrites existing files." do
        sout, serr = capture_sio do
          pr = proc { mv "foo1.txt", "foo2.txt" }
          ok {pr}.raise?(ArgumentError, "mv: foo2.txt: already exists (to overwrite it, call `mv!` instead of `mv`).")
          #
          s = File.read("foo2.txt")
          mv! "foo1.txt", "foo2.txt"
          ok {"foo1.txt"}.not_exist?
          ok {"foo2.txt"}.file_exist?
          ok {File.read("foo2.txt")} != s
        end
      end
      spec "[!vcaf5] (mv!) overwrites existing files." do
        sout, serr = capture_sio do
          mv "foo1.txt", to: "d1"
          ok {"d1/foo1.txt"}.file_exist?
          #
          mv "d1/foo1.txt", "d1/foo2.txt"
          pr = proc { mv "foo2.txt", to: "d1" }
          ok {pr}.raise?(ArgumentError, "mv: d1/foo2.txt: file or directory already exists (to overwrite it, call 'mv!' instead of 'mv').")
        end
      end
    end


    topic 'rm()' do
      spec "[!bikrs] echoback command and arguments." do
        sout, serr = capture_sio do
          rm "foo*.txt"
        end
        ok {sout} == "$ rm foo*.txt\n"
      end
      spec "[!va1j0] error when file not exist but '-f' option not specified." do
        sout, serr = capture_sio do
          pr = proc { rm "foo*.txt", "blabla*.txt" }
          ok {pr}.raise?(ArgumentError, "rm: blabla*.txt: file or directory not found (add '-f' option to ignore missing files).")
          ok {"foo1.txt"}.file_exist?
          #
        end
      end
      spec "[!t6vhx] ignores missing files if '-f' option specified." do
        sout, serr = capture_sio do
          rm :f, "foo*.txt", "blabla*.txt"
          ok {"foo1.txt"}.not_exist?
        end
      end
      spec "[!o92yi] cannot remove directory unless '-r' option specified." do
        sout, serr = capture_sio do
          pr = proc { rm "d1" }
          ok {pr}.raise?(ArgumentError, "rm: d1: cannot remove directory (add '-r' option to remove it).")
        end
      end
      spec "[!srx8w] remove directories recursively if '-r' option specified." do
        sout, serr = capture_sio do
          ok {"d1"}.dir_exist?
          rm :r, "d1"
          ok {"d1"}.not_exist?
        end
      end
      spec "[!mdgjc] remove files if '-r' option not specified." do
        sout, serr = capture_sio do
          rm "foo*.txt"
          ok {"foo1.txt"}.not_exist?
          ok {"foo2.txt"}.not_exist?
        end
      end
    end


    topic 'mkdir()' do
      spec "[!wd7rm] error when mode is invalid." do
        sout, serr = capture_sio do
          pr = proc { mkdir :m, "a+x" }
          ok {pr}.raise?(ArgumentError, "mkdir: a+x: '-m' option doesn't support this style mode (use '0755' tyle instead).")
          #
          pr = proc { mkdir :m, "+x" }
          ok {pr}.raise?(ArgumentError, "mkdir: +x: invalid mode.")
        end
      end
      spec "[!xusor] raises error when argument not specified." do
        sout, serr = capture_sio do
          pr = proc { mkdir() }
          ok {pr}.raise?(ArgumentError, "mkdir: argument required.")
        end
      end
      spec "[!51pmg] error when directory already exists but '-p' option not specified." do
        sout, serr = capture_sio do
          pr = proc { mkdir "d1" }
          ok {pr}.raise?(ArgumentError, "mkdir: d1: directory already exists.")
        end
      end
      spec "[!pydy1] ignores existing directories if '-p' option specified." do
        sout, serr = capture_sio do
          ok {"d1"}.dir_exist?
          mkdir :p, "d1"
          ok {"d1"}.dir_exist?
        end
      end
      spec "[!om8a6] error when file already exists." do
        sout, serr = capture_sio do
          pr = proc { mkdir "foo1.txt" }
          ok {pr}.raise?(ArgumentError, "mkdir: foo1.txt: file exists.")
        end
      end
      spec "[!xx7mv] error when parent directory not exist but '-p' option not specified." do
        sout, serr = capture_sio do
          pr = proc { mkdir "d1/a/b" }
          ok {pr}.raise?(ArgumentError, "mkdir: d1/a/b: parent directory not exists (add '-p' to create it).")
        end
      end
      spec "[!jc8hm] '-m' option specifies mode of new directories." do
        sout, serr = capture_sio do
          ok {"d9"}.not_exist?
          mkdir :m, 0750, "d9"
          ok {"d9"}.dir_exist?
          ok {File.stat("d9").mode & 0777} == 0750
          #
          mkdir :pm, 0705, "d9/a/b"
          ok {"d9/a/b"}.dir_exist?
          ok {File.stat("d9/a/b").mode & 0777} == 0705
        end
      end
      spec "[!0zeu3] create intermediate path if '-p' option specified." do
        sout, serr = capture_sio do
          ok {"d1/a/b"}.not_exist?
          mkdir :p, "d1/a/b"
          ok {"d1/a/b"}.dir_exist?
          #
          ok {"d9/a/b"}.not_exist?
          mkdir :p, "d9/a/b"
          ok {"d9/a/b"}.dir_exist?
        end
      end
      spec "[!l0pr8] create directories if '-p' option not specified." do
        sout, serr = capture_sio do
          mkdir :p, "aa", "bb", "cc"
          ok {"aa"}.dir_exist?
          ok {"bb"}.dir_exist?
          ok {"cc"}.dir_exist?
        end
      end
    end


    topic 'rmdir()' do
      spec "[!bqhdd] error when argument not specified." do
        sout, serr = capture_sio do
          pr = proc { rmdir() }
          ok {pr}.raise?(ArgumentError, "rmdir: argument required.")
        end
      end
      spec "[!o1k3g] error when directory not exist." do
        sout, serr = capture_sio do
          pr = proc { rmdir "d9" }
          ok {pr}.raise?(ArgumentError, "rmdir: d9: No such file or directory.")
        end
      end
      spec "[!ch5rq] error when directory is a symbolic link." do
        sout, serr = capture_sio do
          File.symlink("foo1.txt", "foo1.lnk")
          pr = proc { rmdir "foo1.lnk" }
          ok {pr}.raise?(ArgumentError, "rmdir: foo1.lnk: Not a directory.")
        end
      end
      spec "[!igfti] error when directory is not empty." do
        sout, serr = capture_sio do
          pr = proc { rmdir "d1" }
          #ok {pr}.raise?(Errno::ENOTEMPTY, "Directory not empty @ dir_s_rmdir - d9")
          ok {pr}.raise?(ArgumentError, "rmdir: d1: Directory not empty.")
        end
      end
      spec "[!qnnqy] error when argument is not a directory." do
        sout, serr = capture_sio do
          pr = proc { rmdir "foo1.txt" }
          ok {pr}.raise?(ArgumentError, "rmdir: foo1.txt: Not a directory.")
        end
      end
      spec "[!jgmw7] remove empty directories." do
        sout, serr = capture_sio do
          dummy_dir "d9/a/b"
          ok {"d9/a/b"}.dir_exist?
          rmdir "d9/a/b"
          ok {"d9/a/b"}.not_exist?
          rmdir "d9/a"
          ok {"d9/a"}.not_exist?
        end
      end
    end


    topic 'ln()' do
      spec "[!ycp6e] echobacks command and arguments." do
        sout, serr = capture_sio do
          ln "foo1.txt", "foo8.txt"
          ln :s, "foo2.txt", "foo9.txt"
        end
        ok {sout} == ("$ ln -n foo1.txt foo8.txt\n"\
                      "$ ln -sn foo2.txt foo9.txt\n")
      end
      spec "[!umk6m] keyword arg `to: xx` is echobacked as `-t xx`." do
        sout, serr = capture_sio do
          ln "foo*.txt", to: "d1"
        end
        ok {sout} == ("$ ln -t d1 -n foo*.txt\n")
      end

      case_when "[!qtbp4] when `to:` keyword argument not specified..." do
        spec "[!n1zpi] error when number of arguments is not 2." do
          sout, serr = capture_sio do
            pr = proc { ln() }
            ok {pr}.raise?(ArgumentError, "ln: requires two arguments.")
            pr = proc { ln "foo1.txt" }
            ok {pr}.raise?(ArgumentError, "ln: requires two arguments.")
          end
        end
        spec "[!2rxqo] error when source pattern matched to multiple files." do
          sout, serr = capture_sio do
            pr = proc { ln "foo*.txt", "bar.txt" }
            ok {pr}.raise?(ArgumentError, "ln: foo*.txt: unexpectedly matched to multiple files (foo1.txt, foo2.txt).")
          end
        end
        spec "[!ysxdq] error when destination pattern matched to multiple files." do
          sout, serr = capture_sio do
            pr = proc { ln "d9/bar.txt", "foo*.txt" }
            ok {pr}.raise?(ArgumentError, "ln: foo*.txt: unexpectedly matched to multiple files (foo1.txt, foo2.txt).")
          end
        end
        #
        spec "[!4ry8j] (hard link) error when source file not exists." do
          sout, serr = capture_sio do
            pr = proc { ln "foo8.txt", "foo9.txt" }
            ok {pr}.raise?(ArgumentError, "ln: foo8.txt: No such file or directory.")
          end
        end
        spec "[!tf29w] (hard link) error when source is a directory." do
          sout, serr = capture_sio do
            pr = proc { ln "d1", "d2" }
            ok {pr}.raise?(ArgumentError, "ln: d1: Is a directory.")
          end
        end
        spec "[!zmijh] error when destination is a directory without `to:` keyword argument." do
          sout, serr = capture_sio do
            pr = proc { ln "foo1.txt", "d1" }
            ok {pr}.raise?(ArgumentError, "ln: d1: cannot create link under directory without `to:` keyword option.")
          end
        end
        spec "[!nzci0] (ln) error when destination already exists." do
          sout, serr = capture_sio do
            pr = proc { ln "foo1.txt", "d1" }
            ok {pr}.raise?(ArgumentError, "ln: d1: cannot create link under directory without `to:` keyword option.")
            pr = proc { ln :s, "foo1.txt", "d1" }
            ok {pr}.raise?(ArgumentError, "ln: d1: cannot create link under directory without `to:` keyword option.")
          end
        end
        spec "[!oxjqv] create symbolic link if '-s' option specified." do
          sout, serr = capture_sio do
            ln :s, "foo1.txt", "foo9.txt"
            ok {"foo9.txt"}.file_exist?
            ok {"foo9.txt"}.symlink_exist?
            ln :s, "d1", "d9"
            ok {"d9"}.dir_exist?
            ok {"d9"}.symlink_exist?
          end
        end
        spec "[!awig1] (symlink) can create symbolic link to non-existing file." do
          sout, serr = capture_sio do
            ok {"foo8.txt"}.not_exist?
            ln :s, "foo8.txt", "foo9.txt"
            ok {"foo9.txt"}.symlink_exist?
          end
        end
        spec "[!5kl3w] (symlink) can create symbolic link to directory." do
          sout, serr = capture_sio do
            ln :s, "d1", "d9"
            ok {"d9"}.symlink_exist?
          end
        end
        spec "[!sb29p] create hard link if '-s' option not specified." do
          sout, serr = capture_sio do
            ln "foo1.txt", "foo9.txt"
            ok {"foo9.txt"}.file_exist?
            ok {"foo9.txt"}.NOT.symlink_exist?
          end
        end
      end

      case_else "[!5x2wr] when `to:` keyword argument specified..." do
        spec "[!5gfxk] error when destination directory not exist." do
          sout, serr = capture_sio do
            pr =  proc { ln "foo*.txt", to: "d9" }
            ok {pr}.raise?(ArgumentError, "ln: d9: directory not found.")
          end
        end
        spec "[!euu5d] error when destination pattern matched to multiple filenames." do
          sout, serr = capture_sio do
            pr = proc { ln "d1/bar.txt", to: "foo*.txt" }
            ok {pr}.raise?(ArgumentError, "ln: foo*.txt: unexpectedly matched to multiple filenames (foo1.txt, foo2.txt).")
          end
        end
        spec "[!42nb7] error when destination is not a directory." do
          sout, serr = capture_sio do
            pr = proc { ln "foo1.txt", to: "foo2.txt" }
            ok {pr}.raise?(ArgumentError, "ln: foo2.txt: Not a directory.")
          end
        end
        #
        spec "[!x7wh5] (symlink) can create symlink to unexisting file." do
          sout, serr = capture_sio do
            ln :s, "foo8.txt", to: "d1"
            ok {"d1/foo8.txt"}.not_exist?
            ok {"d1/foo8.txt"}.symlink_exist?
          end
        end
        spec "[!ml1vm] (hard link) error when source file not exist." do
          sout, serr = capture_sio do
            pr = proc { ln "foo8.txt", to: "d1" }
            ok {pr}.raise?(ArgumentError, "ln: foo8.txt: No such file or directory.")
          end
        end
        #
        spec "[!mwukw] (ln) error when target file or directory already exists." do
          sout, serr = capture_sio do
            dummy_file("d1/foo1.txt", "foo1")
            pr = proc { ln "foo*.txt", to: "d1" }       # hard link
            ok {pr}.raise?(ArgumentError, "ln: d1/foo1.txt: File exists (to overwrite it, call `ln!` instead of `ln`).")
            #
            pr = proc { ln :s, "foo*.txt", to: "d1" }   # symbolic link
            ok {pr}.raise?(ArgumentError, "ln: d1/foo1.txt: File exists (to overwrite it, call `ln!` instead of `ln`).")
          end
        end
        spec "[!c8hpp] (hard link) create hard link under directory if '-s' option not specified." do
          sout, serr = capture_sio do
            ln "foo*.txt", to: "d1"
            ok {"d1/foo1.txt"}.file_exist?
            ok {"d1/foo2.txt"}.file_exist?
            ok {"d1/foo1.txt"}.NOT.symlink_exist?
            ok {"d1/foo2.txt"}.NOT.symlink_exist?
          end
        end
        spec "[!9tv9g] (symlik) create symbolic link under directory if '-s' option specified." do
          sout, serr = capture_sio do
            ln :s, "foo*.txt", to: "d1"
            ok {"d1/foo1.txt"}.symlink_exist?
            ok {"d1/foo2.txt"}.symlink_exist?
            ok {"d1/foo1.txt"}.NOT.file_exist?
            ok {"d1/foo2.txt"}.NOT.file_exist?
          end
        end
      end
    end


    topic 'ln!()' do
      spec "[!dkqgq] (ln!) overwrites existing destination file." do
        sout, serr = capture_sio do
          ln :s, "foo1.txt", "foo9.txt"
          ok {"foo9.txt"}.symlink_exist?
          #
          pr = proc { ln :s, "foo2.txt", "foo9.txt" }   # ln, symbolic link
          ok {pr}.raise?(ArgumentError, "ln: foo9.txt: File exists (to overwrite it, call `ln!` instead of `ln`).")
          ln! :s, "foo1.txt", "foo9.txt"                # ln!, symbolic link
          ok {"foo9.txt"}.symlink_exist?
          ok {File.readlink("foo9.txt")} == "foo1.txt"
          #
          pr = proc { ln "foo2.txt", "foo9.txt" }       # ln, hard link
          ok {pr}.raise?(ArgumentError, "ln: foo9.txt: File exists (to overwrite it, call `ln!` instead of `ln`).")
          ln! "foo2.txt", "foo9.txt"                    # ln!, hard link
          ok {"foo9.txt"}.file_exist?
          ok {"foo9.txt"}.NOT.symlink_exist?
        end
      end
      spec "[!c3vwn] (ln!) error when target file is a directory." do
        sout, serr = capture_sio do
          dummy_dir("d1/foo1.txt")
          pr = proc { ln! "foo1.txt", to: "d1" }      # hard link
          ok {pr}.raise?(ArgumentError, "ln!: d1/foo1.txt: directory already exists.")
          #
          pr = proc { ln! :s, "foo1.txt", to: "d1" }  # symbolic link
          ok {pr}.raise?(ArgumentError, "ln!: d1/foo1.txt: directory already exists.")
        end
      end
      spec "[!bfcki] (ln!) overwrites existing symbolic links." do
        sout, serr = capture_sio do
          ln :s, "d1/bar.txt", "d1/foo1.txt"
          ln :s, "d1/bar.txt", "d1/foo2.txt"
          ok {"d1/foo1.txt"}.symlink_exist?
          ok {"d1/foo2.txt"}.symlink_exist?
          #
          pr = proc { ln "foo1.txt", to: "d1" }
          ok {pr}.raise?(ArgumentError, "ln: d1/foo1.txt: symbolic link already exists (to overwrite it, call `ln!` instead of `ln`).")
          ln! "foo1.txt", to: "d1"           # hard link
          ok {"d1/foo1.txt"}.file_exist?
          ok {"d1/foo1.txt"}.NOT.symlink_exist?
          #
          pr = proc { ln :s, "foo2.txt", to: "d1" }
          ok {pr}.raise?(ArgumentError, "ln: d1/foo2.txt: symbolic link already exists (to overwrite it, call `ln!` instead of `ln`).")
          ln! :s, "foo2.txt", to: "d1"       # symbolic link
          ok {"d1/foo2.txt"}.symlink_exist?
          ok {"d1/foo2.txt"}.NOT.file_exist?
        end
      end
      spec "[!ipy2c] (ln!) overwrites existing files." do
        dummy_file "d1/foo1.txt"
        dummy_file "d1/foo2.txt"
        sout, serr = capture_sio do
          ## hard link
          pr = proc { ln "foo1.txt", to: "d1" }
          ok {pr}.raise?(ArgumentError, "ln: d1/foo1.txt: File exists (to overwrite it, call `ln!` instead of `ln`).")
          ln! "foo1.txt", to: "d1"
          ok {"d1/foo1.txt"}.file_exist?
          ok {"d1/foo1.txt"}.NOT.symlink_exist?
          ## symbolic link
          pr = proc { ln :s, "foo2.txt", to: "d1" }
          ok {pr}.raise?(ArgumentError, "ln: d1/foo2.txt: File exists (to overwrite it, call `ln!` instead of `ln`).")
          ln! :s, "foo2.txt", to: "d1"       # symbolic link
          ok {"d1/foo2.txt"}.symlink_exist?
          ok {"d1/foo2.txt"}.NOT.file_exist?
        end
      end
    end

    topic 'atomic_symlink!()' do
      spec "[!gzp4a] creates temporal symlink and rename it when symlink already exists." do
        File.symlink("foo1.txt", "tmp.link")
        sout, serr = capture_sio do
          atomic_symlink! "foo2.txt", "tmp.link"
        end
        ok {File.readlink("tmp.link")} == "foo2.txt"
        ok {sout} =~ /\A\$ ln -s foo2\.txt foo2\.txt\.\d+ \&\& mv -Tf foo2\.txt\.\d+ tmp.link\n\z/
      end
      spec "[!h75kp] error when destination is normal file or directory." do
        sout, serr = capture_sio do
          pr = proc { atomic_symlink! "foo1.txt", "foo2.txt" }
          ok {pr}.raise?(ArgumentError, "atomic_symlink!: foo2.txt: not a symbolic link.")
          pr = proc { atomic_symlink! "foo1.txt", "d1" }
          ok {pr}.raise?(ArgumentError, "atomic_symlink!: d1: not a symbolic link.")
        end
      end
      spec "[!pjcmn] just creates new symbolic link when destination not exist." do
        sout, serr = capture_sio do
          ok {"tmp.link"}.NOT.symlink_exist?
          atomic_symlink! "foo1.txt", "tmp.link"
          ok {"tmp.link"}.symlink_exist?
        end
        ok {sout} == "$ ln -s foo1.txt tmp.link\n"
      end
    end


    topic 'pwd()' do
      spec "[!aelx6] echoback command and arguments." do
        here = Dir.pwd()
        sout, serr = capture_sio do
          pwd()
        end
        ok {sout} == ("$ pwd\n"\
                      "#{here}\n")
      end
      spec "[!kh3l2] prints current directory path."do
        here = Dir.pwd()
        sout, serr = capture_sio do
          pwd()
        end
        ok {sout} == ("$ pwd\n"\
                      "#{here}\n")
      end
    end


    topic 'touch()' do
      fixture :ts do
        ts = Time.new(2000, 1, 1, 0, 0, 0)
        File.utime(ts, ts, "foo1.txt")
        File.utime(ts, ts, "foo2.txt")
        #File.utime(ts, ts, "d1/bar.txt")
        ts
      end
      #
      spec "[!ifxob] echobacks command and arguments." do
        sout, serr = capture_sio do
          touch "foo1.txt", "foo2.txt"
        end
        ok {sout} == "$ touch foo1.txt foo2.txt\n"
      end
      spec "[!c7e51] error when reference file not exist." do
        sout, serr = capture_sio do
          pr = proc { touch :r, "foo9.txt", "foo1.txt" }
          ok {pr}.raise?(ArgumentError, "touch: foo9.txt: not exist.")
        end
      end
      spec "[!pggnv] changes both access time and modification time in default." do |ts|
        sout, serr = capture_sio do
          ok {File.atime("foo1.txt")} == ts
          ok {File.mtime("foo1.txt")} == ts
          #
          now1 = Time.now
          touch "foo1.txt"
          now2 = Time.now
          ok {File.atime("foo1.txt")}.between?(now1, now2)
          ok {File.mtime("foo1.txt")}.between?(now1, now2)
        end
      end
      spec "[!o9h74] expands file name pattern." do |ts|
        sout, serr = capture_sio do
          ok {File.atime("foo1.txt")} == ts
          ok {File.mtime("foo1.txt")} == ts
          ok {File.atime("foo2.txt")} == ts
          ok {File.mtime("foo2.txt")} == ts
          #
          now1 = Time.now
          touch "foo*.txt"
          now2 = Time.now
          ok {File.atime("foo1.txt")}.between?(now1, now2)
          ok {File.mtime("foo1.txt")}.between?(now1, now2)
          ok {File.atime("foo2.txt")}.between?(now1, now2)
          ok {File.mtime("foo2.txt")}.between?(now1, now2)
        end
      end
      spec "[!9ahsu] changes timestamp of files to current datetime." do |ts|
        sout, serr = capture_sio do
          ok {File.atime("foo1.txt")} == ts
          ok {File.mtime("foo1.txt")} == ts
          #
          now1 = Time.now
          touch "foo1.txt"
          now2 = Time.now
          ok {File.atime("foo1.txt")}.between?(now1, now2)
          ok {File.mtime("foo1.txt")}.between?(now1, now2)
        end
      end
      spec "[!wo080] if reference file specified, use it's timestamp." do |ts|
        sout, serr = capture_sio do
          ok {File.atime("foo1.txt")} == ts
          ok {File.mtime("foo1.txt")} == ts
          touch :r, "foo1.txt", "d1/bar.txt"
          ok {File.atime("d1/bar.txt")} == ts
          ok {File.mtime("d1/bar.txt")} == ts
        end
      end
      spec "[!726rq] creates empty file if file not found and '-c' option not specified." do |ts|
        sout, serr = capture_sio do
          ok {"foo9.txt"}.not_exist?
          touch "foo9.txt"
          ok {"foo9.txt"}.file_exist?
        end
      end
      spec "[!cfc40] skips non-existing files if '-c' option specified." do
        sout, serr = capture_sio do
          ok {"foo9.txt"}.not_exist?
          touch :c, "foo9.txt"
          ok {"foo9.txt"}.not_exist?
        end
      end
      spec "[!s50bp] changes only access timestamp if '-a' option specified." do |ts|
        sout, serr = capture_sio do
          ok {File.atime("foo1.txt")} == ts
          ok {File.mtime("foo1.txt")} == ts
          now1 = Time.now
          touch :a, "foo1.txt"
          now2 = Time.now
          ok {File.atime("foo1.txt")}.between?(now1, now2)
          ok {File.mtime("foo1.txt")} == ts
        end
      end
      spec "[!k7zap] changes only modification timestamp if '-m' option specified." do |ts|
        sout, serr = capture_sio do
          ok {File.atime("foo1.txt")} == ts
          ok {File.mtime("foo1.txt")} == ts
          now1 = Time.now
          touch :m, "foo1.txt"
          now2 = Time.now
          ok {File.atime("foo1.txt")} == ts
          ok {File.mtime("foo1.txt")}.between?(now1, now2)
        end
      end
      spec "[!b5c1n] changes both access and modification timestamps in default." do |ts|
        sout, serr = capture_sio do
          ok {File.atime("foo1.txt")} == ts
          ok {File.mtime("foo1.txt")} == ts
          now1 = Time.now
          touch "foo1.txt"
          now2 = Time.now
          ok {File.atime("foo1.txt")} != ts
          ok {File.mtime("foo1.txt")} != ts
          ok {File.atime("foo1.txt")}.between?(now1, now2)
          ok {File.mtime("foo1.txt")}.between?(now1, now2)
        end
      end
    end


    topic 'chmod()' do
      spec "[!pmmvj] echobacks command and arguments." do
        sout, serr = capture_sio do
          chmod "644", "foo1.txt", "foo2.txt"
        end
        ok {sout} == "$ chmod 644 foo1.txt foo2.txt\n"
      end
      spec "[!94hl9] error when mode not specified." do
        sout, serr = capture_sio do
          pr = proc { chmod() }
          ok {pr}.raise?(ArgumentError, "chmod: argument required.")
        end
      end
      spec "[!c8zhu] mode can be integer or octal string." do
        sout, serr = capture_sio do
          mode_i, mask = __chmod("chmod", [0644, "foo1.txt"], true)
          ok {mode_i} == 0644
          ok {mask} == nil
          mode_i, mask = __chmod("chmod", ["644", "foo1.txt"], true)
          ok {mode_i} == 0644
          ok {mask} == nil
        end
      end
      spec "[!j3nqp] error when integer mode is invalid." do
        sout, serr = capture_sio do
          pr = proc { chmod 888, "foo1.txt" }
          ok {pr}.raise?(ArgumentError, "chmod: 888: Invalid file mode.")
        end
      end
      spec "[!ox3le] converts 'u+r' style mode into mask." do
        sout, serr = capture_sio do
          [
            ["u+r", 0400], ["u+w", 0200], ["u+x", 0100], ["u+s", 04000], ["u+t", 00000],
            ["g+r", 0040], ["g+w", 0020], ["g+x", 0010], ["g+s", 02000], ["g+t", 00000],
            ["o+r", 0004], ["o+w", 0002], ["o+x", 0001], ["o+s", 00000], ["o+t", 00000],
            ["a+r", 0444], ["a+w", 0222], ["a+x", 0111], ["a+s", 06000], ["a+t", 01000],
          ].each do |mode, expected|
            mode_i, mask = __chmod("chmod", [mode, "foo1.txt"], true)
            ok {mode_i} == nil
            ok {mask} == expected
          end
        end
      end
      spec "[!axqed] error when mode is invalid." do
        sout, serr = capture_sio do
          pr = proc { chmod "888", "foo1.txt" }
          ok {pr}.raise?(ArgumentError, "chmod: 888: Invalid file mode.")
          pr = proc { chmod "+r", "foo1.txt" }
          ok {pr}.raise?(ArgumentError, "chmod: +r: Invalid file mode.")
        end
      end
      spec "[!ru371] expands file pattern." do
        sout, serr = capture_sio do
          ok {File.readable?("foo1.txt")} == true
          ok {File.readable?("foo2.txt")} == true
          chmod "u-r", "foo*.txt"
          ok {File.readable?("foo1.txt")} == false
          ok {File.readable?("foo2.txt")} == false
        end
      end
      spec "[!ou3ih] error when file not exist." do
        sout, serr = capture_sio do
          pr = proc { chmod "u+r", "blabla" }
          ok {pr}.raise?(ArgumentError, "chmod: blabla: No such file or directory.")
        end
      end
      spec "[!8sd4b] error when file pattern not matched to anything." do
        sout, serr = capture_sio do
          pr = proc { chmod "u+r", "foobar*.txt" }
          ok {pr}.raise?(ArgumentError, "chmod: foobar*.txt: No such file or directory.")
        end
      end
      spec "[!q1psx] changes file mode." do
        sout, serr = capture_sio do
          mode1 = File.stat("foo1.txt").mode
          chmod "432", "foo1.txt"
          mode2 = File.stat("foo1.txt").mode
          ok {mode2} != mode1
          ok {mode2 & 0777} == 0432
          #
          chmod "u+w", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 0777} == 0632
          chmod "g-x", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 0777} == 0622
          chmod "a+x", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 0777} == 0733
          #
          chmod "u+s", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 07777} == 04733
          chmod "g+s", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 07777} == 06733
          chmod "a-s", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 07777} == 00733
          chmod "o+s", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 07777} == 00733
          #
          chmod "u+t", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 07777} == 00733
          chmod "g+t", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 07777} == 00733
          chmod "o+t", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 07777} == 00733
          chmod "a+t", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 07777} == 01733
          chmod "a-t", "foo1.txt"
          ok {File.stat("foo1.txt").mode & 07777} == 00733
        end
      end
      spec "[!4en6n] skips symbolic links." do
        sout, serr = capture_sio do
          File.symlink("foo1.txt", "foo1.link")
          mode = File.stat("foo1.txt").mode
          chmod 0765, "foo1.link"
          ok {File.stat("foo1.txt").mode} == mode
          ok {File.stat("foo1.txt").mode | 0777} != 0765
        end
      end
      spec "[!4e7ve] changes mode recursively if '-R' option specified." do
        sout, serr = capture_sio do
          chmod :R, 0775, "d1"
          ok {File.stat("d1"           ).mode & 0777} == 0775
          ok {File.stat("d1/bar.txt"   ).mode & 0777} == 0775
          ok {File.stat("d1/d2/baz.txt").mode & 0777} == 0775
        end
      end
    end


    topic 'chown()' do
      fixture :usr do
        ENV['USER']     # TODO
      end
      fixture :grp do
        "staff"         # TODO
      end
      fixture :uid do |usr|
        Etc.getpwnam(usr).uid
      end
      fixture :gid do |grp|
        Etc.getgrnam(grp).gid
      end
      #
      spec "[!5jqqv] echobacks command and arguments." do |usr, grp|
        sout, serr = capture_sio do
          chown "#{usr}:#{grp}", "foo*.txt"
        end
        ok {sout} == "$ chown #{usr}:#{grp} foo*.txt\n"
      end
      spec "[!hkxgu] error when owner not specified." do
        sout, serr = capture_sio do
          pr = proc { chown() }
          ok {pr}.raise?(ArgumentError, "chown: argument required.")
        end
      end
      spec "[!0a35v] accepts integer as user id." do |usr, uid|
        sout, serr = capture_sio do
          ok {uid}.is_a?(Integer)
          chown uid, "foo*.txt"
          ok {File.stat("foo1.txt").uid} == uid
        end
      end
      spec "[!b5qud] accepts 'user:group' argument." do |usr, grp, uid, gid|
        sout, serr = capture_sio do
          chown "#{usr}:#{grp}", "foo*.txt"
          ok {File.stat("foo1.txt").uid} == uid
          ok {File.stat("foo1.txt").gid} == gid
        end
      end
      spec "[!18gf0] accepts 'user' argument." do |usr, grp, uid|
        sout, serr = capture_sio do
          chown usr, "foo*.txt"
          ok {File.stat("foo1.txt").uid} == uid
          #
          chown usr+":", "foo*.txt"
          ok {File.stat("foo1.txt").uid} == uid
        end
      end
      spec "[!mw5tg] accepts ':group' argument." do |usr, grp, gid|
        sout, serr = capture_sio do
          chown ":#{grp}", "foo*.txt"
          ok {File.stat("foo1.txt").gid} == gid
        end
      end
      spec "[!jyecc] converts user name into user id." do |usr, grp, uid|
        sout, serr = capture_sio do
          uid, gid = __chown("chown", [usr, "foo*.txt"], true)
          ok {uid} == uid
        end
      end
      spec "[!kt7mp] error when invalid user name specified." do |usr, grp|
        sout, serr = capture_sio do
          pr = proc { chown "honyara", "foo*.txt" }
          ok {pr}.raise?(ArgumentError, "chown: honyara: unknown user name.")
        end
      end
      spec "[!f7ye0] converts group name into group id." do |usr, grp, uid, gid|
        sout, serr = capture_sio do
          uid, gid = __chown("chown", ["#{usr}:#{grp}", "foo*.txt"], true)
          ok {uid} == uid
          ok {gid} == gid
        end
      end
      spec "[!szlsb] error when invalid group name specified." do
        sout, serr = capture_sio do
          pr = proc { chown ":honyara", "foo*.txt" }
          ok {pr}.raise?(ArgumentError, "chown: honyara: unknown group name.")
        end
      end
      spec "[!138eh] expands file pattern." do |usr, grp, uid|
        sout, serr = capture_sio do
          chown usr, "foo*.txt"
          ok {File.stat("foo1.txt").uid} == uid
          ok {File.stat("foo2.txt").uid} == uid
        end
      end
      spec "[!tvpey] error when file not exist." do |usr, grp|
        sout, serr = capture_sio do
          pr = proc { chown usr, "blabla.txt" }
          ok {pr}.raise?(ArgumentError, "chown: blabla.txt: No such file or directory.")
        end
      end
      spec "[!ovkk8] error when file pattern not matched to anything." do |usr, grp|
        sout, serr = capture_sio do
          pr = proc { chown usr, "blabla*.txt" }
          ok {pr}.raise?(ArgumentError, "chown: blabla*.txt: No such file or directory.")
        end
      end
      spec "[!7tf3k] changes file mode." do |usr, grp, uid, gid|
        sout, serr = capture_sio do
          chown "#{usr}:#{grp}", "foo1.txt"
          ok {File.stat("foo1.txt").uid} == uid
          ok {File.stat("foo1.txt").gid} == gid
        end
      end
      spec "[!m6mrg] skips symbolic links." do |usr, grp|
        sout, serr = capture_sio do
          File.symlink "foo1.txt", "foo1.link"
          File.unlink "foo1.txt"
          chown "#{usr}:#{grp}", "foo1.link"   # not raise error
        end
      end
      spec "[!b07ff] changes file mode recursively if '-R' option specified." do |usr, grp, uid|
        sout, serr = capture_sio do
          chown :R, "#{usr}", "d1"
          ok {File.stat("d1/d2/baz.txt").uid} == uid
        end
      end
    end


    topic 'store()' do
      spec "[!9wr1o] error when `to:` keyword argument not specified." do
        sout, serr = capture_sio do
          pr = proc { store "foo*.txt", "d1" }
          ok {pr}.raise?(ArgumentError, /^missing keyword: :?to$/)
        end
      end
      spec "[!n43u2] echoback command and arguments." do
        sout, serr = capture_sio do
          store "foo*.txt", to: "d1"
        end
        ok {sout} == "$ store foo*.txt d1\n"
      end
      spec "[!588e5] error when destination directory not exist." do
        sout, serr = capture_sio do
          pr = proc { store "foo*.txt", to: "d9" }
          ok {pr}.raise?(ArgumentError, "store: d9: directory not found.")
        end
      end
      spec "[!lm43y] error when destination pattern matched to multiple filenames." do
        sout, serr = capture_sio do
          pr = proc { store "d1", to: "foo*.txt" }
          ok {pr}.raise?(ArgumentError, "store: foo*.txt: unexpectedly matched to multiple filenames (foo1.txt, foo2.txt).")
        end
      end
      spec "[!u5zoy] error when destination is not a directory." do
        sout, serr = capture_sio do
          pr = proc { store "foo*.txt", to: "d1/bar.txt" }
          ok {pr}.raise?(ArgumentError, "store: d1/bar.txt: Not a directory.")
        end
      end
      spec "[!g1duw] error when absolute path specified." do
        sout, serr = capture_sio do
          pr = proc { store "/tmp", to: "d1" }
          ok {pr}.raise?(ArgumentError, "store: /tmp: absolute path not expected (only relative path expected).")
        end
      end
      spec "[!je1i2] error when file not exist but '-f' option not specified." do
        sout, serr = capture_sio do
          pr = proc { store "blabla*.txt", to: "d1"}
          ok {pr}.raise?(ArgumentError, "store: blabla*.txt: file or directory not found (add '-f' option to ignore missing files).")
        end
      end
      spec "[!5619q] (store) error when target file or directory already exists." do
        sout, serr = capture_sio do
          dummy_file "d1/foo2.txt", "dummy"
          pr = proc { store "foo*.txt", to: "d1" }
          ok {pr}.raise?(ArgumentError, "store: d1/foo2.txt: destination file or directory already exists.")
        end
      end
      spec "[!4y4zy] copy files with keeping filepath." do
        sout, serr = capture_sio do
          dummy_dir("d9")
          store "foo*.txt", "d1", to: "d9"
          ok {"d9/foo1.txt"}.file_exist?
          ok {"d9/foo2.txt"}.file_exist?
          ok {"d9/d1/bar.txt"}.file_exist?
          ok {"d9/d1/d2/baz.txt"}.file_exist?
        end
      end
      spec "[!f0n0y] copy timestamps if '-p' option specified." do
        sout, serr = capture_sio do
          dummy_dir "d9"
          atime1 = File.atime("d1/d2/baz.txt")
          mtime1 = File.mtime("d1/d2/baz.txt")
          atime2 = (x = atime1 - 600; Time.new(x.year, x.month, x.day, x.hour, x.min, x.sec))
          mtime2 = (x = mtime1 - 900; Time.new(x.year, x.month, x.day, x.hour, x.min, x.sec))
          File.utime(atime2, mtime2, "d1/d2/baz.txt")
          store :p, "d1/**/*.txt", to: "d9"
          ok {File.atime("d1/d2/baz.txt")} != atime1
          ok {File.mtime("d1/d2/baz.txt")} != mtime1
          ok {File.atime("d1/d2/baz.txt")} != atime2
          ok {File.mtime("d1/d2/baz.txt")} == mtime2
        end
      end
      spec "[!w8oq6] creates hard links if '-l' option specified." do
        sout, serr = capture_sio do
          dummy_dir "d9"
          store :l, "foo*.txt", "d1/**/*.txt", to: "d9"
          ok {File.identical?("foo1.txt", "d9/foo1.txt")} == true
          ok {File.identical?("foo2.txt", "d9/foo2.txt")} == true
          ok {File.identical?("d1/bar.txt", "d9/d1/bar.txt")} == true
          ok {File.identical?("d1/d2/baz.txt", "d9/d1/d2/baz.txt")} == true
        end
      end
      spec "[!7n869] error when copying supecial files such as character device." do
        sout, serr = capture_sio do
          dummy_dir "d9"
          dir = File.join(Dir.pwd(), "d9")
          Dir.chdir "/dev" do
            pr = proc { store "./null", to: dir }
            ok {pr}.raise?(ArgumentError, "store: ./null: cannot copy characterSpecial file.")
          end
        end
      end
    end

    topic 'store!()' do
      spec "[!cw08t] (store!) overwrites existing files." do
        dummy_file "d1/foo2.txt", "dummy"
        sout, serr = capture_sio do
          store! "foo*.txt", to: "d1"
          ok {"d1/foo2.txt"}.file_exist?
          ok {File.read("d1/foo2.txt")} != "dummy"
          ok {File.read("d1/foo2.txt")} == File.read("foo2.txt")
        end
      end
    end


    topic 'zip()' do
      spec "[!zzvuk] requires 'zip' gem automatically." do
        skip_when defined?(::Zip) != nil, "zip gem already required."
        ok {defined?(::Zip)} == nil
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
        end
        ok {defined?(::Zip)} != false
        ok {defined?(::Zip)} == 'constant'
      end
      spec "[!zk1qt] echoback command and arguments." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
        end
        ok {sout} == "$ zip foo.zip foo*.txt\n"
      end
      spec "[!lrnj7] zip filename required." do
        sout, serr = capture_sio do
          pr = proc { zip :r }
          ok {pr}.raise?(ArgumentError, "zip: zip filename required.")
        end
      end
      spec "[!umbal] error when zip file glob pattern matched to mutilple filenames." do
        sout, serr = capture_sio do
          dummy_file "foo1.zip"
          dummy_file "foo2.zip"
          pr = proc { zip! "foo*.zip", "foo*.txt" }
          ok {pr}.raise?(ArgumentError, "zip: foo*.zip: matched to multiple filenames (foo1.zip, foo2.zip).")
        end
      end
      spec "[!oqzna] (zip) raises error if zip file already exists." do
        sout, serr = capture_sio do
          dummy_file "foo.zip"
          pr = proc { zip "foo.zip", "foo*.txt" }
          ok {pr}.raise?(ArgumentError, "zip: foo.zip: already exists (to overwrite it, call `zip!` command instead of `zip` command).")
        end
      end
      spec "[!uu8uz] expands glob pattern." do
        sout, serr = capture_sio do
          pr = proc { zip "foo.zip", "foo*.txt" }
          ok {pr}.NOT.raise?(ArgumentError)
        end
      end
      spec "[!nahxa] error if file not exist." do
        sout, serr = capture_sio do
          pr = proc { zip "foo.zip", "blabla*.txt" }
          ok {pr}.raise?(ArgumentError, "zip: blabla*.txt: file or directory not found.")
        end
      end
      spec "[!qsp7c] cannot specify absolute path." do
        sout, serr = capture_sio do
          pr = proc { zip "foo.zip", "/tmp" }
          ok {pr}.raise?(ArgumentError, "zip: /tmp: not support absolute path.")
        end
      end
      spec "[!p8alf] creates zip file." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
          ok {"foo.zip"}.file_exist?
          unzip_cmd = capture2 "which unzip"
          if ! unzip_cmd.strip.empty?
            output = capture2 "#{unzip_cmd.strip} -l foo.zip"
            ok {output} =~ /foo1\.txt/
            ok {output} =~ /foo2\.txt/
          end
        end
      end
      spec "[!3sxmg] supports complession level (0~9)." do
        sout, serr = capture_sio do
          dummy_file "foo3.txt", "foobar"*10
          zip :'0', "foo0.zip", "foo*.txt"
          ok {"foo0.zip"}.file_exist?
          zip :'1', "foo1.zip", "foo*.txt"
          ok {"foo1.zip"}.file_exist?
          zip :'9', "foo9.zip", "foo*.txt"
          ok {"foo9.zip"}.file_exist?
          #
          ok {File.size("foo9.zip")} <= File.size("foo1.zip")
          ok {File.size("foo1.zip")} <  File.size("foo0.zip")
        end
      end
      spec "[!h7yxl] restores value of `Zip.default_compression`." do
        val = Zip.default_compression
        sout, serr = capture_sio do
          zip :'9', "foo9.zip", "foo*.txt"
        end
        ok {Zip.default_compression} == val
      end
      spec "[!bgdg7] adds files recursively into zip file if '-r' option specified." do
        sout, serr = capture_sio do
          zip :r, "foo.zip", "d1"
          unzip_cmd = capture2 "which unzip"
          if ! unzip_cmd.strip.empty?
            output = capture2 "#{unzip_cmd.strip} -l foo.zip"
            ok {output} =~ /d1\/bar\.txt/
            ok {output} =~ /d1\/d2\/baz\.txt/
          end
        end
      end
      spec "[!jgt96] error when special file specified." do
        sout, serr = capture_sio do
          here = Dir.pwd
          Dir.chdir "/dev" do
            pr = proc { zip File.join(here, "foo.zip"), "./null" }
            ok {pr}.raise?(ArgumentError, "zip: ./null: characterSpecial file not supported.")
          end
        end
      end
      spec "[!fvvn8] returns zip file object." do
        sout, serr = capture_sio do
          ret = zip "foo.zip", "foo*.txt"
          ok {ret}.is_a?(Zip::File)
        end
      end
    end

    topic 'zip!()' do
      spec "[!khbiq] zip filename can be glob pattern." do
        sout, serr = capture_sio do
          dummy_file "foo.zip"
          pr = proc { zip! "*.zip", "foo*.txt" }
          ok {pr}.NOT.raise?(ArgumentError)
        end
      end
      spec "[!e995z] (zip!) removes zip file if exists." do
        sout, serr = capture_sio do
          dummy_file "foo.zip"
          pr = proc { zip! "foo.zip", "foo*.txt" }
          ok {pr}.NOT.raise?(ArgumentError)
        end
      end
    end


    topic 'unzip()' do
      spec "[!eqx48] requires 'zip' gem automatically." do
        skip_when defined?(::Zip) != nil, "zip gem already required."
        ok {defined?(::Zip)} == nil
        sout, serr = capture_sio do
          begin
            unzip "foo.zip"
          rescue
          end
        end
        ok {defined?(::Zip)} == 'constant'
      end
      spec "[!0tedi] extract zip file." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
          rm "foo*.txt"
          ok {"foo1.txt"}.not_exist?
          ok {"foo2.txt"}.not_exist?
          unzip "foo.zip"
          ok {"foo1.txt"}.file_exist?
          ok {"foo2.txt"}.file_exist?
        end
      end
      spec "[!ednxk] echoback command and arguments." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
          File.unlink("foo1.txt", "foo2.txt")
          unzip "foo.zip"
        end
        ok {sout} == ("$ zip foo.zip foo*.txt\n"\
                      "$ unzip foo.zip\n")
      end
      spec "[!1lul7] error if zip file not specified." do
        sout, serr = capture_sio do
          pr = proc { unzip() }
          ok {pr}.raise?(ArgumentError, "unzip: zip filename required.")
          pr = proc { unzip :d }
          ok {pr}.raise?(ArgumentError, "unzip: zip filename required.")
        end
      end
      spec "[!0yyg8] target directory should not exist, or be empty." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
          mkdir "d8"
          unzip :d, "d8", "foo.zip"   # empty dir
          unzip :d, "d9", "foo.zip"   # non-existing dir
        end
      end
      spec "[!1ls2h] error if target directory not empty." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
          pr = proc { unzip :d, "d1", "foo.zip" }
          ok {pr}.raise?(ArgumentError, "unzip: d1: directory not empty.")
        end
      end
      spec "[!lb6r5] error if target directory is not a directory." do
        sout, serr = capture_sio do
          pr = proc { unzip :d, "foo1.txt", "foo2.txt" }
          ok {pr}.raise?(ArgumentError, "unzip: foo1.txt: not a directory.")
        end
      end
      spec "[!dzk7c] creates target directory if not exists." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
          unzip :d, "d8/d9", "*.zip"
          ok {"d8/d9/foo1.txt"}.file_exist?
          ok {"d8/d9/foo2.txt"}.file_exist?
        end
      end
      spec "[!o1ot5] expands glob pattern." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"; File.unlink("foo1.txt", "foo2.txt")
          unzip "*.zip"
          ok {"foo1.txt"}.file_exist?
          ok {"foo2.txt"}.file_exist?
        end
      end
      spec "[!92bh4] error if glob pattern matched to multiple filenames." do
        sout, serr = capture_sio do
          pr = proc { unzip "*.txt" }
          ok {pr}.raise?(ArgumentError, "unzip: *.txt: matched to multiple filenames (foo1.txt foo2.txt).")
        end
      end
      spec "[!esnke] error if zip file not found." do
        sout, serr = capture_sio do
          pr = proc { unzip "*.zip" }
          ok {pr}.raise?(ArgumentError, "unzip: *.zip: zip file not found.")
        end
      end
      spec "[!ekllx] (unzip) error when file already exists." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
          pr = proc { unzip "foo.zip" }
          ok {pr}.raise?(ArgumentError, "unzip: foo1.txt: file already exists (to overwrite it, call `unzip!` command instead of `unzip` command).")
        end
      end
      spec "[!zg60i] error if file has absolute path." do
        skip_when true, "cannot create zip file containing absolute path."
      end
      spec "[!ikq5w] if filenames are specified, extracts files matched to them." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"; File.unlink("foo1.txt", "foo2.txt")
          unzip "foo.zip", "*2.txt"
          ok {"foo1.txt"}.not_exist?
          ok {"foo2.txt"}.file_exist?
        end
      end
      spec "[!dy4r4] if '-d' option specified, extracts files under target directory." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
          unzip :d, "d9", "foo.zip"
          ok {"d9/foo1.txt"}.file_exist?
          ok {"d9/foo2.txt"}.file_exist?
        end
      end
      spec "[!5u645] if '-d' option not specified, extracts files under current directory." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"; File.unlink("foo1.txt", "foo2.txt")
          unzip "foo.zip"
          ok {"foo1.txt"}.file_exist?
          ok {"foo2.txt"}.file_exist?
        end
      end
    end

    topic 'unzip!()' do
      spec "[!06nyv] (unzip!) overwrites existing files." do
        sout, serr = capture_sio do
          zip "foo.zip", "foo*.txt"
          File.unlink("foo2.txt")
          ok {"foo1.txt"}.file_exist?
          ok {"foo2.txt"}.not_exist?
          pr = proc { unzip! "foo.zip" }
          ok {pr}.NOT.raise?(ArgumentError)
          ok {"foo1.txt"}.file_exist?
          ok {"foo2.txt"}.file_exist?
        end
      end
    end


    topic 'time()' do
      spec "[!ddl3a] measures elapsed time of block and reports into stderr." do
        sout, serr = capture_sio do
          time do
            puts "sleep 1..."
            sleep 1
          end
        end
        ok {sout} == "sleep 1...\n"
        ok {serr} =~ /\A\n        1\.\d\d\ds real       0\.\d\d\ds user       0\.\d\d\ds sys\n\z/
      end
      spec "[!sjf80] (unzip!) `Zip.on_exists_proc` should be recovered." do
        sout, serr = capture_sio do
          ok {Zip.on_exists_proc} == false
          zip "foo.zip", "foo1.txt", "foo2.txt"
          unzip! "foo.zip"
          ok {Zip.on_exists_proc} == false
        end
      end
    end


  end


end
