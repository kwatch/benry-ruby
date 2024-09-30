# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::Util do

    fixture :util do
      Benry::MicroRake::Util
    end


    topic '#convert_value()' do

      spec "[!29j7q] returns true if arg is true." do |util|
        ok {util.convert_value(true)} == true
      end

      spec "[!5wzbr] returns true if arg is nil." do |util|
        ok {util.convert_value(nil)} == true
      end

      spec "[!fqzvn] parses arg as JSON string." do |util|
        ok {util.convert_value("123")} == 123
        ok {util.convert_value("-123")} == -123
        ok {util.convert_value("3.14")} == 3.14
        ok {util.convert_value("true")} == true
        ok {util.convert_value("false")} == false
        ok {util.convert_value("null")} == nil
        ok {util.convert_value("[10,20]")} == [10, 20]
        ok {util.convert_value("{\"a\":1}")} == {"a"=>1}
      end

      spec "[!we5lh] returns arg string as is if failed to parse as JSON string." do |util|
        ok {util.convert_value("foo")} == "foo"
        ok {util.convert_value("nil")} == "nil"
      end

    end


    topic '#render_default_taskfile()' do

      spec "[!73223] returns default template of task file." do |util|
        str = util.render_default_taskfile("urake")
        ok {str} =~ /^task :help do$/
        ok {str} =~ /^task :clean do \|all: false\|$/
        dummy_file("Taskfile2.rb", str)
        pr = proc do
          require "./Taskfile2"
        end
        ok {pr}.NOT.raise?
      end

      spec "[!forme] replaces '%COMMAND%' in detault template with command name." do |util|
        str = util.render_default_taskfile("urake9")
        ok {str} =~ /urake9/
        ok {str} !~ /urake[^9]/
      end

    end


    topic '#normalize_task_name()' do

      spec "[!cwfml] converts a Symbol object to a String object." do |util|
        ok {util.normalize_task_name(:foo)} == "foo"
      end

      spec "[!nntke] replaces '-' in name with '_'." do |util|
        ok {util.normalize_task_name("aa-bb-cc")} == "aa_bb_cc"
      end

    end


    topic '#hyphenize_task_name()' do

      spec "[!e77l6] converts symbol to string." do |util|
        ok {util.hyphenize_task_name(:foo)} == "foo"
      end

      spec "[!uned9] converts \"a_b_c\" into \"a-b-c\"." do |util|
        ok {util.hyphenize_task_name(:aa_bb_cc)} == "aa-bb-cc"
      end

      spec "[!hdlhm] converts \"-foo\" into \"_foo\"." do |util|
        ok {util.hyphenize_task_name("-foo-bar")} == "_foo-bar"
      end

      spec "[!9aimn] converts \"foo:-bar\" into \"foo:_bar\"." do |util|
        ok {util.hyphenize_task_name("foo:-bar-baz")} == "foo:_bar-baz"
      end

    end


    topic '#format_argname()' do

      spec "[!zv7xb] converts symbol into string." do |util|
        ok {util.format_argname(:foo)} == "foo"
      end

      spec "[!dhg0y] converts `:yes_or_no` to `\"yes|no\"`." do |util|
        ok {util.format_argname(:yes_or_no)} == "yes|no"
      end

      spec "[!srnd1] converts `:file__html` to `\"file.html\"`."  do |util|
        ok {util.format_argname(:file__html)} == "file.html"
      end

      spec "[!9y6re] converts `:my_src_file` to `\"my-src-file\"`." do |util|
        ok {util.format_argname(:my_src_file)} == "my-src-file"
      end

      spec "[!27nhc] converts `:_foo_bar_baz` to `\"_foo-bar_baz\"`." do |util|
        ok {util.format_argname(:_foo_bar_baz)} == "_foo-bar-baz"
      end

    end


    topic '#colorize_appname()' do

      spec "[!n3evs] returns corolized string." do |util|
        ok {util.colorize_appname("Urake")} == "\e[1mUrake\e[0m"
      end

    end


    topic '#colorize_taskname()' do

      spec "[!0ouyi] returns corolized string." do |util|
        ok {util.colorize_taskname("build")} == "\e[1mbuild\e[0m"
      end

    end


    topic '#colorize_secheader()' do

      spec "[!jahx6] returns colorized string." do |util|
        ok {util.colorize_secheader("Options")} == "\e[36mOptions\e[0m"
      end

    end


    topic '#colorize_location()' do

      spec "[!8kgb8] returns colorized string." do |util|
        ok {util.colorize_location("./Taskfile.rb:12")} == "\e[2;3m./Taskfile.rb:12\e[0m"
      end

    end


    topic '#colorize_important()' do

      spec "[!u76lu] returns colorized string." do |util|
        ok {util.colorize_important("build")} == "\e[1mbuild\e[0m"
      end

    end


    topic '#colorize_unimportant()' do

      spec "[!17hi0] returns colorized string." do |util|
        ok {util.colorize_unimportant("list")} == "\e[2mlist\e[0m"
      end

    end


    topic '#colorize_hidden()' do

      spec "[!f5dvq] returns colorized string." do |util|
        ok {util.colorize_hidden("delete")} == "\e[2mdelete\e[0m"
      end

    end


    topic '#colorize_trace()' do

      spec "[!nxyvc] returns colorized string." do |util|
        ok {util.colorize_trace("enter:")} == "\e[33menter:\e[0m"
      end

    end


    topic '#colorize_error()' do

      spec "[!bnfcm] returns red-colorized string." do |util|
        ok {util.colorize_error("Not found.")} == "\e[31mNot found.\e[0m"
      end

    end


    topic '#uncolorize()' do

      spec "[!v5lvk] deletes escape sequences from a string." do |util|
        ok {util.uncolorize("\e[1mBOLD\e[0m\n\e[31mRED\e[0m\n")} == "BOLD\nRED\n"
      end

    end


    topic '#uncolorize_unless_tty()' do

      spec "[!i9hd9] deletes escape sequences when stdout is not a tty." do |util|
        capture_sio(tty: false) do
          ok {util.uncolorize_unless_tty("\e[1mBOLD\e[0m")} == "BOLD"
        end
        capture_sio(tty: true) do
          ok {util.uncolorize_unless_tty("\e[1mBOLD\e[0m")} == "\e[1mBOLD\e[0m"
        end
      end

    end

  end


  topic Benry::MicroRake::Util::FilepathShortener do

    fixture :shortener do
      $URAKE_TASKFILE_FULLPATH = File.absolute_path("Taskfile.rb")
      Benry::MicroRake::Util::FilepathShortener.new
    end


    topic '#initialize()' do

      spec "[!6krfz] prepares path replacement mapping dict." do |shortener|
        shortener.instance_exec(self) do |_|
          _.ok {@dict} == {
            (Dir.pwd + "/")               => "./",
            (File.dirname(Dir.pwd) + "/") => "../",
            (File.expand_path("~") + "/") => "~/",
          }
        end
      end

    end


    topic '#shorten_filepath()' do

      spec "[!t9w8h] converts \"/home/yourname/lib/\" to \"~/lib/\"." do
        |shortener|
        filepath = Dir.pwd + "/Taskfile.rb"
        ok {filepath} != "./Taskfile.rb"
        ok {shortener.shorten_filepath(filepath)} == "./Taskfile.rb"
      end

      spec "[!2s6p9] converts \"/home/yourname/src/foo\" to \"./\"." do
        |shortener|
        filepath = File.dirname(Dir.pwd) + "/Taskfile.rb"
        ok {filepath} != "../Taskfile.rb"
        ok {shortener.shorten_filepath(filepath)} == "../Taskfile.rb"
      end

      spec "[!665n9] converts \"/home/yourname/src/bar\" to \"../bar\"." do
        |shortener|
        filepath = File.expand_path("~/_tmp_test_file")
        ok {filepath} != "~/_tmp_test_file"
        ok {shortener.shorten_filepath(filepath)} == "~/_tmp_test_file"
      end

      spec "[!om9f6] returns filepath as is if it doesn't match to replacement path." do
        |shortener|
        filepath = "/var/tmp/foobar.txt"
        ok {shortener.shorten_filepath(filepath)} == "/var/tmp/foobar.txt"
      end

    end


    topic '#_root_path()' do

      spec "[!j2fjj] detects relative path from here to task file." do
        |shortener|
        here = Dir.pwd
        dummy_dir("foo/bar/baz")
        Dir.chdir("foo/bar/baz") do
          root_abspath, root_relpath = shortener.instance_eval {
            _root_path(here + "/foo/bar/baz")
          }
          ok {root_abspath} == here + "/"
          ok {root_relpath} == "../../.."
        end
      end

    end


  end


  topic Benry::MicroRake::Util::FileLinesCache do

    fixture :linescache do
      Benry::MicroRake::Util::FileLinesCache.new()
    end


    topic '#clear_cache()' do

      spec "[!0c6ye] clears line cache." do |linescache|
        linescache.instance_exec(self) do |_|
          @lines_cache = {"Taskfile.rb" => ["line1", "line2"]}
          clear_cache()
          _.ok {@lines_cache} == {}
        end
      end

    end


    topic '#get_line_of_file_at()' do

      spec "[!s5fur] reads lines of file and stores into line cache." do |linescache|
        linescache.instance_exec(self) do |_|
          _.ok {@lines_cache}.empty?
          get_line_of_file_at("Taskfile.rb", 15)
          _.ok {@lines_cache}.NOT.empty?
          _.ok {@lines_cache.keys} == ["Taskfile.rb"]
          _.ok {@lines_cache["Taskfile.rb"]}.is_a?(Array)
        end
      end

      spec "[!9rnqn] returns a line string of file." do |linescache|
        line = linescache.get_line_of_file_at("Taskfile.rb", 15)
        ok {line} == "task :help do"
      end

    end


    topic '#_get_lines_of_file()' do

      spec "[!5ovcm] splits file content into lines." do |linescache|
        lines = linescache.instance_eval {
          _get_lines_of_file("Taskfile.rb")
        }
        ok {lines}.is_a?(Array)
        ok {lines}.all? {|x| x.is_a?(String) }
      end

      spec "[!vgoe6] each line doesn't contain \"\n\"." do |linescache|
        lines = linescache.instance_eval {
          _get_lines_of_file("Taskfile.rb")
        }
        ok {lines}.all? {|x| x !~ /\n/ }
      end

    end


  end


end
