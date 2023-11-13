# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative 'shared'


class HelpTestAction < Benry::CmdApp::Action

  @action.("preamble and postamble",
           detail: "See https://....",
           postamble: [{"Examples:"=>"  $ echo\n"}, "(Tips: blabla)"])
  def prepostamble()
  end

  @action.("no options")
  def noopt(aa, bb=nil)
    puts "aa=#{aa.inspect}, bb=#{bb.inspect}"
  end

  @action.("usage sample", usage: "input.txt > output.txt")
  def usagesample1(aa, bb, cc=nil)
  end

  @action.("usage sample", usage: ["input.txt | less", "input.txt > output.txt"])
  @option.(:file, "-f <file>", "filename")
  def usagesample2(aa, bb, cc=nil, file: nil)
  end

  @action.("arguments sample")
  @option.(:xx, "--xx", "XX")
  @option.(:yy, "--yy", "YY")
  def argsample(aa, bb, cc=nil, dd=nil, *rest, xx: nil, yy: nil)
    puts "aa=#{aa.inspect}, bb=#{bb.inspect}, cc=#{cc.inspect}, dd=#{dd.inspect}, rest=#{rest.inspect}, xx=#{xx.inspect}, yy=#{yy.inspect}"
  end

  category "secret:" do
    @action.("secret action", hidden: true)
    def crypt()
    end
  end

  category "descdemo:", "category description demo" do
    @action.("demo #1")
    def demo1()
    end
    @action.("demo #2")
    def demo2()
    end
  end

  ## alias test
  @action.("sample action")
  @option.(:aa, "-a, --aa", "option A")
  @option.(:bb, "    --bb", "option B")
  def alitest1(xx, yy=0, *zz, aa: nil, bb: nil)
  end
  define_alias "alitest1x", "alitest1"
  define_alias "alitest1y", ["alitest1", "--aa"]
  Benry::CmdApp.define_alias! "alitest1z", ["alitest1y", "foobar"]   # error

end


class HelpTestBuilder < Benry::CmdApp::BaseHelpBuilder
  HEADER_ACTIONS = "<ACTIONS>"
end


Oktest.scope do


  def with_dummy_registry(registry=nil, &b)
    registry ||= Benry::CmdApp::Registry.new()
    bkup = nil
    Benry::CmdApp.module_eval {
      bkup = const_get :REGISTRY
      remove_const :REGISTRY
      const_set :REGISTRY, registry
    }
    yield registry
    return registry
  ensure
    Benry::CmdApp.module_eval {
      remove_const :REGISTRY
      const_set :REGISTRY, bkup
    }
  end

  def new_registry_with_filter(*categories)
    idx = Benry::CmdApp::Registry.new()
    Benry::CmdApp::REGISTRY.metadata_each do |md|
      if md.name.start_with?(*categories)
        idx.metadata_add(md)
      end
    end
    return idx
  end


  topic Benry::CmdApp::BaseHelpBuilder do


    before do
      @config  = Benry::CmdApp::Config.new("test app", "1.2.3", app_command: "testapp")
      @builder = Benry::CmdApp::BaseHelpBuilder.new(@config)
    end


    topic '#build_help_message()' do

      spec "[!0hy81] this is an abstract method." do
        pr = proc { @builder.build_help_message(nil) }
        ok {pr}.raise?(NotImplementedError,
                       "Benry::CmdApp::BaseHelpBuilder#build_help_message(): not implemented yet.")
      end

    end


    topic '#build_section()' do

      spec "[!61psk] returns section string with decorating header." do
        s = @builder.__send__(:build_section, "Document:", "http://example.com/doc/\n")
        ok {s} == ("\e[1;34mDocument:\e[0m\n" \
                   "http://example.com/doc/\n")
      end

      spec "[!0o8w4] appends '\n' to content if it doesn't end with '\n'." do
        s = @builder.__send__(:build_section, "Document:", "http://...")
        ok {s} == ("\e[1;34mDocument:\e[0m\n" \
                   "http://...\n")
        ok {s}.end_with?("\n")
      end

    end


    topic '#build_sections()' do

      spec "[!tqau1] returns nil if value is nil or empty." do
        ok {@builder.__send__(:build_sections, nil, 'config.app_postamble')} == nil
        ok {@builder.__send__(:build_sections, [] , 'config.app_postamble')} == nil
      end

      spec "[!ezb0d] returns value unchanged if value is a string." do
        ok {@builder.__send__(:build_sections, "ABC\n", 'xxx')} == "ABC\n"
      end

      spec "[!gipxn] builds sections of help message if value is a hash object." do
        ok {@builder.__send__(:build_sections, {"Doc:"=>"ABC\n"}, 'xxx')} == <<"END"
\e[1;34mDoc:\e[0m
ABC
END
      end

      spec "[!944rt] raises ActionError if unexpected value found in value." do
        pr = proc { @builder.__send__(:build_sections, 123, 'xxx') }
        ok {pr}.raise?(Benry::CmdApp::ActionError,
                       "123: Unexpected value found in `xxx`.")
      end

    end


    topic '#build_option_help()' do

      before do
        @schema = Benry::CmdApp::ACTION_OPTION_SCHEMA_CLASS.new()
        #@schema.add(:help  , "-h, --help"  , "help message")
        @schema.add(:silent, "-s, --silent", "silent mode")
        @schema.add(:file  , "-f <file>"   , "filename")
        @schema.add(:debug , "    --debug" , "debug mode", hidden: true)
        config = Benry::CmdApp::Config.new("test app", "1.2.3")
        @format = config.format_option
      end

      spec "[!muhem] returns option part of help message." do
        x = @builder.__send__(:build_option_help, @schema, @format)
        ok {x} == <<"END"
  -s, --silent       : silent mode
  -f <file>          : filename
END
      end

      spec "[!4z70n] includes hidden options when `all: true` passed." do
        x = @builder.__send__(:build_option_help, @schema, @format, all: true)
        ok {x} == <<"END"
  -s, --silent       : silent mode
  -f <file>          : filename
\e[2m      --debug        : debug mode\e[0m
END
      end

      spec "[!hxy1f] includes `detail:` kwarg value with indentation." do
        @schema.add(:mode, "-m <mode>", "output mode", detail: <<END)
- v, verbose: print many output
- q, quiet:   print litte output
- c, compact: print summary output
END
        #
        x = @builder.__send__(:build_option_help, @schema, @format)
        ok {x} == <<"END"
  -s, --silent       : silent mode
  -f <file>          : filename
  -m <mode>          : output mode
                       - v, verbose: print many output
                       - q, quiet:   print litte output
                       - c, compact: print summary output
END
        #
        x = @builder.__send__(:build_option_help, @schema, "  %-15s # %s")
        ok {x} == <<"END"
  -s, --silent    # silent mode
  -f <file>       # filename
  -m <mode>       # output mode
                    - v, verbose: print many output
                    - q, quiet:   print litte output
                    - c, compact: print summary output
END
      end

      spec "[!jcqdf] returns nil if no options." do
        schema = Benry::CmdApp::ACTION_OPTION_SCHEMA_CLASS.new()
        x = @builder.__send__(:build_option_help, schema, @format)
        ok {x} == nil
      end

    end


    topic '#decorate_command()' do

      spec "[!zffx5] decorates command string." do
        x = @builder.__send__(:decorate_command, "cmdname")
        ok {x} == "\e[1mcmdname\e[0m"
      end

    end


    topic '#decorate_header()' do

      spec "[!4ufhw] decorates header string." do
        x = @builder.__send__(:decorate_header, "Header:")
        ok {x} == "\e[1;34mHeader:\e[0m"
      end

    end


    topic '#decorate_extra()' do

      spec "[!9nch4] decorates extra string." do
        x = @builder.__send__(:decorate_extra, "(default: 'git')")
        ok {x} == "\e[2m(default: 'git')\e[0m"
      end

    end


    topic '#decorate_str()' do

      spec "[!9qesd] decorates string if `hidden` is true." do
        b = @builder
        ok {b.__send__(:decorate_str, "FOOBAR", true, nil)}  == "\e[2mFOOBAR\e[0m"
        ok {b.__send__(:decorate_str, "FOOBAR", false, nil)} == "FOOBAR"
        ok {b.__send__(:decorate_str, "FOOBAR", nil, nil)}   == "FOOBAR"
      end

      spec "[!uql2d] decorates string if `important` is true." do
        b = @builder
        ok {b.__send__(:decorate_str, "FOOBAR", nil, true)} == "\e[1mFOOBAR\e[0m"
      end

      spec "[!mdhhr] decorates string if `important` is false." do
        b = @builder
        ok {b.__send__(:decorate_str, "FOOBAR", nil, false)} == "\e[2mFOOBAR\e[0m"
      end

      spec "[!6uzbi] not decorates string if `hidden` is falthy and `important` is nil." do
        b = @builder
        ok {b.__send__(:decorate_str, "FOOBAR", nil, nil)} == "FOOBAR"
      end

    end


    topic '#_header()' do

      spec "[!ep064] returns constant value defined in the class." do
        b = Benry::CmdApp::BaseHelpBuilder.new(nil)
        ok {b.__send__(:_header, :HEADER_ACTIONS)} == "Actions:"
      end

      spec "[!viwtn] constant value defined in child class is prior to one defined in parent class." do
        b = HelpTestBuilder.new(nil)
        ok {b.__send__(:_header, :HEADER_ACTIONS)} == "<ACTIONS>"
      end

    end


  end


  topic Benry::CmdApp::ApplicationHelpBuilder do

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.2.3",
                                          app_name: "TestApp", app_command: "testapp",
                                          option_verbose: true, option_quiet: true,
                                          option_color: true, #option_debug: true,
                                          option_trace: true)
      @builder = Benry::CmdApp::ApplicationHelpBuilder.new(@config)
    end


    topic '#build_help_message()' do

      spec "[!ezcs4] returns help message string of application." do
        gschema = Benry::CmdApp::GLOBAL_OPTION_SCHEMA_CLASS.new(@config)
        actual = @builder.build_help_message(gschema)
        expected = <<"END"
\e[1mTestApp\e[0m \e[2m(1.2.3)\e[0m --- test app

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] <action> [<arguments>...]

\e[1;34mOptions:\e[0m
  -h, --help         : print help message (of action if specified)
  -V, --version      : print version
  -l, --list         : list actions
  -a, --all          : list hidden actions/options, too
  -v, --verbose      : verbose mode
  -q, --quiet        : quiet mode
  --color[=<on|off>] : color mode
  -T, --trace        : trace mode

\e[1;34mActions:\e[0m
END
        ok {actual}.start_with?(expected)
        ok {actual} !~ /^ *--debug/
      end

      spec "[!ntj2y] includes hidden actions and options if `all: true` passed." do
        @config.option_debug = true
        gschema = Benry::CmdApp::GLOBAL_OPTION_SCHEMA_CLASS.new(@config)
        actual = @builder.build_help_message(gschema)
        expected = <<"END"
\e[1mTestApp\e[0m \e[2m(1.2.3)\e[0m --- test app

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] <action> [<arguments>...]

\e[1;34mOptions:\e[0m
  -h, --help         : print help message (of action if specified)
  -V, --version      : print version
  -l, --list         : list actions
  -a, --all          : list hidden actions/options, too
  -v, --verbose      : verbose mode
  -q, --quiet        : quiet mode
  --color[=<on|off>] : color mode
      --debug        : debug mode
  -T, --trace        : trace mode

\e[1;34mActions:\e[0m
END
        ok {actual}.start_with?(expected)
        ok {actual} =~ /^ +--debug +: debug mode$/
      end

    end


    topic '#build_preamble_part()' do

      spec "[!51v42] returns preamble part of application help message." do
        x = @builder.__send__(:build_preamble_part)
        ok {x} == "\e[1mTestApp\e[0m \e[2m(1.2.3)\e[0m --- test app\n"
      end

      spec "[!bmh17] includes `config.app_name` or `config.app_command` into preamble." do
        @config.app_name = "TestApp"
        @config.app_command = "testapp"
        x = @builder.__send__(:build_preamble_part)
        ok {x} == "\e[1mTestApp\e[0m \e[2m(1.2.3)\e[0m --- test app\n"
        #
        @config.app_name = nil
        x = @builder.__send__(:build_preamble_part)
        ok {x} == "\e[1mtestapp\e[0m \e[2m(1.2.3)\e[0m --- test app\n"
      end

      spec "[!opii8] includes `config.app_versoin` into preamble if it is set." do
        @config.app_version = "3.4.5"
        x = @builder.__send__(:build_preamble_part)
        ok {x} == "\e[1mTestApp\e[0m \e[2m(3.4.5)\e[0m --- test app\n"
        #
        @config.app_version = nil
        x = @builder.__send__(:build_preamble_part)
        ok {x} == "\e[1mTestApp\e[0m --- test app\n"
      end

      spec "[!3h380] includes `config.app_detail` into preamble if it is set." do
        @config.app_detail = "https://www.example.com/"
        x = @builder.__send__(:build_preamble_part)
        ok {x} == <<"END"
\e[1mTestApp\e[0m \e[2m(1.2.3)\e[0m --- test app

https://www.example.com/
END
      end

    end


    topic '#build_postamble_part()' do

      spec "[!64hj1] returns postamble of application help message." do
        @config.help_postamble = [
          {"Examples:" => "  $ echo yes\n  yes\n"},
          "(Tips: blablabla)",
        ]
        x = @builder.__send__(:build_postamble_part)
        ok {x} == <<"END"
\e[1;34mExamples:\e[0m
  $ echo yes
  yes

(Tips: blablabla)
END
      end

      spec "[!z5k2w] returns nil if postamble not set." do
        x = @builder.__send__(:build_postamble_part)
        ok {x} == nil
      end

    end


    topic '#build_usage_part()' do

      spec "[!h98me] returns 'Usage:' section of application help message." do
        x = @builder.__send__(:build_usage_part)
        ok {x} == <<"END"
\e[1;34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] <action> [<arguments>...]
END
      end

      spec "[!i9d4r] includes `config.app_usage` into help message if it is set." do
        @config.app_usage = "<command> [<args>...]"
        x = @builder.__send__(:build_usage_part)
        ok {x} == <<"END"
\e[1;34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] <command> [<args>...]
END
      end

    end


    topic '#build_options_part()' do

      spec "[!f2n70] returns 'Options:' section of application help message." do
        gschema = Benry::CmdApp::GLOBAL_OPTION_SCHEMA_CLASS.new(@config)
        x = @builder.__send__(:build_options_part, gschema)
        ok {x} == <<"END"
\e[1;34mOptions:\e[0m
  -h, --help         : print help message (of action if specified)
  -V, --version      : print version
  -l, --list         : list actions
  -a, --all          : list hidden actions/options, too
  -v, --verbose      : verbose mode
  -q, --quiet        : quiet mode
  --color[=<on|off>] : color mode
  -T, --trace        : trace mode
END
        ok {x} !~ /--debug/
      end

      spec "[!0bboq] includes hidden options into help message if `all: true` passed." do
        gschema = Benry::CmdApp::GLOBAL_OPTION_SCHEMA_CLASS.new(@config)
        x = @builder.__send__(:build_options_part, gschema, all: true)
        ok {x} == <<"END"
\e[1;34mOptions:\e[0m
  -h, --help         : print help message (of action if specified)
  -V, --version      : print version
  -l, --list         : list actions
\e[2m  -L <topic>         : list of a topic (action|alias|category|abbrev)\e[0m
  -a, --all          : list hidden actions/options, too
  -v, --verbose      : verbose mode
  -q, --quiet        : quiet mode
  --color[=<on|off>] : color mode
\e[2m      --debug        : debug mode\e[0m
  -T, --trace        : trace mode
END
        ok {x} =~ /--debug/
      end

      spec "[!fjhow] returns nil if no options." do
        gschema = Benry::CmdApp::ACTION_OPTION_SCHEMA_CLASS.new
        x = @builder.__send__(:build_options_part, gschema)
        ok {x} == nil
      end

    end


    topic '#build_actions_part()' do

      spec "[!typ67] returns 'Actions:' section of help message." do
        x = @builder.__send__(:build_actions_part)
        ok {x} =~ /\A\e\[1;34mActions:\e\[0m$/
      end

      spec "[!yn8ea] includes hidden actions into help message if `all: true` passed." do
        x = @builder.__send__(:build_actions_part, all: true)
        ok {x} =~ /debuginfo/
        ok {x} =~ /^\e\[2m  debuginfo          : hidden action\e\[0m$/
        #
        x = @builder.__send__(:build_actions_part)
        ok {x} !~ /debuginfo/
      end

      spec "[!10qp0] includes aliases if the 1st argument is true." do
        x = @builder.__send__(:build_actions_part, true, all: true)
        ok {x} =~ /alias of/
        #
        x = @builder.__send__(:build_actions_part, false, all: true)
        ok {x} !~ /alias of/
      end

      spec "[!24by5] returns nil if no actions defined." do
        debuginfo_md = Benry::CmdApp::REGISTRY.metadata_get("debuginfo")
        hello_md     = Benry::CmdApp::REGISTRY.metadata_get("hello")
        registry = Benry::CmdApp::Registry.new()
        with_dummy_registry(registry) do
          #
          x = @builder.__send__(:build_actions_part)
          ok {x} == nil
          #
          registry.metadata_add(debuginfo_md)
          x = @builder.__send__(:build_actions_part)
          ok {x} == nil
          x = @builder.__send__(:build_actions_part, all: true)
          ok {x} == <<"END"
\e[1;34mActions:\e[0m
\e[2m  debuginfo          : hidden action\e[0m
END
          #
          registry.metadata_add(hello_md)
          x = @builder.__send__(:build_actions_part)
          ok {x} == <<"END"
\e[1;34mActions:\e[0m
  hello              : greeting message
END
          x = @builder.__send__(:build_actions_part, all: true)
          ok {x} == <<"END"
\e[1;34mActions:\e[0m
\e[2m  debuginfo          : hidden action\e[0m
  hello              : greeting message
END
        end
      end

      spec "[!8qz6a] adds default action name after header if it is set." do
        @config.default_action = "help"
        x = @builder.__send__(:build_actions_part)
        ok {x} =~ /\A\e\[1;34mActions:\e\[0m \e\[2m\(default: help\)\e\[0m$/
        #
        @config.default_action = "hello"
        x = @builder.__send__(:build_actions_part)
        ok {x} =~ /\A\e\[1;34mActions:\e\[0m \e\[2m\(default: hello\)\e\[0m$/
      end

    end


    topic '#_build_metadata_list()' do

      spec "[!iokkp] builds list of actions or aliases." do
        format = "%s : %s"
        output = @builder.__send__(:_build_metadata_list, format) { true }
        ok {output} =~ /^hello : greeting message$/
      end

      spec "[!grwkj] filters by block." do
        format = "%s : %s"
        output = @builder.__send__(:_build_metadata_list, format) {|md| md.alias? }
        ok {output} !~ /^hello : greeting message$/
        ok {output} =~ /alias of/
        output = @builder.__send__(:_build_metadata_list, format) {|md| ! md.alias? }
        ok {output} =~ /^hello : greeting message$/
        ok {output} !~ /alias of/
      end

      spec "[!hv7or] if action has any aliases, print them below of the action." do
        format = "  %-18s : %s"
        include_aliases = true
        output = @builder.instance_eval{
          _build_metadata_list(format, include_aliases) {|md| ! md.alias? }
        }
        ok {output} =~ /^\e\[2m +\(alias: .*\)\e\[0m$/
      end

    end


    topic '#build_candidates_part()' do

      spec "[!3c3f1] returns list of actions which name starts with prefix specified." do
        x = @builder.build_candidates_part("git:")
        ok {x} == <<"END"
\e[1;34mActions:\e[0m
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`
END
      end

      spec "[!idm2h] includes hidden actions when `all: true` passed." do
        x = @builder.build_candidates_part("git:", all: true)
        ok {x} == <<"END"
\e[1;34mActions:\e[0m
\e[2m  git:correct        : same as `git commit --amend`\e[0m
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`
END
      end

      spec "[!duhyd] includes actions which name is same as prefix." do
        HelpTestAction.class_eval do
          category "p8572:", action: "aaa" do
            @action.("AAA")
            def aaa()
            end
            @action.("BBB")
            def bbb()
            end
          end
          @action.("sample")
          def p8572x()
          end
        end
        x = @builder.build_candidates_part("p8572:")
        ok {x} == <<"END"
\e[1;34mActions:\e[0m
  p8572              : AAA
  p8572:bbb          : BBB
END
      end

      spec "[!nwwrd] if prefix is 'xxx:' and alias name is 'xxx' and action name of alias matches to 'xxx:', skip it because it will be shown in 'Aliases:' section." do
        Benry::CmdApp.define_alias("git", "git:stage")
        at_end { Benry::CmdApp.undef_alias("git") }
        x = @builder.build_candidates_part("git:")
        ok {x} == <<"END"
\e[1;34mActions:\e[0m
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`

\e[1;34mAliases:\e[0m
  git                : alias of 'git:stage'
END
      end

      spec "[!otvbt] includes name of alias which corresponds to action starting with prefix." do
        Benry::CmdApp.define_alias("add", "git:stage")
        at_end { Benry::CmdApp.undef_alias("add") }
        x = @builder.build_candidates_part("git:")
        ok {x} == <<"END"
\e[1;34mActions:\e[0m
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`

\e[1;34mAliases:\e[0m
  add                : alias of 'git:stage'
END
      end

      spec "[!h5ek7] includes hidden aliases when `all: true` passed." do
        Benry::CmdApp.define_alias("add", "git:stage", hidden: true)
        at_end { Benry::CmdApp.undef_alias("add") }
        x = @builder.build_candidates_part("git:", all: true)
        ok {x} == <<"END"
\e[1;34mActions:\e[0m
\e[2m  git:correct        : same as `git commit --amend`\e[0m
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`

\e[1;34mAliases:\e[0m
\e[2m  add                : alias of 'git:stage'\e[0m
END
        #
        x = @builder.build_candidates_part("git:")
        ok {x} == <<"END"
\e[1;34mActions:\e[0m
  git:stage          : same as `git add -p`
  git:staged         : same as `git diff --cached`
  git:unstage        : same as `git reset HEAD`
END
      end

      spec "[!80t51] alias names are displayed in separated section from actions." do
        Benry::CmdApp.define_alias("add", "git:stage")
        at_end { Benry::CmdApp.undef_alias("add") }
        x = @builder.build_candidates_part("git:")
        ok {x} =~ /^\e\[1;34mAliases:\e\[0m$/
      end

      spec "[!rqx7w] returns header string if both no actions nor aliases found with names starting with prefix." do
        x = @builder.build_candidates_part("blabla:")
        ok {x} == "\e[1;34mActions:\e[0m\n\n"
      end

    end


    topic '#build_aliases_part()' do

      spec "[!496qq] renders alias list." do
        Benry::CmdApp.define_alias("a9208", "hello")
        x = @builder.build_aliases_part()
        ok {x} =~ /\A\e\[1;34mAliases:\e\[0m\n/
        ok {x} =~ /^  a9208 +: alias of 'hello'$/
      end

      spec "[!fj1c7] returns header string if no aliases found." do
        registry = Benry::CmdApp::Registry.new()
        @builder.instance_variable_set(:@_registry, registry)
        x = @builder.build_aliases_part()
        ok {x} == "\e[1;34mAliases:\e[0m\n\n"
        registry.metadata_add(Benry::CmdApp::REGISTRY.metadata_get("hello"))
        registry.metadata_add(Benry::CmdApp::AliasMetadata.new("h1", "hello", []))
        x = @builder.build_aliases_part()
        ok {x} != nil
        ok {x} == <<"END"
\e[1;34mAliases:\e[0m
  h1                 : alias of 'hello'
END
      end

      spec "[!d7vee] ignores hidden aliases in default." do
        Benry::CmdApp.define_alias("a4904", "hello", hidden: true)
        x = @builder.build_aliases_part()
        ok {x} =~ /\A\e\[1;34mAliases:\e\[0m\n/
        ok {x} !~ /a4904/
      end

      spec "[!4vvrs] include hidden aliases if `all: true` specifieid." do
        Benry::CmdApp.define_alias("a4612", "hello", hidden: true)
        x = @builder.build_aliases_part(all: true)
        ok {x} =~ /\A\e\[1;34mAliases:\e\[0m\n/
        ok {x} =~ /^\e\[2m  a4612 +: alias of 'hello'\e\[0m$/
      end

      spec "[!v211d] sorts aliases by action names." do
        old_registry = Benry::CmdApp::REGISTRY
        names = ["hello", "debuginfo", "testerr1", "git:stage", "git:staged", "git:unstage"]
        output = nil
        with_dummy_registry do |new_registry|
          names.each {|name| new_registry.metadata_add(old_registry.metadata_get(name)) }
          Benry::CmdApp.define_alias("a1", "git:unstage")
          Benry::CmdApp.define_alias("a2", "git:stage")
          Benry::CmdApp.define_alias("a3", "git:staged")
          Benry::CmdApp.define_alias("a6", "git:staged")
          Benry::CmdApp.define_alias("a5", "git:staged")
          Benry::CmdApp.define_alias("a4", "git:staged")
          Benry::CmdApp.define_alias("a7", "testerr1")
          Benry::CmdApp.define_alias("a8", "debuginfo")
          Benry::CmdApp.define_alias("a9", "hello")
          output = @builder.build_aliases_part()
        end
        ok {output} == <<"END"
\e[1;34mAliases:\e[0m
  a8                 : alias of 'debuginfo'
  a2                 : alias of 'git:stage'
  a3                 : alias of 'git:staged'
  a4                 : alias of 'git:staged'
  a5                 : alias of 'git:staged'
  a6                 : alias of 'git:staged'
  a1                 : alias of 'git:unstage'
  a9                 : alias of 'hello'
  a7                 : alias of 'testerr1'
END
      end

    end


    topic '#build_abbrevs_part()' do

      spec "[!00ice] returns abbrev list string." do
        Benry::CmdApp.define_abbrev("g25:", "git:")
        x = @builder.build_abbrevs_part()
        ok {x} =~ /\A\e\[1;34mAbbreviations:\e\[0m\n/
        ok {x} =~ /^  g25: +=> +git:\n/
      end

      spec "[!dnt12] returns header string if no abbrevs found." do
        registry = Benry::CmdApp::Registry.new()
        @builder.instance_variable_set(:@_registry, registry)
        ok {@builder.build_abbrevs_part()} == "\e[1;34mAbbreviations:\e[0m\n\n"
        registry.abbrev_add("g26:", "git:")
        ok {@builder.build_abbrevs_part()} == <<END
\e[1;34mAbbreviations:\e[0m
  g26:       =>  git:
END
      end

    end


    topic '#build_categories_part()' do

      spec "[!crbav] returns top prefix list." do
        x = @builder.build_categories_part(1)
        ok {x} =~ /\A\e\[1;34mCategories:\e\[0m \e\[2m\(depth=\d+\)\e\[0m\n/
        ok {x} =~ /^  git: \(\d+\)\n/
      end

      spec "[!alteh] includes prefix of hidden actions if `all: true` passed." do
        x = @builder.build_categories_part(1, all: true)
        ok {x} =~ /^  secret:/
        x = @builder.build_categories_part(1)
        ok {x} !~ /^  secret:/
      end

      spec "[!p4j1o] returns nil if no prefix found." do
        registry = Benry::CmdApp::Registry.new
        ["hello", "secret:crypt"].each do |action|
          registry.metadata_add(Benry::CmdApp::REGISTRY.metadata_get(action))
        end
        #
        with_dummy_registry(registry) do
          x = @builder.build_categories_part()
          ok {x} == nil
          x = @builder.build_categories_part(all: true)
          ok {x} != nil
        end
      end

      spec "[!30l2j] includes number of actions per prefix." do
        x = @builder.build_categories_part(all: true)
        ok {x} =~ /^  git: \(\d+\)\n/
        ok {x} =~ /^  secret: \(\d+\)\n/
      end

      spec "[!qxoja] includes category description if registered." do
        x = @builder.build_categories_part(all: true)
        ok {x} =~ /^  descdemo: \(2\)      : category description demo$/
      end

      spec "[!k3y6q] uses `config.format_category` or `config.format_action`." do
        @config.format_category = "  %-15s # %s"
        x = @builder.build_categories_part(all: true)
        ok {x} =~ /^  descdemo: \(2\)   # category description demo\n/
        #
        @config.format_category = nil
        @config.format_category = "    %-15s -- %s"
        x = @builder.build_categories_part(all: true)
        ok {x} =~ /^    descdemo: \(2\)   -- category description demo$/
      end

    end


  end


  topic Benry::CmdApp::ActionHelpBuilder do

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.2.3",
                                          app_name: "TestApp", app_command: "testapp",
                                          option_verbose: true, option_quiet: true,
                                          option_color: true, #option_debug: true,
                                          option_trace: true)
      @builder = Benry::CmdApp::ActionHelpBuilder.new(@config)
      @registry = Benry::CmdApp::REGISTRY
    end

    topic '#build_help_message()' do

      spec "[!f3436] returns help message of an action." do
        metadata = @registry.metadata_get("hello")
        x = @builder.build_help_message(metadata)
        ok {x}.start_with?(<<"END")
\e[1mtestapp hello\e[0m --- greeting message

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp hello\e[0m [<options>] [<name>]

\e[1;34mOptions:\e[0m
  -l, --lang=<lang>  : language name (en/fr/it)
END
      end

      spec "[!8acs1] includes hidden options if `all: true` passed." do
        metadata = @registry.metadata_get("debuginfo")
        x = @builder.build_help_message(metadata, all: true)
        ok {x} == <<"END"
\e[1mtestapp debuginfo\e[0m --- hidden action

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp debuginfo\e[0m [<options>]

\e[1;34mOptions:\e[0m
\e[2m  -h, --help         : print help message\e[0m
\e[2m  --val=<val>        : something value\e[0m
END
      end

      spec "[!mtvw8] includes 'Aliases:' section if action has any aliases." do
        metadata = @registry.metadata_get("alitest1")
        output = @builder.build_help_message(metadata, all: true)
        ok {output} == <<"END"
\e[1mtestapp alitest1\e[0m --- sample action

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp alitest1\e[0m [<options>] <xx> [<yy> [<zz>...]]

\e[1;34mOptions:\e[0m
\e[2m  -h, --help         : print help message\e[0m
  -a, --aa           : option A
      --bb           : option B

\e[1;34mAliases:\e[0m
  alitest1x          : alias of 'alitest1'
  alitest1y          : alias of 'alitest1 --aa'
  alitest1z          : alias of 'alitest1 --aa foobar'
END
      end

      spec "[!vcg9w] not include 'Options:' section if action has no options." do
        metadata = @registry.metadata_get("noopt")
        x = @builder.build_help_message(metadata, all: true)
        ok {x} == <<"END"
\e[1mtestapp noopt\e[0m --- no options

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp noopt\e[0m [<options>] <aa> [<bb>]

\e[1;34mOptions:\e[0m
\e[2m  -h, --help         : print help message\e[0m
END
      end

      spec "[!1auu5] not include '[<options>]' in 'Usage:'section if action has no options." do
        metadata = @registry.metadata_get("debuginfo")
        x = @builder.build_help_message(metadata)
        ok {x} == <<"END"
\e[1mtestapp debuginfo\e[0m --- hidden action

\e[1;34mUsage:\e[0m
  $ \e[1mtestapp debuginfo\e[0m
END
      end

    end


    topic '#build_preamble_part()' do

      spec "[!a6nk4] returns preamble of action help message." do
        metadata = @registry.metadata_get("hello")
        x = @builder.__send__(:build_preamble_part, metadata)
        ok {x} == <<"END"
\e[1mtestapp hello\e[0m --- greeting message
END
      end

      spec "[!imxdq] includes `config.app_command`, not `config.app_name`, into preamble." do
        @config.app_name    = "TestApp1"
        @config.app_command = "testapp1"
        metadata = @registry.metadata_get("hello")
        x = @builder.__send__(:build_preamble_part, metadata)
        ok {x} == <<"END"
\e[1mtestapp1 hello\e[0m --- greeting message
END
      end

      spec "[!7uy4f] includes `detail:` kwarg value of `@action.()` if specified." do
        @config.app_command = "testapp1"
        metadata = @registry.metadata_get("prepostamble")
        x = @builder.__send__(:build_preamble_part, metadata)
        ok {x} == <<"END"
\e[1mtestapp1 prepostamble\e[0m --- preamble and postamble

See https://....
END
      end

    end


    topic '#build_usage_part()' do

      spec "[!jca5d] not add '[<options>]' if action has no options." do
        metadata = @registry.metadata_get("noopt")
        x = @builder.__send__(:build_usage_part, metadata)
        ok {x}.NOT.include?("[<options>]")
        ok {x} == <<"END"
\e[1;34mUsage:\e[0m
  $ \e[1mtestapp noopt\e[0m <aa> [<bb>]
END
        #
        metadata = @registry.metadata_get("debuginfo")   # has a hidden option
        x = @builder.__send__(:build_usage_part, metadata)
        ok {x}.NOT.include?("[<options>]")
        ok {x} == <<"END"
\e[1;34mUsage:\e[0m
  $ \e[1mtestapp debuginfo\e[0m
END
      end

      spec "[!h5bp4] if `usage:` kwarg specified in `@action.()`, use it as usage string." do
        metadata = @registry.metadata_get("usagesample1")
        x = @builder.__send__(:build_usage_part, metadata)
        ok {x} == <<"END"
\e[1;34mUsage:\e[0m
  $ \e[1mtestapp usagesample1\e[0m input.txt > output.txt
END
      end

      spec "[!nfuxz] `usage:` kwarg can be a string or an array of string." do
        metadata = @registry.metadata_get("usagesample2")
        x = @builder.__send__(:build_usage_part, metadata)
        ok {x} == <<"END"
\e[1;34mUsage:\e[0m
  $ \e[1mtestapp usagesample2\e[0m [<options>] input.txt | less
  $ \e[1mtestapp usagesample2\e[0m [<options>] input.txt > output.txt
END
      end

      spec "[!z3lh9] if `usage:` kwarg not specified in `@action.()`, generates usage string from method parameters." do
        metadata = @registry.metadata_get("argsample")
        x = @builder.__send__(:build_usage_part, metadata)
        ok {x}.include?("[<options>] <aa> <bb> [<cc> [<dd> [<rest>...]]]")
      end

      spec "[!iuctx] returns 'Usage:' section of action help message." do
        metadata = @registry.metadata_get("argsample")
        x = @builder.__send__(:build_usage_part, metadata)
        ok {x} == <<"END"
\e[1;34mUsage:\e[0m
  $ \e[1mtestapp argsample\e[0m [<options>] <aa> <bb> [<cc> [<dd> [<rest>...]]]
END
      end

    end


    topic '#build_options_part()' do

      spec "[!pafgs] returns 'Options:' section of help message." do
        metadata = @registry.metadata_get("hello")
        x = @builder.__send__(:build_options_part, metadata)
        ok {x} == <<"END"
\e[1;34mOptions:\e[0m
  -l, --lang=<lang>  : language name (en/fr/it)
END
      end

      spec "[!85wus] returns nil if action has no options." do
        metadata = @registry.metadata_get("noopt")
        x = @builder.__send__(:build_options_part, metadata)
        ok {x} == nil
      end

    end


    topic '#build_aliases_part()' do

      spec "[!kjpt9] returns 'Aliases:' section of help message." do
        action = "alitest1"
        x = @registry.metadata_each.any? {|md| md.alias? && md.action == action }
        ok {x} == true
        #
        metadata = @registry.metadata_get("alitest1")
        output = @builder.__send__(:build_aliases_part, metadata)
        ok {output} == <<"END"
\e[1;34mAliases:\e[0m
  alitest1x          : alias of 'alitest1'
  alitest1y          : alias of 'alitest1 --aa'
  alitest1z          : alias of 'alitest1 --aa foobar'
END
      end

      spec "[!cjr0q] returns nil if action has no options." do
        action = "argsample"
        x = @registry.metadata_each.any? {|md| md.alias? && md.action == action }
        ok {x} == false
        #
        metadata = @registry.metadata_get(action)
        output = @builder.__send__(:build_aliases_part, metadata)
        ok {output} == nil
      end

    end


    topic '#build_postamble_part()' do

      spec "[!q1jee] returns postamble of help message if `postamble:` kwarg specified in `@action.()`." do
        metadata = @registry.metadata_get("prepostamble")
        x = @builder.__send__(:build_postamble_part, metadata)
        ok {x} == <<"END"
\e[1;34mExamples:\e[0m
  $ echo

(Tips: blabla)
END
      end

      spec "[!jajse] returns nil if postamble is not set." do
        metadata = @registry.metadata_get("hello")
        x = @builder.__send__(:build_postamble_part, metadata)
        ok {x} == nil
      end

    end


  end


end
