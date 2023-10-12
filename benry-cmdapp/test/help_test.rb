# -*- coding: utf-8 -*-

require 'oktest'

require 'benry/cmdapp'
require_relative './shared'


Oktest.scope do


  topic Benry::CmdApp::HelpBuilder do


    before do
      @builder = Benry::CmdApp::HelpBuilder.new()
    end


    topic '#build_section()' do

      spec "[!cfijh] includes section title and content if specified by config." do
        msg = @builder.build_section("Example", "  $ echo 'Hello, world!'")
        ok {msg} == <<"END"
\e[34mExample:\e[0m
  $ echo 'Hello, world!'
END
      end

      spec "[!09jzn] third argument can be nil." do
        msg = @builder.build_section("Example", "  $ echo 'Hello, world!'", "(see https://...)")
        ok {msg} == <<"END"
\e[34mExample:\e[0m (see https://...)
  $ echo 'Hello, world!'
END
      end

    end


  end


  topic Benry::CmdApp::ActionHelpBuilder do
    include ActionMetadataTestingHelper


    topic '#build_help_message()' do

      spec "[!pqoup] adds detail text into help if specified." do
        expected = <<END
testapp halo1 -- greeting

See: https://example.com/doc.html

Usage:
  $ testapp halo1 [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
END
        detail = "See: https://example.com/doc.html"
        [detail, detail+"\n"].each do |detail_|
          metadata = new_metadata(new_schema(), detail: detail)
          msg = metadata.help_message("testapp")
          msg = uncolorize(msg)
          ok {msg} == expected
        end
      end

      spec "[!zbc4y] adds '[<options>]' into 'Usage:' section only when any options exist." do
        schema = new_schema(lang: false)
        msg = new_metadata(schema).help_message("testapp")
        msg = uncolorize(msg)
        ok {msg}.include?("Usage:\n" +
                          "  $ testapp halo1 [<user>]\n")
        #
        schema = new_schema(lang: true)
        msg = new_metadata(schema).help_message("testapp")
        msg = uncolorize(msg)
        ok {msg}.include?("Usage:\n" +
                          "  $ testapp halo1 [<options>] [<user>]\n")
      end

      spec "[!8b02e] ignores '[<options>]' in 'Usage:' when only hidden options speicified." do
        schema = new_schema(lang: false)
        schema.add(:_lang, "-l, --lang=<en|fr|it>", "language")
        msg = new_metadata(schema).help_message("testapp")
        msg = uncolorize(msg)
        ok {msg} =~ /^  \$ testapp halo1 \[<user>\]\n/
        ok {msg} =~ /^Usage:\n  \$ testapp halo1 \[<user>\]$/
      end

      spec "[!ou3md] not add extra whiespace when no arguments of command." do
        schema = new_schema(lang: true)
        msg = new_metadata(schema, :halo3).help_message("testapp")
        msg = uncolorize(msg)
        ok {msg} =~ /^  \$ testapp halo3 \[<options>\]\n/
        ok {msg} =~ /^Usage:\n  \$ testapp halo3 \[<options>\]$/
      end

      spec "[!g2ju5] adds 'Options:' section." do
        schema = new_schema(lang: true)
        msg = new_metadata(schema).help_message("testapp")
        msg = uncolorize(msg)
        ok {msg}.include?("Options:\n" +
                          "  -l, --lang=<en|fr|it> : language\n")
      end

      spec "[!pvu56] ignores 'Options:' section when no options exist." do
        schema = new_schema(lang: false)
        msg = new_metadata(schema).help_message("testapp")
        msg = uncolorize(msg)
        ok {msg}.NOT.include?("Options:\n")
      end

      spec "[!hghuj] ignores 'Options:' section when only hidden options speicified." do
        schema = new_schema(lang: false)
        schema.add(:_lang, "-l, --lang=<en|fr|it>", "language")  # hidden option
        msg = new_metadata(schema).help_message("testapp")
        msg = uncolorize(msg)
        ok {msg}.NOT.include?("Options:\n")
      end

      spec "[!vqqq1] hidden option should be shown in weak format." do
        schema = new_schema(lang: false)
        schema.add(:file , "-f, --file=<file>", "filename")
        schema.add(:_lang, "-l, --lang=<lang>", "language")  # hidden option
        msg = new_metadata(schema).help_message("testapp", true)
        ok {msg}.end_with?(<<"END")
\e[34mOptions:\e[0m
  \e[1m-f, --file=<file> \e[0m : filename
  \e[1m\e[2m-l, --lang=<lang>\e[0m \e[0m : language
END
      end

      spec "[!dukm7] includes detailed description of option." do
        schema = new_schema(lang: false)
        schema.add(:lang, "-l, --lang=<lang>", "language",
                   detail: "detailed description1\ndetailed description2")
        msg = new_metadata(schema).help_message("testapp")
        msg = uncolorize(msg)
        ok {msg}.end_with?(<<"END")
Options:
  -l, --lang=<lang>  : language
                       detailed description1
                       detailed description2
END
      end

      spec "[!0p2gt] adds postamble text if specified." do
        postamble = "Tips: `testapp -h <action>` print help message of action."
        schema = new_schema(lang: false)
        ameta = new_metadata(schema, postamble: postamble)
        msg = ameta.help_message("testapp")
        msg = uncolorize(msg)
        ok {msg} == <<END
testapp halo1 -- greeting

Usage:
  $ testapp halo1 [<user>]

Tips: `testapp -h <action>` print help message of action.
END
      end

      spec "[!v5567] adds '\n' at end of preamble text if it doesn't end with '\n'." do
        postamble = "END"
        schema = new_schema(lang: false)
        ameta = new_metadata(schema, postamble: postamble)
        msg = ameta.help_message("testapp")
        ok {msg}.end_with?("\nEND\n")
      end

      spec "[!x0z89] required arg is represented as '<arg>'." do
        schema = new_schema(lang: false)
        metadata = Benry::CmdApp::ActionMetadata.new("args1", MetadataTestAction, :args1, "", schema)
        msg = metadata.help_message("testapp")
        msg = uncolorize(msg)
        ok {msg} =~ /^  \$ testapp args1 <aa> <bb>$/
      end

      spec "[!md7ly] optional arg is represented as '[<arg>]'." do
        schema = new_schema(lang: false)
        metadata = Benry::CmdApp::ActionMetadata.new("args2", MetadataTestAction, :args2, "", schema)
        msg = without_tty { metadata.help_message("testapp") }
        msg = uncolorize(msg)
        ok {msg} =~ /^  \$ testapp args2 <aa> \[<bb> \[<cc>\]\]$/
      end

      spec "[!xugkz] variable args are represented as '[<arg>...]'." do
        schema = new_schema(lang: false)
        metadata = Benry::CmdApp::ActionMetadata.new("args3", MetadataTestAction, :args3, "", schema)
        msg = metadata.help_message("testapp")
        msg = uncolorize(msg)
        ok {msg} =~ /^  \$ testapp args3 <aa> \[<bb> \[<cc> \[<dd>...\]\]\]$/
      end

      spec "[!eou4h] converts arg name 'xx_or_yy_or_zz' into 'xx|yy|zz'." do
        schema = new_schema(lang: false)
        metadata = Benry::CmdApp::ActionMetadata.new("args4", MetadataTestAction, :args4, "", schema)
        msg = metadata.help_message("testapp")
        msg = uncolorize(msg)
        ok {msg} =~ /^  \$ testapp args4 <xx\|yy\|zz>$/
      end

      spec "[!naoft] converts arg name '_xx_yy_zz' into '_xx-yy-zz'." do
        schema = new_schema(lang: false)
        metadata = Benry::CmdApp::ActionMetadata.new("args5", MetadataTestAction, :args5, "", schema)
        msg = metadata.help_message("testapp")
        msg = uncolorize(msg)
        ok {msg} =~ /^  \$ testapp args5 <_xx-yy-zz>$/
      end

    end


  end


  topic Benry::CmdApp::AppHelpBuilder do
    include CommonTestingHelper

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.0.0").tap do |config|
        config.app_name     = "TestApp"
        config.app_command  = "testapp"
        config.option_all   = true
        config.option_debug = true
        config.default_action = nil
      end
      @schema = Benry::CmdApp::AppOptionSchema.new(@config)
      @builder = Benry::CmdApp::AppHelpBuilder.new(@config, @schema)
    end

    topic '#build_help_message()' do

      class HelpMessageTest < Benry::CmdApp::ActionScope
        @action.("greeting #1")
        def yo_yo()
        end
        @action.("greeting #2")
        def ya__ya()
        end
        @action.("greeting #3")
        def _aha()
        end
        @action.("greeting #4")
        def ya___mada()
        end
      end

      Benry::CmdApp.action_alias("yes", "yo-yo")

      before do
        clear_index_except(HelpMessageTest)
      end

      after do
        restore_index()
      end

      expected_color = <<"END"
\e[1mTestApp\e[0m (1.0.0) -- test app

\e[34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] [<action> [<arguments>...]]

\e[34mOptions:\e[0m
  \e[1m-h, --help        \e[0m : print help message
  \e[1m-V, --version     \e[0m : print version
  \e[1m-a, --all         \e[0m : list all actions including private (hidden) ones
  \e[1m-D, --debug       \e[0m : debug mode (set $DEBUG_MODE to true)

\e[34mActions:\e[0m
  \e[1mya:ya             \e[0m : greeting #2
  \e[1myes               \e[0m : alias of 'yo-yo' action
  \e[1myo-yo             \e[0m : greeting #1
END

      expected_mono = <<'END'
TestApp (1.0.0) -- test app

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message
  -V, --version      : print version
  -a, --all          : list all actions including private (hidden) ones
  -D, --debug        : debug mode (set $DEBUG_MODE to true)

Actions:
  ya:ya              : greeting #2
  yes                : alias of 'yo-yo' action
  yo-yo              : greeting #1
END

      spec "[!rvpdb] returns help message." do
        msg = @builder.build_help_message()
        msg_color = msg
        msg_mono  = uncolorize(msg)
        ok {msg_mono}  == expected_mono
        ok {msg_color} == expected_color
      end

      def _with_color_mode(val, &b)
        bkup = $COLOR_MODE
        $COLOR_MODE = val
        yield
      ensure
        $COLOR_MODE = bkup
      end

      spec "[!34y8e] includes application name specified by config." do
        @config.app_name = "MyGreatApp"
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg} =~ /^MyGreatApp \(1\.0\.0\) -- test app$/
      end

      spec "[!744lx] includes application description specified by config." do
        @config.app_desc = "my great app"
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg} =~ /^TestApp \(1\.0\.0\) -- my great app$/
      end

      spec "[!d1xz4] includes version number if specified by config." do
        @config.app_version = "1.2.3"
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg} =~ /^TestApp \(1\.2\.3\) -- test app$/
        #
        @config.app_version = nil
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg} =~ /^TestApp -- test app$/
      end

      spec "[!775jb] includes detail text if specified by config." do
        @config.app_detail = "See https://example.com/doc.html"
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg}.start_with?(<<END)
TestApp (1.0.0) -- test app

See https://example.com/doc.html

Usage:
END
      #
      @config.app_detail = nil
      msg = @builder.build_help_message()
      msg = uncolorize(msg)
      ok {msg}.start_with?(<<END)
TestApp (1.0.0) -- test app

Usage:
END
      end

      spec "[!t3tbi] adds '\\n' before detail text only when app desc specified." do
        @config.app_desc   = nil
        @config.app_detail = "See https://..."
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg}.start_with?(<<END)
See https://...

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

END
      end

      spec "[!rvhzd] no preamble when neigher app desc nor detail specified." do
        @config.app_desc   = nil
        @config.app_detail = nil
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg}.start_with?(<<END)
Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

END
      end

      spec "[!o176w] includes command name specified by config." do
        @config.app_name = "GreatCommand"
        @config.app_command = "greatcmd"
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg}.start_with?(<<END)
GreatCommand (1.0.0) -- test app

Usage:
  $ greatcmd [<options>] [<action> [<arguments>...]]

Options:
END
      end

      spec "[!proa4] includes description of global options." do
        @config.app_version = "1.0.0"
        @config.option_debug = true
        app = Benry::CmdApp::Application.new(@config)
        msg = without_tty { app.help_message() }
        msg = uncolorize(msg)
        ok {msg}.include?(<<END)
Options:
  -h, --help         : print help message
  -V, --version      : print version
  -a, --all          : list all actions including private (hidden) ones
  -D, --debug        : debug mode (set $DEBUG_MODE to true)

Actions:
END
        #
        @config.app_version = nil
        @config.option_debug = false
        app = Benry::CmdApp::Application.new(@config)
        msg = without_tty { app.help_message() }
        msg = uncolorize(msg)
        ok {msg}.include?(<<END)
Options:
  -h, --help         : print help message
  -a, --all          : list all actions including private (hidden) ones

Actions:
END
      end

      spec "[!in3kf] ignores private (hidden) options." do
        @config.app_version = nil
        @config.option_debug = false
        app = Benry::CmdApp::Application.new(@config)
        schema = app.instance_variable_get('@schema')
        schema.add(:_log, "-L", "private option")
        msg = app.help_message()
        msg = uncolorize(msg)
        ok {msg} !~ /^  -L /
        ok {msg}.include?(<<END)
Options:
  -h, --help         : print help message
  -a, --all          : list all actions including private (hidden) ones

Actions:
END
      end

      spec "[!ywarr] not ignore private (hidden) options if 'all' flag is true." do
        @config.app_version = nil
        @config.option_debug = false
        app = Benry::CmdApp::Application.new(@config)
        schema = app.instance_variable_get('@schema')
        schema.add(:_log, "-L", "private option")
        msg = app.help_message(true)
        msg = uncolorize(msg)
        ok {msg} =~ /^  -L /
        ok {msg}.include?(<<END)
Options:
  -h, --help         : print help message
  -a, --all          : list all actions including private (hidden) ones
  -L                 : private option

Actions:
END
      end

      fixture :app3 do
        config = Benry::CmdApp::Config.new(nil)
        schema = Benry::CmdApp::AppOptionSchema.new(nil)
        schema.add(:help, "-h, --help", "print help message")
        app = Benry::CmdApp::Application.new(config, schema)
      end

      spec "[!p1tu9] prints option in weak format if option is hidden." do
        |app3|
        app3.schema.add(:_log, "-L", "private option")   # !!!
        msg = app3.help_message(true)
        ok {msg}.include?(<<END)
\e[34mOptions:\e[0m
  \e[1m-h, --help        \e[0m : print help message
  \e[1m\e[2m-L\e[0m                \e[0m : private option

END
      end

      spec "[!bm71g] ignores 'Options:' section if no options exist." do
        @config.option_help = false
        @config.option_all = false
        @config.app_version = nil
        @config.option_debug = false
        app = Benry::CmdApp::Application.new(@config)
        schema = app.instance_variable_get('@schema')
        schema.add(:_log, "-L", "private option")
        msg = app.help_message()
        msg = uncolorize(msg)
        ok {msg} !~ /^Options:$/
      end

      spec "[!jat15] includes action names ordered by name." do
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg}.end_with?(<<'END')
Actions:
  ya:ya              : greeting #2
  yes                : alias of 'yo-yo' action
  yo-yo              : greeting #1
END
      end

      spec "[!df13s] includes default action name if specified by config." do
        @config.default_action = nil
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg} =~ /^Actions:$/
        #
        @config.default_action = "yo-yo"
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg} =~ /^Actions: \(default: yo-yo\)$/
      end

      spec "[!b3l3m] not show private (hidden) action names in default." do
        msg = @builder.build_help_message()
        msg = uncolorize(msg)
        ok {msg} !~ /^  _aha /
        ok {msg} !~ /^  ya:_mada /
        ok {msg}.end_with?(<<END)
Actions:
  ya:ya              : greeting #2
  yes                : alias of 'yo-yo' action
  yo-yo              : greeting #1
END
      end

      spec "[!yigf3] shows private (hidden) action names if 'all' flag is true." do
        msg = @builder.build_help_message(true)
        msg = uncolorize(msg)
        ok {msg} =~ /^  _aha /
        ok {msg} =~ /^  ya:_mada /
        ok {msg}.end_with?(<<END)
Actions:
  _aha               : greeting #3
  ya:_mada           : greeting #4
  ya:ya              : greeting #2
  yes                : alias of 'yo-yo' action
  yo-yo              : greeting #1
END
      end

      spec "[!5d9mc] shows hidden action in weak format." do
        HelpMessageTest.class_eval { private :yo_yo }
        #
        begin
          msg = @builder.build_help_message(true)
          ok {msg}.end_with?(<<END)
\e[34mActions:\e[0m
  \e[1m_aha              \e[0m : greeting #3
  \e[1mya:_mada          \e[0m : greeting #4
  \e[1mya:ya             \e[0m : greeting #2
  \e[1m\e[2myes\e[0m               \e[0m : alias of 'yo-yo' action
  \e[1m\e[2myo-yo\e[0m             \e[0m : greeting #1
END
        ensure
          HelpMessageTest.class_eval { public :yo_yo }
        end
      end

      spec "[!awk3l] shows important action in strong format." do
        with_important("yo-yo"=>true) do
          msg = @builder.build_help_message()
          ok {msg}.end_with?(<<END)
\e[34mActions:\e[0m
  \e[1mya:ya             \e[0m : greeting #2
  \e[1m\e[4myes\e[0m               \e[0m : alias of 'yo-yo' action
  \e[1m\e[4myo-yo\e[0m             \e[0m : greeting #1
END
        end
      end

      spec "[!9k4dv] shows unimportant action in weak fomrat." do
        with_important("yo-yo"=>false) do
          msg = @builder.build_help_message()
          ok {msg}.end_with?(<<END)
\e[34mActions:\e[0m
  \e[1mya:ya             \e[0m : greeting #2
  \e[1m\e[2myes\e[0m               \e[0m : alias of 'yo-yo' action
  \e[1m\e[2myo-yo\e[0m             \e[0m : greeting #1
END
        end
      end

      spec "[!i04hh] includes postamble text if specified by config." do
        @config.help_postamble = "Home:\n  https://example.com/\n"
        msg = @builder.build_help_message()
        ok {msg}.end_with?(<<"END")
Home:
  https://example.com/
END
      end

      spec "[!ckagw] adds '\\n' at end of postamble text if it doesn't end with '\\n'." do
        @config.help_postamble = "END"
        msg = @builder.build_help_message()
        ok {msg}.end_with?("\nEND\n")
      end

      spec "[!oxpda] prints 'Aliases:' section only when 'config.help_aliases' is true." do
        app = Benry::CmdApp::Application.new(@config)
        #
        @config.help_aliases = true
        msg = app.help_message()
        msg = Benry::CmdApp::Util.del_escape_seq(msg)
        ok {msg}.end_with?(<<'END')
Actions:
  ya:ya              : greeting #2
  yo-yo              : greeting #1

Aliases:
  yes                : alias of 'yo-yo' action
END
        #
        @config.help_aliases = false
        msg = app.help_message()
        msg = Benry::CmdApp::Util.del_escape_seq(msg)
        ok {msg}.end_with?(<<'END')
Actions:
  ya:ya              : greeting #2
  yes                : alias of 'yo-yo' action
  yo-yo              : greeting #1
END
      end

      spec "[!kqnxl] array of section may have two or three elements." do
        @config.help_sections = [
          ["Example", "  $ echo foobar", "(see https://...)"],
          ["Tips", "  * foobar"],
        ]
        app = Benry::CmdApp::Application.new(@config)
        msg = app.help_message()
        ok {msg}.end_with?(<<"END")

\e[34mExample:\e[0m (see https://...)
  $ echo foobar

\e[34mTips:\e[0m
  * foobar
END
      end

    end


    topic '#build_aliases()' do

      class BuildAliasTest < Benry::CmdApp::ActionScope
        prefix "help25"
        @action.("test #1")
        def test1; end
        @action.("test #2")
        def test2; end
        @action.("test #3")
        def test3; end
        @action.("test #4")
        def test4; end
      end

      Benry::CmdApp.action_alias "h25t3", "help25:test3"
      Benry::CmdApp.action_alias "h25t1", "help25:test1"
      Benry::CmdApp.action_alias "_h25t4", "help25:test4"

      before do
        clear_index_except(BuildAliasTest)
      end

      after do
        restore_index()
      end

      def new_help_builder(**kws)
        config  = Benry::CmdApp::Config.new("test app", "1.2.3", **kws)
        schema  = Benry::CmdApp::AppOptionSchema.new(config)
        builder = Benry::CmdApp::AppHelpBuilder.new(config, schema)
        return builder
      end

      spec "[!tri8x] includes alias names in order of registration." do
        hb = new_help_builder(help_aliases: true)
        msg = hb.__send__(:build_aliases)
        ok {msg} == <<"END"
\e[34mAliases:\e[0m
  \e[1mh25t3             \e[0m : alias of 'help25:test3' action
  \e[1mh25t1             \e[0m : alias of 'help25:test1' action
END
      end

      spec "[!5g72a] not show hidden alias names in default." do
        hb = new_help_builder(help_aliases: true)
        msg = hb.__send__(:build_aliases)
        ok {msg} !~ /_h25t4/
      end

      spec "[!ekuqm] shows all alias names including private ones if 'all' flag is true." do
        hb = new_help_builder(help_aliases: true)
        msg = hb.__send__(:build_aliases, true)
        ok {msg} =~ /_h25t4/
        ok {msg} == <<"END"
\e[34mAliases:\e[0m
  \e[1mh25t3             \e[0m : alias of 'help25:test3' action
  \e[1mh25t1             \e[0m : alias of 'help25:test1' action
  \e[1m_h25t4            \e[0m : alias of 'help25:test4' action
END
      end

      spec "[!aey2k] shows alias in strong or weak format according to action." do
        with_important("help25:test1"=>true, "help25:test3"=>false) do
          hb = new_help_builder(help_aliases: true)
          msg = hb.__send__(:build_aliases, true)
          ok {msg} == <<"END"
\e[34mAliases:\e[0m
  \e[1m\e[2mh25t3\e[0m             \e[0m : alias of 'help25:test3' action
  \e[1m\e[4mh25t1\e[0m             \e[0m : alias of 'help25:test1' action
  \e[1m_h25t4            \e[0m : alias of 'help25:test4' action
END
        end
      end

      spec "[!p3oh6] now show 'Aliases:' section if no aliases defined." do
        Benry::CmdApp::INDEX.instance_variable_get('@aliases').clear()
        hb = new_help_builder(help_aliases: true)
        msg = hb.__send__(:build_aliases)
        ok {msg} == nil
      end

      spec "[!we1l8] shows 'Aliases:' section if any aliases defined." do
        hb = new_help_builder(help_aliases: true)
        msg = hb.__send__(:build_aliases)
        ok {msg} != nil
        ok {msg} == <<"END"
\e[34mAliases:\e[0m
  \e[1mh25t3             \e[0m : alias of 'help25:test3' action
  \e[1mh25t1             \e[0m : alias of 'help25:test1' action
END
      end

    end


  end


end
