# -*- coding: utf-8 -*-

require 'oktest'

require 'benry/cmdapp'
require_relative './shared'


Oktest.scope do


  topic Benry::CmdApp::Util do


    topic '.hidden_name?()' do

      spec "[!fcfic] returns true if name is '_foo'." do
        ok {Benry::CmdApp::Util.hidden_name?("_foo")} == true
      end

      spec "[!po5co] returns true if name is '_foo:bar'." do
        ok {Benry::CmdApp::Util.hidden_name?("_foo:bar")} == true
      end

      spec "[!9iqz3] returns true if name is 'foo:_bar'." do
        ok {Benry::CmdApp::Util.hidden_name?("foo:_bar")} == true
      end

      spec "[!mjjbg] returns false if else." do
        ok {Benry::CmdApp::Util.hidden_name?("foo")} == false
        ok {Benry::CmdApp::Util.hidden_name?("foo_")} == false
        ok {Benry::CmdApp::Util.hidden_name?("foo_:bar")} == false
        ok {Benry::CmdApp::Util.hidden_name?("foo:bar_")} == false
      end

    end


    topic '.schema_empty?()' do

      spec "[!8t5ju] returns true if schema empty." do
        sc = Benry::CmdOpt::Schema.new
        ok {Benry::CmdApp::Util.schema_empty?(sc)} == true
        sc.add(:help, "-h", "help")
        ok {Benry::CmdApp::Util.schema_empty?(sc)} == false
      end

      spec "[!c4ljy] returns true if schema contains only private (hidden) options." do
        sc = Benry::CmdOpt::Schema.new
        sc.add(:help, "-h", "help", hidden: true)
        ok {Benry::CmdApp::Util.schema_empty?(sc)} == true
        sc.add(:version, "-V", "version")
        ok {Benry::CmdApp::Util.schema_empty?(sc)} == false
      end

    end


    topic '.method2action()' do

      spec "[!801f9] converts action name 'aa_bb_cc_' into 'aa_bb_cc'." do
        ok {Benry::CmdApp::Util.method2action("aa_")} == "aa"
        ok {Benry::CmdApp::Util.method2action("_aa_")} == "_aa"
      end

      spec "[!9pahu] converts action name 'aa__bb__cc' into 'aa:bb:cc'." do
        ok {Benry::CmdApp::Util.method2action("aa__bb__cc")} == "aa:bb:cc"
      end

      spec "[!7a1s7] converts action name 'aa_bb:_cc_dd' into 'aa-bb:_cc-dd'." do
        ok {Benry::CmdApp::Util.method2action("aa_bb:cc_dd")} == "aa-bb:cc-dd"
        ok {Benry::CmdApp::Util.method2action("aa_bb:_cc_dd")} == "aa-bb:_cc-dd"
        ok {Benry::CmdApp::Util.method2action("aa___bb")} == "aa:_bb"
      end

    end


    topic '.colorize?()' do

      spec "[!801y1] returns $COLOR_MODE value if it is not nil." do
        bkup = $COLOR_MODE
        begin
          $COLOR_MODE = true
          ok {Benry::CmdApp::Util.colorize?()} == true
          $COLOR_MODE = false
          ok {Benry::CmdApp::Util.colorize?()} == false
        ensure
          $COLOR_MODE = bkup
        end
      end

      spec "[!0harg] returns true if stdout is a tty." do
        capture_sio(tty: true) {
          ok {Benry::CmdApp::Util.colorize?()} == true
        }
      end

      spec "[!u1j1x] returns false if stdout is not a tty." do
        capture_sio(tty: false) {
          ok {Benry::CmdApp::Util.colorize?()} == false
        }
      end

    end


    topic '.del_escape_seq()' do

      spec "[!wgp2b] deletes escape sequence." do
        s = "  \e[1m%-18s\e[0m : %s"
        ok {Benry::CmdApp::Util.del_escape_seq(s)} == "  %-18s : %s"
      end

    end


    topic '._important?()' do

      spec "[!0yz2h] returns nil if tag == nil." do
        ok {Benry::CmdApp::Util._important?(nil)} == nil
      end

      spec "[!h5pid] returns true if tag == :important." do
        ok {Benry::CmdApp::Util._important?(:important)} == true
        ok {Benry::CmdApp::Util._important?("important")} == true
      end

      spec "[!7zval] returns false if tag == :unimportant." do
        ok {Benry::CmdApp::Util._important?(:unimportant)} == false
        ok {Benry::CmdApp::Util._important?("unimportant")} == false
      end

      spec "[!z1ygi] supports nested tag." do
        ok {Benry::CmdApp::Util._important?([:important, :foo])} == true
        ok {Benry::CmdApp::Util._important?([:bar, :unimportant])} == false
      end

    end


    topic '.format_help_line()' do

      fixture :format do
        "  [[%-10s]] : %s"
      end

      spec "[!xx1vj] if `important == nil` then format help line with no decoration." do
        |format|
        s = Benry::CmdApp::Util.format_help_line(format, "<action>", "<desc>", nil)
        ok {s} == "  [[<action>  ]] : <desc>"
      end

      spec "[!oaxp1] if `important == true` then format help line with strong decoration." do
        |format|
        s = Benry::CmdApp::Util.format_help_line(format, "<action>", "<desc>", true)
        ok {s} == "  [[\e[4m<action>\e[0m  ]] : <desc>"
      end

      spec "[!bdhh6] if `important == false` then format help line with weak decoration." do
        |format|
        s = Benry::CmdApp::Util.format_help_line(format, "<action>", "<desc>", false)
        ok {s} == "  [[\e[2m<action>\e[0m  ]] : <desc>"
      end

    end


    topic '.fill_with_decoration()' do

      spec "[!udrbj] returns decorated string with padding by white spaces." do
        format = "  [[%-10s]] : %s"
        s = Benry::CmdApp::Util.fill_with_decoration(format, "<action>") {|s| "\e[1m#{s}\e[0m" }
        ok {s} == "\e[1m<action>\e[0m  "
      end

      spec "[!7bl2b] considers minus sign in format." do
        format = "  [[%10s]] : %s"
        s = Benry::CmdApp::Util.fill_with_decoration(format, "<action>") {|s| "\e[1m#{s}\e[0m" }
        ok {s} == "  \e[1m<action>\e[0m"
      end

    end


  end


end
