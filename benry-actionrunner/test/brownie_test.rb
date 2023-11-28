# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative './shared'


Oktest.scope do

  before_all do
    TestHelperModule.setup_all()
  end

  after_all do
    TestHelperModule.teardown_all()
  end


  topic Benry::ActionRunner::Brownie do

    before do
      @filename = "Actionfile.rb"
      $LOADED_FEATURES.delete(File.absolute_path(@filename))
      config = Benry::ActionRunner::CONFIG
      @brownie = Benry::ActionRunner::Brownie.new(config)
      @registry = Benry::CmdApp::REGISTRY
    end

    after do
      File.unlink(@filename) if File.exist?(@filename)
      clear_registry()
    end

    def cd_tmpdir(dirpath, &b)
      xs = dirpath.split("/")
      (1..(xs.length)).each do |len|
        dir = xs[0, len].join("/")
        dummy_dir(dir)
      end
      pwd = Dir.pwd()
      Dir.chdir(dirpath)
      yield
    ensure
      Dir.chdir(pwd)
    end


    topic('#search_and_load_action_file()') {
      #
      spec "[!c9e1h] if action file exists in current dir, load it regardless of options." do
        prepare_actionfile("a2071")
        ok {@registry.metadata_exist?("a2071")} == false
        @brownie.search_and_load_action_file(@filename, true, false)
        ok {@registry.metadata_exist?("a2071")} == true
      end
      #
      spec "[!m5oj7] if action file exists in parent dir, find and load it if option '-s' specified." do
        prepare_actionfile("a4290")
        cd_tmpdir("foo/bar") do
          ok {@registry.metadata_exist?("a4290")} == false
          @brownie.search_and_load_action_file(@filename, true, false)
          ok {@registry.metadata_exist?("a4290")} == true
        end
      end
      #
      spec "[!079xs] returns nil if action file not found." do
        ok {@filename}.not_exist?
        ret = @brownie.search_and_load_action_file(@filename, true, false)
        ok {ret} == nil
      end
      #
      spec "[!7simq] changes current dir to where action file exists if option '-w' specified." do
        prepare_actionfile("a0561", "puts Dir.pwd")
        pwd1 = Dir.pwd()
        cd_tmpdir("foo/bar") do
          pwd2 = Dir.pwd()
          ok {pwd2} == File.join(pwd1, "foo/bar")
          sout = arun "-uw", "a0561"
          ok {sout} == <<~"END"
            $ cd ../..
            #{pwd1}
          END
        end
      end
      #
      spec "[!dg2qv] action file can has directory path." do
        prepare_actionfile("a5767", "puts Dir.pwd")
        pwd1 = Dir.pwd()
        cd_tmpdir("foo/bar") do
          sout = arun "-uw", "-f", "../Actionfile.rb", "a5767"
          ok {sout} == <<~"END"
            $ cd ..
            #{File.join(pwd1, "foo")}
          END
        end
      end
      #
      spec "[!d987b] loads action file if exists." do
        prepare_actionfile("a5626")
        cd_tmpdir("foo/bar") do
          ok {@registry.metadata_exist?("a5626")} == false
          sout = arun "-uw", "a5626", "Bob"
          ok {sout} == <<~"END"
            $ cd ../..
            Hi, Bob!
          END
        end
      end
      #
      spec "[!x9xxl] returns absolute path of action file if exists." do
        prepare_actionfile("a4156")
        pwd = Dir.pwd()
        $BENRY_ECHOBACK = false
        cd_tmpdir("foo/bar") do
          ok {@registry.metadata_exist?("a4156")} == false
          ret = @brownie.search_and_load_action_file(@filename, true, true)
          ok {@registry.metadata_exist?("a4156")} == true
          ok {ret} == File.join(pwd, "Actionfile.rb")
        end
        $BENRY_ECHOBACK = true
      end
    }

    topic('#populate_global_variables()') {
      #
      spec "[!cr2ph] sets global variables." do
        gvars = {"g5933x" => "ABC", "g5933y" => "123"}
        @brownie.populate_global_variables(gvars)
        ok {$g5933x} == "ABC"
        ok {$g5933y} == 123
      end
      #
      spec "[!3kow3] normalizes global variable names." do
        gvars = {"g8258-vari-@able" => "ABC"}
        @brownie.populate_global_variables(gvars)
        ok {$g8258_vari__able} == "ABC"
      end
      #
      spec "[!03x7t] decodes JSON string into Ruby object." do
        gvars = {"g6950" => "[123, true, null]"}
        @brownie.populate_global_variables(gvars)
        ok {$g6950} == [123, true, nil]
      end
      #
      spec "[!1ol4a] print global variables if debug mode is on." do
        gvars = {"g7091" => '{"a": 123}'}
        $DEBUG_MODE = true
        at_end { $DEBUG_MODE = nil }
        sout, serr = capture_sio do
          @brownie.populate_global_variables(gvars)
        end
        ok {serr} == ""
        ok {sout} == "[DEBUG] $g7091 = {\"a\"=>123}\n"
      end
    }

    topic('#_decode_value()') {
      #
      spec "[!omxyf] decodes string as JSON format." do
        str = '["ABC", 123, true, null]'
        val = @brownie.instance_eval { _decode_value(str) }
        ok {val} == ["ABC", 123, true, nil]
      end
      #
      spec "[!tvwvn] returns string as it is if failed to parse as JSON." do
        str = 'nil'
        val = @brownie.instance_eval { _decode_value(str) }
        ok {val} == "nil"
      end
    }

    topic('#_debug_global_var()') {
      #
      spec "[!05l5f] prints var name and it's value." do
        sout, serr = capture_sio(tty: false) do
          @brownie.instance_eval { _debug_global_var("var1", ["val1"]) }
        end
        ok {serr} == ""
        ok {sout} == "[DEBUG] $var1 = [\"val1\"]\n"
      end
      #
      spec "[!7lwvz] colorizes output if color mode enabled." do
        sout, serr = capture_sio(tty: true) do
          @brownie.instance_eval { _debug_global_var("var1", ["val1"]) }
        end
        ok {serr} == ""
        ok {sout} == "\e[2m[DEBUG] $var1 = [\"val1\"]\e[0m\n"
      end
    }

    topic('#render_action_file_content()') {
      #
      spec "[!oc03q] returns content of action file." do
        filename = "Actionfile.rb"
        s = @brownie.render_action_file_content(filename)
        ok {s} != ""
        dummy_file(filename, s)
        output = `ruby -wc #{filename}`
        ok {output} == "Syntax OK\n"
      end
    }

  end


end
