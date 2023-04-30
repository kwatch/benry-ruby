# -*- coding: utf-8 -*-

require 'oktest'

require 'benry/cmdapp'


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
      sc.add(:_help, "-h", "help")
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


end


topic Benry::CmdApp::Index do


  class IndexTestAction < Benry::CmdApp::Action
    @action.("lookup test #1")
    def lookup1(user="world", repeat: nil); end
    #
    @action.("lookup test #2")
    def lookup2(); end
    #
    private
    @action.("lookup test #3")   # hidden
    def lookup3(); end
  end

  Benry::CmdApp.action_alias("findxx", "lookup2")


  topic '.lookup_action()' do

    spec "[!vivoa] returns action metadata object." do
      x = Benry::CmdApp::Index.lookup_action("lookup1")
      ok {x} != nil
      ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
      ok {x.name} == "lookup1"
      ok {x.klass} == IndexTestAction
      ok {x.method} == :lookup1
    end

    spec "[!tnwq0] supports alias name." do
      x = Benry::CmdApp::Index.lookup_action("findxx")
      ok {x} != nil
      ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
      ok {x.name} == "lookup2"
      ok {x.klass} == IndexTestAction
      ok {x.method} == :lookup2
    end

    spec "[!z15vu] returns ActionWithArgs object if alias has args and/or kwargs." do
      Benry::CmdApp.action_alias("findyy1", "lookup1", ["Alice"], {repeat: 3})
      x = Benry::CmdApp::Index.lookup_action("findyy1")
      ok {x} != nil
      ok {x}.is_a?(Benry::CmdApp::ActionWithArgs)
      ok {x.args} == ["Alice"]
      ok {x.kwargs} == {repeat: 3}
      ok {x.name} == "lookup1"
      ok {x.klass} == IndexTestAction
      ok {x.method} == :lookup1
    end

  end


  topic '.each_action_name_and_desc()' do

    before do
      @_bkup_actions = Benry::CmdApp::Index::ACTIONS.dup()
      Benry::CmdApp::Index::ACTIONS.delete_if {|_, x| x.klass != IndexTestAction }
      anames = Benry::CmdApp::Index::ACTIONS.keys()
      @_bkup_aliases = Benry::CmdApp::Index::ALIASES.dup()
      Benry::CmdApp::Index::ALIASES.delete_if {|_, x| ! anames.include?(x.action_name) }
    end

    after do
      Benry::CmdApp::Index::ACTIONS.update(@_bkup_actions)
      Benry::CmdApp::Index::ALIASES.update(@_bkup_aliases)
    end

    spec "[!5lahm] yields action name and description." do
      arr = []
      Benry::CmdApp::Index.each_action_name_and_desc(false) {|a| arr << a }
      ok {arr} == [
        ["lookup1", "lookup test #1"],
        ["lookup2", "lookup test #2"],
      ]
    end

    spec "[!27j8b] includes alias names when the first arg is true." do
      arr = []
      Benry::CmdApp::Index.each_action_name_and_desc(true) {|a| arr << a }
      ok {arr} == [
        ["findxx", "alias of 'lookup2' action"],
        ["findyy1", "alias of 'lookup1' action"],
        ["lookup1", "lookup test #1"],
        ["lookup2", "lookup test #2"],
      ]
    end

    spec "[!8xt8s] rejects hidden actions if 'all: false' kwarg specified." do
      arr = []
      Benry::CmdApp::Index.each_action_name_and_desc(false, all: false) {|a| arr << a }
      ok {arr} == [
        ["lookup1", "lookup test #1"],
        ["lookup2", "lookup test #2"],
      ]
    end

    spec "[!5h7s5] includes hidden actions if 'all: true' kwarg specified." do
      arr = []
      Benry::CmdApp::Index.each_action_name_and_desc(false, all: true) {|a| arr << a }
      ok {arr} == [
        ["lookup1", "lookup test #1"],
        ["lookup2", "lookup test #2"],
        ["lookup3", "lookup test #3"],   # hidden action
      ]
    end

    spec "[!arcia] action names are sorted." do
      arr = []
      Benry::CmdApp::Index.each_action_name_and_desc(true) {|a| arr << a }
      ok {arr} == arr.sort_by(&:first)
    end

  end


end


module CommonTestingHelper

  def uncolorize(str)
    return str.gsub(/\e\[.*?m/, '')
  end

  def without_tty(&block)
    result = nil
    capture_sio(tty: false) { result = yield }
    return result
  end

  def with_tty(&block)
    result = nil
    capture_sio(tty: true) { result = yield }
    return result
  end

end


module ActionMetadataTestingHelper
  include CommonTestingHelper

  def new_schema(lang: true)
    schema = Benry::Cmdopt::Schema.new
    schema.add(:lang, "-l, --lang=<en|fr|it>", "language") if lang
    return schema
  end

  def new_metadata(schema, meth=:halo1, **kwargs)
    metadata = Benry::CmdApp::ActionMetadata.new(meth.to_s, MetadataTestAction, meth, "greeting", schema, **kwargs)
    return metadata
  end

end


topic Benry::CmdApp::ActionMetadata do
  #include CommonTestingHelper         # not work. why?
  include ActionMetadataTestingHelper

  class MetadataTestAction < Benry::CmdApp::Action

    @action.("print greeting message")
    @option.(:lang, "-l, --lang=<en|fr|it>", "language")
    def halo1(user="world", lang: "en")
      case lang
      when "en" ;  puts "Hello, #{user}!"
      when "fr" ;  puts "Bonjour, #{user}!"
      when "it" ;  puts "Ciao, #{user}!"
      else      ;  raise "#{lang}: unknown language."
      end
    end

    @action.("print greeting message")
    @option.(:lang, "-l, --lang=<en|fr|it>", "language")
    def halo2(user="world", *users, lang: "en")
      puts "user=#{user.inspect}, users=#{users.inspect}"
    end

    @action.("no arguments")
    @option.(:lang, "-l, --lang=<en|fr|it>", "language")
    def halo3(lang: "en")
      puts "lang=#{lang}"
    end

    def args1(aa, bb, xx: nil); end                   # required arg
    def args2(aa, bb=nil, cc=nil, xx: nil); end       # optional arg
    def args3(aa, bb=nil, cc=nil, *dd, xx: nil); end  # variable arg
    def args4(xx_or_yy_or_zz); end                    # xx|yy|zz
    def args5(_xx_yy_zz); end                         # _xx-yy-zz

  end


  before do
    schema = Benry::Cmdopt::Schema.new
    schema.add(:lang, "-l, --lang=<en|fr|it>", "language")
    @metadata = Benry::CmdApp::ActionMetadata.new("halo1", MetadataTestAction, :halo1, "greeting", schema)
  end


  topic '#hidden?()' do

    class HiddenTestAction < Benry::CmdApp::Action
      @action.("public")
      def pphidden1(); puts __method__(); end
      #
      @action.("private")
      def pphidden2(); puts __method__(); end
      private :pphidden2
      #
      private
      @action.("private")
      def pphidden3(); puts __method__(); end
    end

    spec "[!kp10p] returns true when action method is private." do
      ameta = Benry::CmdApp::Index::ACTIONS["pphidden3"]
      ok {ameta.hidden?} == true
      ameta = Benry::CmdApp::Index::ACTIONS["pphidden2"]
      ok {ameta.hidden?} == true
    end

    spec "[!nw322] returns false when action method is not private." do
      ameta = Benry::CmdApp::Index::ACTIONS["pphidden1"]
      ok {ameta.hidden?} == false
    end

  end


  topic '#parse_options()' do

    spec "[!ab3j8] parses argv and returns options." do
      args = ["-l", "fr", "Alice"]
      opts = @metadata.parse_options(args)
      ok {opts} == {:lang => "fr"}
      ok {args} == ["Alice"]
      args = ["--lang=it", "Bob"]
      opts = @metadata.parse_options(args)
      ok {opts} == {:lang => "it"}
      ok {args} == ["Bob"]
    end

    spec "[!56da8] raises InvalidOptionError if option value is invalid." do
      args = ["-x", "fr", "Alice"]
      pr = proc { @metadata.parse_options(args) }
      ok {pr}.raise?(Benry::CmdApp::InvalidOptionError, "-x: unknown option.")
    end

  end


  topic '#run_action()' do

    spec "[!veass] runs action with args and kwargs." do
      args = ["Alice"]; kwargs = {lang: "fr"}
      #
      sout, serr = capture_sio { @metadata.run_action() }
      ok {sout} == "Hello, world!\n"
      ok {serr} == ""
      #
      sout, serr = capture_sio { @metadata.run_action(*args) }
      ok {sout} == "Hello, Alice!\n"
      ok {serr} == ""
      #
      sout, serr = capture_sio { @metadata.run_action(**kwargs) }
      ok {sout} == "Bonjour, world!\n"
      ok {serr} == ""
      #
      sout, serr = capture_sio { @metadata.run_action(*args, **kwargs) }
      ok {sout} == "Bonjour, Alice!\n"
      ok {serr} == ""
    end

    def _trace_mode(flag, &block)
      bkup = $TRACE_MODE
      $TRACE_MODE = true
      begin
        return yield
      ensure
        $TRACE_MODE = bkup
      end
    end

    spec "[!tubhv] if $TRACE_MODE is on, prints tracing info." do
      args = ["Alice"]; kwargs = {lang: "it"}
      sout, serr = _trace_mode(true) do
        capture_sio {
          @metadata.run_action(*args, **kwargs)
        }
      end
      ok {serr} == ""
      ok {sout} == <<"END"
## enter: halo1
Ciao, Alice!
## exit:  halo1
END
    end

    spec "[!zgp14] tracing info is colored when stdout is a tty." do
      args = ["Alice"]; kwargs = {lang: "it"}
      sout, serr = _trace_mode(true) do
        capture_sio(tty: true) {
          @metadata.run_action(*args, **kwargs)
        }
      end
      ok {serr} == ""
      ok {sout} == <<"END"
\e[33m## enter: halo1\e[0m
Ciao, Alice!
\e[33m## exit:  halo1\e[0m
END
    end

  end


  topic '#method_arity()' do

    spec "[!7v4tp] returns min and max number of positional arguments." do
      ok {@metadata.method_arity()} == [0, 1]
    end

    spec "[!w3rer] max is nil if variable argument exists." do
      schema = Benry::Cmdopt::Schema.new
      metadata = Benry::CmdApp::ActionMetadata.new("halo2", MetadataTestAction, :halo2, "greeting", schema)
      ok {metadata.method_arity()} == [0, nil]
    end

  end


  topic '#validate_method_params()' do

    spec "[!plkhs] returns error message if keyword parameter for option not exist." do
      schema = Benry::Cmdopt::Schema.new
      schema.add(:foo, "--foo", "foo")
      metadata = Benry::CmdApp::ActionMetadata.new("halo1", MetadataTestAction, :halo1, "greeting", schema)
      msg = metadata.validate_method_params()
      ok {msg} == "should have keyword parameter 'foo' for '@option.(:foo)', but not."
    end

    spec "[!1koi8] returns nil if all keyword parameters for option exist." do
      schema = Benry::Cmdopt::Schema.new
      schema.add(:lang, "-l, --lang=<lang>", "lang")
      metadata = Benry::CmdApp::ActionMetadata.new("halo1", MetadataTestAction, :halo1, "greeting", schema)
      msg = metadata.validate_method_params()
      ok {msg} == nil
    end

  end


  topic '#help_message()' do

    spec "[!i7siu] returns help message of action." do
      schema = new_schema()
      msg = without_tty { new_metadata(schema).help_message("testapp") }
      ok {uncolorize(msg)} == <<END
testapp halo1 -- greeting

Usage:
  $ testapp halo1 [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
END
    end

  end


end


topic Benry::CmdApp::ActionWithArgs do
  include ActionMetadataTestingHelper


  topic '#initialize()' do

    spec "[!6jklb] keeps ActionMetadata, args, and kwargs." do
      ameta = new_metadata(new_schema())
      wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, ["Alice"], {lang: "fr"})
      ok {wrapper.action_metadata} == ameta
      ok {wrapper.args}   == ["Alice"]
      ok {wrapper.kwargs} == {lang: "fr"}
    end

  end


  topic '#method_missing()' do

    spec "[!14li3] behaves as ActionMetadata." do
      ameta = new_metadata(new_schema())
      wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, ["Alice"], {lang: "fr"})
      ok {wrapper.name} == ameta.name
      ok {wrapper.klass} == ameta.klass
      ok {wrapper.schema} == ameta.schema
      ok {wrapper.method_arity()} == ameta.method_arity()
    end

  end


  topic '#run_action()' do

    class ActionWithArgsTest < Benry::CmdApp::Action
      @action.("hello")
      @option.(:lang, "-l <lang>", "language")
      @option.(:repeat, "-r <N>", "repeat <N> times")
      def hellowithargs(user1="alice", user2="bob", lang: nil, repeat: nil)
        puts "user1=#{user1}, user2=#{user2}, lang=#{lang.inspect}, repeat=#{repeat.inspect}"
      end
    end

    spec "[!fl26i] invokes action with args and kwargs." do
      ameta = Benry::CmdApp::Index::ACTIONS["hellowithargs"]
      #
      wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, ["bill"], {repeat: 3})
      sout, serr = capture_sio() { wrapper.run_action() }
      ok {serr} == ""
      ok {sout} == "user1=bill, user2=bob, lang=nil, repeat=3\n"
      #
      wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, ["bill"], nil)
      sout, serr = capture_sio() { wrapper.run_action() }
      ok {serr} == ""
      ok {sout} == "user1=bill, user2=bob, lang=nil, repeat=nil\n"
      #
      wrapper = Benry::CmdApp::ActionWithArgs.new(ameta, nil, {repeat: 3})
      sout, serr = capture_sio() { wrapper.run_action() }
      ok {serr} == ""
      ok {sout} == "user1=alice, user2=bob, lang=nil, repeat=3\n"
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


topic Benry::CmdApp::Action do


  class InvokeTestAction < Benry::CmdApp::Action
    prefix "test3:foo"
    #
    @action.("invoke once")
    @option.(:lang, "-l, --lang=<en|fr>", "language")
    def invoke1(user="world", lang: "en")
      puts(lang == "fr" ? "Bonjour, #{user}!" : "Hello, #{user}!")
    end
    #
    @action.("invoke twice")
    @option.(:lang, "-l, --lang=<en|fr>", "language")
    def invoke2(user="world", lang: "en")
      puts(lang == "fr" ? "Bonjour, #{user}!" : "Hello, #{user}!")
    end
    #
    @action.("invoke more")
    @option.(:lang, "-l, --lang=<en|fr>", "language")
    def invoke3(user="world", lang: "en")
      puts(lang == "fr" ? "Bonjour, #{user}!" : "Hello, #{user}!")
    end
  end

  class LoopedActionTest < Benry::CmdApp::Action
    @action.("test")
    def loop1()
      run_action_once("loop2")
    end
    @action.("test")
    def loop2()
      run_action_once("loop3")
    end
    @action.("test")
    def loop3()
      run_action_once("loop1")
    end
  end

  before do
    @action = InvokeTestAction.new()
    Benry::CmdApp::Index::DONE.clear()
  end


  topic '#run_action_once()' do

    spec "[!oh8dc] don't invoke action if already invoked." do
      sout, serr = capture_sio() do
        @action.run_action_once("test3:foo:invoke2", "Alice", lang: "fr")
      end
      ok {sout} == "Bonjour, Alice!\n"
      sout, serr = capture_sio() do
        @action.run_action_once("test3:foo:invoke2", "Alice", lang: "fr")
      end
      ok {sout} == ""
      ok {serr} == ""
    end

  end


  topic '#run_action!()' do

    spec "[!2yrc2] invokes action even if already invoked." do
      sout, serr = capture_sio() do
        @action.run_action!("test3:foo:invoke3", "Alice", lang: "fr")
      end
      ok {sout} == "Bonjour, Alice!\n"
      sout, serr = capture_sio() do
        @action.run_action!("test3:foo:invoke3", "Alice", lang: "fr")
      end
      ok {sout} == "Bonjour, Alice!\n"
      sout, serr = capture_sio() do
        @action.run_action!("test3:foo:invoke3", "Alice", lang: "en")
      end
      ok {sout} == "Hello, Alice!\n"
    end

  end


  topic '#__run_action()' do

    def __run_action(action_name, once, args, kwargs)
      @action.__send__(:__run_action, action_name, once, args, kwargs)
    end

    def __run_loop(action_name, once, args, kwargs)
      action = LoopedActionTest.new()
      action.__send__(:__run_action, action_name, once, args, kwargs)
    end

    spec "[!7vszf] raises error if action specified not found." do
      pr = proc { __run_action("loop9", nil, ["Alice"], {}) }
      ok {pr}.raise?(Benry::CmdApp::ActionNotFoundError, "loop9: action not found.")
    end

    spec "[!u8mit] raises error if action flow is looped." do
      pr = proc { __run_loop("loop1", nil, [], {}) }
      ok {pr}.raise?(Benry::CmdApp::LoopedActionError, "loop1: looped action detected.")
    end

    spec "[!vhdo9] don't invoke action twice if 'once' arg is true." do
      sout, serr = capture_sio() do
        __run_action("test3:foo:invoke2", true, ["Alice"], {lang: "fr"})
      end
      ok {sout} == "Bonjour, Alice!\n"
      sout, serr = capture_sio() do
        __run_action("test3:foo:invoke2", true, ["Alice"], {lang: "fr"})
      end
      ok {sout} == ""
      ok {serr} == ""
    end

    spec "[!r8fbn] invokes action." do
      sout, serr = capture_sio() do
        __run_action("test3:foo:invoke1", false, ["Alice"], {lang: "fr"})
      end
      ok {sout} == "Bonjour, Alice!\n"
    end

  end


  topic '.prefix()' do

    spec "[!1gwyv] converts symbol into string." do
      class PrefixTest1 < Benry::CmdApp::Action
        prefix :foo
      end
      prefix = PrefixTest1.instance_variable_get('@__prefix__')
      ok {prefix} == "foo:"
    end

    spec "[!pz46w] error if prefix contains extra '_'." do
      pr = proc do
        class PrefixTest2 < Benry::CmdApp::Action
          prefix "foo_bar"
        end
      end
      ok {pr}.raise?(Benry::CmdApp::ActionDefError,
                     "foo_bar: invalid prefix name (please use ':' or '-' instead of '_' as word separator).")
    end

    spec "[!9pu01] adds ':' at end of prefix name if prefix not end with ':'." do
      class PrefixTest3 < Benry::CmdApp::Action
        prefix "foo:bar"
      end
      prefix = PrefixTest3.instance_variable_get('@__prefix__')
      ok {prefix} == "foo:bar:"
    end

  end


  topic '.inherited()' do

    spec "[!f826w] registers all subclasses into 'Action::SUBCLASSES'." do
      class InheritedTest0a < Benry::CmdApp::Action
      end
      class InheritedTest0b < Benry::CmdApp::Action
      end
      ok {Benry::CmdApp::Action::SUBCLASSES}.include?(InheritedTest0a)
      ok {Benry::CmdApp::Action::SUBCLASSES}.include?(InheritedTest0b)
    end

    spec "[!2imrb] sets class instance variables in subclass." do
      class InheritedTest1 < Benry::CmdApp::Action
      end
      ivars = InheritedTest1.instance_variables().sort()
      ok {ivars} == [:@__action__, :@__aliasof__, :@__default__, :@__option__, :@__prefix__, :@action, :@copy_options, :@option]
    end

    spec "[!1qv12] @action is a Proc object and saves args." do
      class InheritedTest2 < Benry::CmdApp::Action
        @action.("description", detail: "xxx", postamble: "yyy", tag: "zzz")
      end
      x = InheritedTest2.instance_variable_get('@__action__')
      ok {x} == ["description", {detail: "xxx", postamble: "yyy", tag: "zzz"}]
    end

    spec "[!33ma7] @option is a Proc object and saves args." do
      class InheritedTest3 < Benry::CmdApp::Action
        @action.("description", detail: "xxx", postamble: "yyy")
        @option.(:xx, "-x, --xxx=<N>", "desc 1", type: Integer, rexp: /\A\d+\z/, enum: [2,4,8], range: (2..8))
        @option.(:yy, "-y, --yyy[=<on|off>]", "desc 2", type: TrueClass, value: false)
      end
      x = InheritedTest3.instance_variable_get('@__option__')
      ok {x}.is_a?(Benry::CmdOpt::Schema)
      items = x.each.to_a()
      ok {items.length}    == 2
      ok {items[0].key}    == :xx
      ok {items[0].optdef} == "-x, --xxx=<N>"
      ok {items[0].desc}   == "desc 1"
      ok {items[0].type}   == Integer
      ok {items[0].rexp}   == /\A\d+\z/
      ok {items[0].enum}   == [2, 4, 8]
      ok {items[0].range}  == (2..8)
      ok {items[0].value}  == nil
      ok {items[1].key}    == :yy
      ok {items[1].optdef} == "-y, --yyy[=<on|off>]"
      ok {items[1].desc}   == "desc 2"
      ok {items[1].type}   == TrueClass
      ok {items[1].rexp}   == nil
      ok {items[1].enum}   == nil
      ok {items[1].range}  == nil
      ok {items[1].value}  == false
    end

    spec "[!gxybo] '@option.()' raises error when '@action.()' not called." do
      pr = proc do
        class InheritedTest4 < Benry::CmdApp::Action
          @option.(:xx, "-x, --xxx=<N>", "desc 1")
        end
      end
      ok {pr}.raise?(Benry::CmdApp::OptionDefError,
                     "@option.(:xx): `@action.()` required but not called.")
    end

    spec "[!ga6zh] '@option.()' raises error when invalid option info specified." do
      pr = proc do
        class InheritedTest20 < Benry::CmdApp::Action
          @action.("test")
          @option.(:xx, "-x, --xxx=<N>", "desc 1", range: (2..8))
          def hello(xx: nil)
          end
        end
      end
      ok {pr}.raise?(Benry::CmdApp::OptionDefError,
                     "2..8: range value should be String, but not.")
    end

    spec "[!yrkxn] @copy_options is a Proc object and copies options from other action." do
      class InheritedTest5 < Benry::CmdApp::Action
        @action.("copy src")
        @option.(:xxx, "-x, --xxx=<arg>", "xxx #1")
        def optcopy1(xxx: nil)
        end
        #
        @action.("copy dst")
        @copy_options.("optcopy1")
        @option.(:yyy, "-y, --yyy=<on|off>", "yyy #2", type=TrueClass)
      end
      x = InheritedTest5.instance_variable_get('@__option__')
      ok {x}.is_a?(Benry::CmdOpt::Schema)
      items = x.each.to_a()
      ok {items.length}    == 2
      ok {items[0].key}    == :xxx
      ok {items[0].short}  == "x"
      ok {items[0].long}   == "xxx"
      ok {items[1].key}    == :yyy
      ok {items[1].short}  == "y"
      ok {items[1].long}   == "yyy"
    end

    spec "[!mhhn2] '@copy_options.()' raises error when action not found." do
      pr = proc do
        class InheritedTest6 < Benry::CmdApp::Action
          @action.("copy")
          @copy_options.("optcopy99")
          def copytest2(yyy: nil)
          end
        end
      end
      ok {pr}.raise?(Benry::CmdApp::OptionDefError,
                     "@copy_options.(\"optcopy99\"): action not found.")
    end

  end


  topic '.method_added()' do

    def defined_actions()
      action_names = Benry::CmdApp::Index::ACTIONS.keys()
      yield
      new_names = Benry::CmdApp::Index::ACTIONS.keys() - action_names
      metadata = new_names.length > 0 ? Benry::CmdApp::Index::ACTIONS[new_names[0]] : nil
      return new_names, metadata
    end

    spec "[!idh1j] do nothing if '@__action__' is nil." do
      new_names, x = defined_actions() do
        class Added1Test < Benry::CmdApp::Action
          prefix "added1"
          def hello1(); end
        end
      end
      ok {new_names} == []
      ok {x} == nil
    end

    spec "[!ernnb] clears both '@__action__' and '@__option__'." do
      new_names, x = defined_actions() do
        class Added2Test < Benry::CmdApp::Action
          @action.("test", detail: "XXX", postamble: "YYY")
          @option.(:foo, "--foo", "foo")
        end
        ok {Added2Test.instance_variable_get('@__action__')} != nil
        ok {Added2Test.instance_variable_get('@__option__')} != nil
        Added2Test.class_eval do
          def hello2(foo: nil); end
        end
        ok {Added2Test.instance_variable_get('@__action__')} == nil
        ok {Added2Test.instance_variable_get('@__option__')} == nil
      end
    end

    spec "[!n8tem] creates ActionMetadata object if '@__action__' is not nil." do
      new_names, x = defined_actions() do
        class Added3Test < Benry::CmdApp::Action
          prefix "added3"
          @action.("test", detail: "XXX", postamble: "YYY")
          def hello3(); end
        end
      end
      ok {new_names} == ["added3:hello3"]
      ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
      ok {x.name}      == "added3:hello3"
      ok {x.klass}     == Added3Test
      ok {x.method}    == :hello3
      ok {x.hidden?}   == false
      ok {x.detail}    == "XXX"
      ok {x.postamble} == "YYY"
    end

    spec "[!4pbsc] raises error if keyword param for option not exist in method." do
      pr = proc do
        class Added5Test < Benry::CmdApp::Action
          prefix "added5"
          @action.("test")
          @option.(:flag, "--flag=<on|off>", nil, type: TrueClass)
          def hello5(xx: nil); end
        end
      end
      ok {pr}.raise?(Benry::CmdApp::ActionDefError,
                     "def hello5(): should have keyword parameter 'flag' for '@option.(:flag)', but not.")
    end

    topic '[!5e5o0] when method name is same as default action name...' do

      spec "[!myj3p] uses prefix name (expect last char ':') as action name." do
        new_names, x = defined_actions() do
          class Added6Test < Benry::CmdApp::Action
            prefix "added6", default: :hello6
            @action.("test")
            def hello6(); end
          end
        end
        ok {new_names} == ["added6"]
        ok {x.klass} == Added6Test
        ok {x.method} == :hello6
      end

      spec "[!j5oto] clears '@__default__'." do
        class ClearDefaultTest1 < Benry::CmdApp::Action
          prefix "cleardefault1", default: :test2_   # symbol
          @__default__ != nil  or
            raise MiniTest::Assertion, "@__default__ should NOT be nil"
          #
          @action.("test")
          def test1_(); end
          @__default__ != nil  or
            raise MiniTest::Assertion, "@__default__ should NOT be nil"
          #
          @action.("test")
          def test2_(); end
          @__default__ == nil  or
            raise MiniTest::Assertion, "@__default__ should be nil"
        end
      end

    end

    topic '[!agpwh] else...' do

      spec "[!3icc4] uses method name as action name." do
        new_names, x = defined_actions() do
          class Added7Test < Benry::CmdApp::Action
            @action.("test")
            def hello7xx(); end
          end
        end
        ok {new_names} == ["hello7xx"]
        ok {x.klass} == Added7Test
        ok {x.method} == :hello7xx
      end

      spec "[!c643b] converts action name 'aa_bb_cc_' into 'aa_bb_cc'." do
        new_names, x = defined_actions() do
          class Added8Test < Benry::CmdApp::Action
            @action.("test")
            def hello8xx_(); end
          end
        end
        ok {new_names} == ["hello8xx"]
        ok {x.klass} == Added8Test
        ok {x.method} == :hello8xx_
      end

      spec "[!3fkb3] converts action name 'aa__bb__cc' into 'aa:bb:cc'." do
        new_names, x = defined_actions() do
          class Added9Test < Benry::CmdApp::Action
            @action.("test")
            def hello9xx__yy__zz(); end
          end
        end
        ok {new_names} == ["hello9xx:yy:zz"]
        ok {x.klass} == Added9Test
        ok {x.method} == :hello9xx__yy__zz
      end

      spec "[!o9s9h] converts action name 'aa_bb:_cc_dd' into 'aa-bb:_cc-dd'." do
        new_names, x = defined_actions() do
          class Added10Test < Benry::CmdApp::Action
            @action.("test")
            def _hello10xx_yy_zz(); end
          end
        end
        ok {new_names} == ["_hello10xx-yy-zz"]
        ok {x.klass} == Added10Test
        ok {x.method} == :_hello10xx_yy_zz
      end

      spec "[!8hlni] when action name is same as default name, uses prefix as action name." do
        new_names, x = defined_actions() do
          class Added11Test < Benry::CmdApp::Action
            prefix "added11", default: "hello11"
            @action.("test")
            def hello11(); end
          end
        end
        ok {new_names} == ["added11"]
        ok {x.klass} == Added11Test
        ok {x.method} == :hello11
      end

      spec "[!q8oxi] clears '@__default__' when default name matched to action name." do
        class ClearDefaultTest2 < Benry::CmdApp::Action
          prefix "cleardefault2", default: "test2"   # string
          @__default__ != nil  or
            raise MiniTest::Assertion, "@__default__ should NOT be nil"
          #
          @action.("test")
          def test1_(); end
          @__default__ != nil  or
            raise MiniTest::Assertion, "@__default__ should NOT be nil"
          #
          @action.("test")
          def test2_(); end
          @__default__ == nil  or
            raise MiniTest::Assertion, "@__default__ should be nil"
        end
      end

      spec "[!xfent] when prefix is provided, adds it to action name." do
        new_names, x = defined_actions() do
          class Added12Test < Benry::CmdApp::Action
            prefix "added12"
            @action.("test")
            def hello12(); end
          end
        end
        ok {new_names} == ["added12:hello12"]
        ok {x.klass} == Added12Test
        ok {x.method} == :hello12
      end

    end

    spec "[!jpzbi] defines same name alias of action as prefix." do
      ## when symbol
      class AliasOfTest1 < Benry::CmdApp::Action
        prefix "blabla1", alias_of: :bla1    # symbol
        @action.("test")
        def bla1(); end
      end
      ok {Benry::CmdApp::Index::ALIASES["blabla1"]} != nil
      ok {Benry::CmdApp::Index::ALIASES["blabla1"].action_name} == "blabla1:bla1"
      ## when string
      class AliasOfTest2 < Benry::CmdApp::Action
        prefix "bla:bla2", alias_of: "blala"    # string
        @action.("test")
        def blala(); end
      end
      ok {Benry::CmdApp::Index::ALIASES["bla:bla2"]} != nil
      ok {Benry::CmdApp::Index::ALIASES["bla:bla2"].action_name} == "bla:bla2:blala"
    end

    spec "[!tvjb0] clears '@__aliasof__' only when alias created." do
      class AliasOfTest3 < Benry::CmdApp::Action
        prefix "bla:bla3", alias_of: "bla3b"    # string
        @__aliasof__ != nil  or
          raise MiniTest::Assertion, "@__aliasof__ should NOT be nil"
        #
        @action.("test")
        def bla3a(); end
        @__aliasof__ != nil  or
          raise MiniTest::Assertion, "@__aliasof__ should NOT be nil"
        #
        @action.("test")
        def bla3b(); end
        @__aliasof__ == nil  or
          raise MiniTest::Assertion, "@__aliasof__ should be nil"
      end
      begin
        ok {AliasOfTest3.instance_variable_get('@__aliasof__')} == nil
      ensure
        AliasOfTest3.class_eval do
          @__aliasof__ = nil
        end
      end
    end

    spec "[!997gs] not raise error when action not found." do
      pr = proc do
        class AliasOfTest4 < Benry::CmdApp::Action
          prefix "blabla4", alias_of: :bla99     # action not exist
          @action.("test")
          def bla3(); end
        end
      end
      begin
        ok {pr}.NOT.raise?(Exception)
      ensure
        AliasOfTest4.class_eval { @__aliasof__ = nil }
      end
    end

    spec "[!349nr] raises error when same name action or alias with prefix already exists." do
      pr = proc do
        class AliasOfTest5a < Benry::CmdApp::Action
          @action.("test")
          def bla5(); end                    # define 'bla5' action
        end
        class AliasOfTest5b < Benry::CmdApp::Action
          prefix "bla5", alias_of: :blala    # define 'bla5' action, too
          @action.("test")
          def blala(); end
        end
      end
      begin
        ok {pr}.raise?(Benry::CmdApp::AliasDefError,
                       'action_alias("bla5", "bla5:blala"): not allowed to define same name alias as existing action.')
      ensure
        AliasOfTest5b.class_eval { @__aliasof__ = nil }
      end
    end

  end


end


topic Benry::CmdApp do


  topic '.action_alias()' do

    class Alias1Test < Benry::CmdApp::Action
      prefix "alias1"
      @action.("alias test")
      def a1(); end
      @action.("alias test")
      def a2(); end
    end

    spec "[!vzlrb] registers alias name with action name." do
      Benry::CmdApp.action_alias("a4", "alias1:a1")
      ok {Benry::CmdApp::Index::ALIASES}.key?("a4")
      ok {Benry::CmdApp::Index::ALIASES["a4"].action_name} == "alias1:a1"
    end

    spec "[!0cq6o] supports args and kwargs." do
      Benry::CmdApp.action_alias("a8", "alias1:a1", ["Alice"], {lang: "it"})
      ok {Benry::CmdApp::Index::ALIASES}.key?("a8")
      ok {Benry::CmdApp::Index::ALIASES["a8"].action_name} == "alias1:a1"
      ok {Benry::CmdApp::Index::ALIASES["a8"].args}   == ["Alice"]
      ok {Benry::CmdApp::Index::ALIASES["a8"].kwargs} == {lang: "it"}
    end

    spec "[!4wtxj] supports 'tag:' keyword arg." do
      Benry::CmdApp.action_alias("a7", "alias1:a1", tag: :important)
      ok {Benry::CmdApp::Index::ALIASES}.key?("a7")
      ok {Benry::CmdApp::Index::ALIASES["a7"].action_name} == "alias1:a1"
      ok {Benry::CmdApp::Index::ALIASES["a7"].tag} == :important
    end

    spec "[!5immb] convers both alias name and action name into string." do
      Benry::CmdApp.action_alias(:a5, :'alias1:a2')
      ok {Benry::CmdApp::Index::ALIASES}.key?("a5")
      ok {Benry::CmdApp::Index::ALIASES["a5"].action_name} == "alias1:a2"
    end

    spec "[!nrz3d] error if action not found." do
      pr = proc { Benry::CmdApp.action_alias(:a5, :'alias1:a5') }
      ok {pr}.raise?(Benry::CmdApp::AliasDefError,
                     "action_alias(:a5, :\"alias1:a5\"): action not found.")
    end

    spec "[!vvmwd] error when action with same name as alias exists." do
      pr = proc { Benry::CmdApp.action_alias(:'alias1:a2', :'alias1:a1') }
      ok {pr}.raise?(Benry::CmdApp::AliasDefError,
                     "action_alias(:\"alias1:a2\", :\"alias1:a1\"): not allowed to define same name alias as existing action.")
    end

    spec "[!i9726] error if alias already defined." do
      pr1 = proc { Benry::CmdApp.action_alias(:'a6', :'alias1:a1') }
      pr2 = proc { Benry::CmdApp.action_alias(:'a6', :'alias1:a2') }
      ok {pr1}.NOT.raise?(Exception)
      ok {pr2}.raise?(Benry::CmdApp::AliasDefError,
                      "action_alias(:a6, :\"alias1:a2\"): alias name duplicated.")
    end

  end

end


topic Benry::CmdApp::Config do


  topic '#initialize()' do

    spec "[!uve4e] sets command name automatically if not provided." do
      config = Benry::CmdApp::Config.new("test")
      ok {config.app_command} != nil
      ok {config.app_command} == File.basename($0)
    end

  end


end


topic Benry::CmdApp::GlobalOptionSchema do


  topic '#initialize()' do

    def new_gschema(desc="", version=nil, **kwargs)
      config = Benry::CmdApp::Config.new(desc, version, **kwargs)
      x = Benry::CmdApp::GlobalOptionSchema.new(config)
      return x
    end

    spec "[!3ihzx] do nothing when config is nil." do
      x = nil
      pr = proc { x = Benry::CmdApp::GlobalOptionSchema.new(nil) }
      ok {pr}.NOT.raise?(Exception)
      ok {x}.is_a?(Benry::CmdApp::GlobalOptionSchema)
    end

    spec "[!tq2ol] adds '-h, --help' option if 'config.option_help' is set." do
      x = new_gschema(option_help: true)
      ok {x.find_long_option("help")} != nil
      ok {x.find_short_option("h")}   != nil
      x = new_gschema(option_help: false)
      ok {x.find_long_option("help")} == nil
      ok {x.find_short_option("h")}   == nil
    end

    spec "[!mbtw0] adds '-V, --version' option if 'config.app_version' is set." do
      x = new_gschema("", "0.0.0")
      ok {x.find_long_option("version")} != nil
      ok {x.find_short_option("V")}      != nil
      x = new_gschema("", nil)
      ok {x.find_long_option("version")} == nil
      ok {x.find_short_option("V")}      == nil
    end

    spec "[!f5do6] adds '-a, --all' option if 'config.option_all' is set." do
      x = new_gschema(option_all: true)
      ok {x.find_long_option("all")} != nil
      ok {x.find_short_option("a")}  != nil
      x = new_gschema(option_all: false)
      ok {x.find_long_option("all")} == nil
      ok {x.find_short_option("a")}  == nil
    end

    spec "[!cracf] adds '-v, --verbose' option if 'config.option_verbose' is set." do
      x = new_gschema(option_verbose: true)
      ok {x.find_long_option("verbose")} != nil
      ok {x.find_short_option("v")}  != nil
      x = new_gschema(option_verbose: false)
      ok {x.find_long_option("verbose")} == nil
      ok {x.find_short_option("v")}  == nil
    end

    spec "[!2vil6] adds '-q, --quiet' option if 'config.option_quiet' is set." do
      x = new_gschema(option_quiet: true)
      ok {x.find_long_option("quiet")} != nil
      ok {x.find_short_option("q")}  != nil
      x = new_gschema(option_quiet: false)
      ok {x.find_long_option("quiet")} == nil
      ok {x.find_short_option("q")}  == nil
    end

    spec "[!6zw3j] adds '--color=<on|off>' option if 'config.option_color' is set." do
      x = new_gschema(option_color: true)
      ok {x.find_long_option("color")} != nil
      x = new_gschema(option_quiet: false)
      ok {x.find_long_option("color")} == nil
    end

    spec "[!29wfy] adds '-D, --debug' option if 'config.option_debug' is set." do
      x = new_gschema(option_debug: true)
      ok {x.find_long_option("debug")} != nil
      ok {x.find_short_option("D")}    != nil
      x = new_gschema(option_debug: false)
      ok {x.find_long_option("debug")} == nil
      ok {x.find_short_option("D")}    == nil
    end

    spec "[!s97go] adds '-T, --trace' option if 'config.option_trace' is set." do
      x = new_gschema(option_trace: true)
      ok {x.find_long_option("trace")} != nil
      ok {x.find_short_option("T")}    != nil
      x = new_gschema(option_debug: false)
      ok {x.find_long_option("trace")} == nil
      ok {x.find_short_option("T")}    == nil
    end

  end


end


topic Benry::CmdApp::Application do
  include CommonTestingHelper

  class AppTest < Benry::CmdApp::Action
    @action.("print greeting message")
    @option.(:lang, "-l, --lang=<en|fr|it>", "language")
    def sayhello(user="world", lang: "en")
      case lang
      when "en" ;  puts "Hello, #{user}!"
      when "fr" ;  puts "Bonjour, #{user}!"
      when "it" ;  puts "Ciao, #{user}!"
      else      ;  raise "#{lang}: unknown language."
      end
    end
  end

  before do
    @config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                        app_name: "TestApp", app_command: "testapp",
                                        option_all: true, option_debug: true)
    @app = Benry::CmdApp::Application.new(@config)
  end

  def _run_app(*args)
    sout, serr = capture_sio { @app.run(*args) }
    ok {serr} == ""
    return sout
  end


  topic '#initialize()' do

    spec "[!jkprn] creates option schema object according to config." do
      c = Benry::CmdApp::Config.new("test", "1.0.0", option_debug: true)
      app = Benry::CmdApp::Application.new(c)
      schema = app.instance_variable_get('@schema')
      ok {schema}.is_a?(Benry::CmdOpt::Schema)
      items = schema.each.to_a()
      ok {items[0].key} == :help
      ok {items[1].key} == :version
      ok {items[2].key} == :debug
      ok {schema.option_help()} == <<END
  -h, --help     : print help message (of action if action specified)
  -V, --version  : print version
  -D, --debug    : set $DEBUG_MODE to true
END
    end

    spec "[!h786g] acceps callback block." do
      config = Benry::CmdApp::Config.new("test app")
      n = 0
      app = Benry::CmdApp::Application.new(config) do |args|
        n += 1
      end
      ok {app.callback}.is_a?(Proc)
      ok {n} == 0
      app.callback.call([])
      ok {n} == 1
      app.callback.call([])
      ok {n} == 2
    end

  end


  topic '#main()' do

    after do
      $cmdapp_config = nil
    end

    spec "[!y6q9z] runs action with options." do
      sout, serr = capture_sio { @app.main(["sayhello", "-l", "it", "Alice"]) }
      ok {serr} == ""
      ok {sout} == "Ciao, Alice!\n"
    end

    spec "[!a7d4w] prints error message with '[ERROR]' prompt." do
      sout, serr = capture_sio { @app.main(["sayhello", "Alice", "Bob"]) }
      ok {serr} == "\e[0;31m[ERROR]\e[0m sayhello: too much arguments (at most 1).\n"
      ok {sout} == ""
    end

    spec "[!r7opi] prints filename and line number on where error raised if DefinitionError." do
      class MainTest1 < Benry::CmdApp::Action
        prefix "main1"
        @action.("test")
        def err1
          MainTest1.class_eval do
            @action.("test")
            @option.(:foo, "--foo", "foo")
            def err2(bar: nil)   # should have keyword parameter 'foo'
            end
          end
        end
      end
      lineno = __LINE__ - 5
      sout, serr = capture_sio { @app.main(["main1:err1"]) }
      ok {sout} == ""
      ok {serr} == <<"END"
\e[0;31m[ERROR]\e[0m def err2(): should have keyword parameter 'foo' for '@option.(:foo)', but not.
\t\(file: test\/cmdapp_test\.rb, line: #{lineno})
END
    end

    spec "[!v0zrf] error location can be filtered by block." do
      class MainTest2 < Benry::CmdApp::Action
        prefix "main2"
        @action.("test")
        def err2
          _err2()
        end
        def _err2()
          MainTest2.class_eval do  # == lineno2
            @action.("test")
            @option.(:foo, "--foo", "foo")
            def err2x(bar: nil)    # == lineno1
            end
          end
        end
      end
      lineno1 = __LINE__ - 5
      lineno2 = lineno1 - 3
      ## no filter
      sout, serr = capture_sio { @app.main(["main2:err2"]) }
      ok {sout} == ""
      ok {serr} =~ /\t\(file: .*\/cmdapp_test\.rb, line: #{lineno1}\)\n/
      ## filter by block
      sout, serr = capture_sio {
        @app.main(["main2:err2"]) {|exc| exc.lineno == lineno2 }
      }
      ok {sout} == ""
      ok {serr} =~ /\t\(file: .*\/cmdapp_test\.rb, line: #{lineno2}\)\n/
    end

    spec "[!6ro6n] not catch error when $DEBUG_MODE is on." do
      bkup = $DEBUG_MODE
      begin
        pr = proc { @app.main(["-D", "sayhello", "Alice", "Bob"]) }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "sayhello: too much arguments (at most 1).")
      ensure
        $DEBUG_MODE = bkup
      end
    end

    spec "[!5oypr] returns 0 as exit code when no errors occurred." do
      ret = nil
      sout, serr = capture_sio do
        ret = @app.main(["sayhello", "Alice", "-l", "it"])
      end
      ok {ret} == 0
      ok {serr} == ""
      ok {sout} == "Ciao, Alice!\n"
    end

    spec "[!qk5q5] returns 1 as exit code when error occurred." do
      ret = nil
      sout, serr = capture_sio do
        ret = @app.main(["sayhello", "Alice", "Bob"])
      end
      ok {ret} == 1
      ok {serr} == "\e[0;31m[ERROR]\e[0m sayhello: too much arguments (at most 1).\n"
      ok {sout} == ""
    end

  end


  topic '#run()' do

    class AppRunTest < Benry::CmdApp::Action
      #
      @action.("test config")
      def check_config()
        puts "$cmdapp_config.class=#{$cmdapp_config.class.name}"
      end
      #
      @action.("test global option parseing")
      @option.(:help, "-h, --help", "print help")
      def test_globalopt(help: false)
        puts "help=#{help}"
      end
      #
      @action.("test debug option")
      def test_debugopt(help: false)
        puts "$DEBUG_MODE=#{$DEBUG_MODE}"
      end
      #
      @action.("arity test")
      def test_arity1(xx, yy, zz=nil)
      end
      #
      @action.("arity test with variable args")
      def test_arity2(xx, yy, zz=nil, *rest)
      end
      #
      @action.("raises exception")
      def test_exception1()
        1/0
      end
      #
      @action.("loop test")
      def test_loop1()
        run_action_once("test-loop2")
      end
      @action.("loop test")
      def test_loop2()
        run_action_once("test-loop1")
      end
    end

    spec "[!t4ypg] sets $cmdapp_config at beginning." do
      sout, serr = capture_sio { @app.run("check-config") }
      ok {serr} == ""
      ok {sout} == "$cmdapp_config.class=Benry::CmdApp::Config\n"
    end

    spec "[!pyotc] sets global options to '@global_options'." do
      ok {@app.instance_variable_get('@global_options')} == nil
      capture_sio { @app.run("--help") }
      ok {@app.instance_variable_get('@global_options')} == {:help=>true}
    end

    spec "[!go9kk] sets global variables according to global options." do
      config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                         option_verbose: true,
                                         option_quiet: true,
                                         option_debug: true,
                                         option_color: true)
      app = Benry::CmdApp::Application.new(config)
      bkup = [$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]
      begin
        ['-v', '--verbose'].each do |x|
          $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil, nil
          capture_sio { app.run(x, '-h') }
          ok {[$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [true, nil, nil, nil]
        end
        #
        ['-q', '--quiet'].each do |x|
          $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil, nil
          capture_sio { app.run(x, '-h') }
          ok {[$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [nil, true, nil, nil]
        end
        #
        ['-D', '--debug'].each do |x|
          $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil, nil
          capture_sio { app.run(x, '-h') }
          ok {[$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [nil, nil, true, nil]
        end
        #
        ['--color', '--color=on'].each do |x|
          $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil, nil
          capture_sio { app.run(x, '-h') }
          ok {[$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [nil, nil, nil, true]
        end
        ['--color=off'].each do |x|
          $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = nil, nil, nil, nil
          capture_sio { app.run(x, '-h') }
          ok {[$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE]} == [nil, nil, nil, false]
        end
      ensure
        $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE, $COLOR_MODE = bkup
      end
    end

    spec "[!5iczl] skip actions if help option or version option specified." do
      def @app.do_callback(args, global_opts)
        @_called_ = args.dup
      end
      capture_sio { @app.run("--help") }
      ok {@app.instance_variable_get('@_called_')} == nil
      capture_sio { @app.run("--version") }
      ok {@app.instance_variable_get('@_called_')} == nil
      capture_sio { @app.run("sayhello") }
      ok {@app.instance_variable_get('@_called_')} == ["sayhello"]
    end

    spec "[!w584g] calls callback method." do
      def @app.do_callback(args, global_opts)
        @_called_ = args.dup
      end
      ok {@app.instance_variable_get('@_called_')} == nil
      capture_sio { @app.run("sayhello") }
      ok {@app.instance_variable_get('@_called_')} == ["sayhello"]
    end

    spec "[!pbug7] skip actions if callback method returns `:SKIP` value." do
      def @app.do_callback(args, global_opts)
        @_called1 = args.dup
        return :SKIP
      end
      def @app.do_find_action(args, global_opts)
        super
        @_called2 = args.dup
      end
      ok {@app.instance_variable_get('@_called1')} == nil
      ok {@app.instance_variable_get('@_called2')} == nil
      capture_sio { @app.run("sayhello") }
      ok {@app.instance_variable_get('@_called1')} == ["sayhello"]
      ok {@app.instance_variable_get('@_called2')} == nil
    end

    spec "[!avxos] prints candidate actions if action name ends with ':'." do
      class CandidateTest1 < Benry::CmdApp::Action
        prefix "candi:date1"
        @action.("test")
        def bbb(); end
        @action.("test")
        def aaa(); end
      end
      ## without tty
      sout, serr = capture_sio(tty: false) { @app.run("candi:date1:") }
      ok {serr} == ""
      ok {sout} == <<"END"
Actions:
  candi:date1:aaa    : test
  candi:date1:bbb    : test
END
      ## with tty
      sout, serr = capture_sio(tty: true) { @app.run("candi:date1:") }
      ok {serr} == ""
      ok {sout} == <<"END"
\e[34mActions:\e[0m
  \e[1mcandi:date1:aaa   \e[0m : test
  \e[1mcandi:date1:bbb   \e[0m : test
END
    end

    spec "[!eeh0y] candidates are not printed if 'config.feat_candidate' is false." do
      class CandidateTest5 < Benry::CmdApp::Action
        prefix "candi:date5"
        @action.("test b")
        def bbb(); end
        @action.("test a")
        def aaa(); end
      end
      ## flag is on
      @app.config.feat_candidate = false
      pr = proc { @app.run("candi:date5:") }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "candi:date5:: unknown action.")
      ## flag is off
      @app.config.feat_candidate = true
      sout, serr = capture_sio(tty: false) { @app.run("candi:date5:") }
      ok {serr} == ""
      ok {sout} == <<"END"
Actions:
  candi:date5:aaa    : test a
  candi:date5:bbb    : test b
END
    end

    spec "[!l0g1l] skip actions if no action specified and 'config.default_help' is set." do
      def @app.do_find_action(args, global_opts)
        ret = super
        @_args1 = args.dup
        @_result = ret
        ret
      end
      def @app.do_run_action(metadata, args, global_opts)
        ret = super
        @_args2 = args.dup
        ret
      end
      @app.config.default_help = true
      capture_sio { @app.run() }
      ok {@app.instance_variable_get('@_args1')} == []
      ok {@app.instance_variable_get('@_result')} == nil
      ok {@app.instance_variable_get('@_args2')} == nil
    end

    spec "[!x1xgc] run action with options and arguments." do
      sout, serr = capture_sio { @app.run("sayhello", "Alice", "-l", "it") }
      ok {serr} == ""
      ok {sout} == "Ciao, Alice!\n"
    end

    spec "[!agfdi] reports error when action not found." do
      pr = proc { @app.run("xxx-yyy") }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "xxx-yyy: unknown action.")
    end

    spec "[!v5k56] runs default action if action not specified." do
      @config.default_action = "sayhello"
      sout, serr = capture_sio { @app.run() }
      ok {serr} == ""
      ok {sout} == "Hello, world!\n"
    end

    spec "[!o5i3w] reports error when default action not found." do
      @config.default_action = "xxx-zzz"
      pr = proc { @app.run() }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "xxx-zzz: unknown default action.")
    end

    spec "[!7h0ku] prints help if no action but 'config.default_help' is true." do
      expected, serr = capture_sio { @app.run("-h") }
      ok {serr} == ""
      ok {expected} =~ /^Usage:/
      #
      @config.default_help = true
      sout, serr = capture_sio { @app.run() }
      ok {serr} == ""
      ok {sout} == expected
    end

    spec "[!n60o0] reports error when action nor default action not specified." do
      @config.default_action = nil
      pr = proc { @app.run() }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "testapp: action name required (run `testapp -h` for details).")
    end

    spec "[!hk6iu] unsets $cmdapp_config at end." do
      bkup = $cmdapp_config
      $cmdapp_config = nil
      begin
        sout, serr = capture_sio { @app.run("check-config") }
        ok {sout} == "$cmdapp_config.class=Benry::CmdApp::Config\n"
        ok {$cmdapp_config} == nil
      ensure
        $cmdapp_config = bkup
      end
    end

    spec "[!wv22u] calls teardown method at end of running action." do
      def @app.do_teardown(*args)
        @_args = args
      end
      ok {@app.instance_variable_get('@_args')} == nil
      sout, serr = capture_sio { @app.run("check-config") }
      ok {@app.instance_variable_get('@_args')} == [nil]
    end

    spec "[!dhba4] calls teardown method even if exception raised." do
      def @app.do_teardown(*args)
        @_args = args
      end
      ok {@app.instance_variable_get('@_args')} == nil
      pr = proc { @app.run("test-exception1") }
      ok {pr}.raise?(ZeroDivisionError) do |exc|
        ok {@app.instance_variable_get('@_args')} == [exc]
      end
    end

  end


  topic '#help_message()' do

    spec "[!owg9y] returns help message." do
      msg = @app.help_message()
      msg = uncolorize(msg)
      ok {msg}.start_with?(<<END)
TestApp (1.0.0) -- test app

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)
  -V, --version      : print version
  -a, --all          : list all actions/options including private (hidden) ones
  -D, --debug        : set $DEBUG_MODE to true

Actions:
END
    end

  end


  topic '#do_create_global_option_schema()' do

    spec "[!u3zdg] creates global option schema object according to config." do
      config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                         option_all: true, option_quiet: true)
      app = Benry::CmdApp::Application.new(config)
      x = app.__send__(:do_create_global_option_schema, config)
      ok {x}.is_a?(Benry::CmdApp::GlobalOptionSchema)
      ok {x.find_long_option("all")}     != nil
      ok {x.find_long_option("quiet")}   != nil
      ok {x.find_long_option("verbose")} == nil
      ok {x.find_long_option("debug")}   == nil
    end

  end


  topic '#do_create_help_message_builder()' do

    spec "[!pk5da] creates help message builder object." do
      config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                         option_all: true, option_quiet: true)
      app = Benry::CmdApp::Application.new(config)
      x = app.__send__(:do_create_help_message_builder, config, app.schema)
      ok {x}.is_a?(Benry::CmdApp::CommandHelpBuilder)
    end

  end


  topic '#do_parse_global_options()' do

    spec "[!5br6t] parses only global options and not parse action options." do
      sout, serr = capture_sio { @app.run("test-globalopt", "--help") }
      ok {serr} == ""
      ok {sout} == "help=true\n"
    end

    spec "[!kklah] raises InvalidOptionError if global option value is invalid." do
      pr = proc { @app.run("-hoge", "test-globalopt") }
      ok {pr}.raise?(Benry::CmdApp::InvalidOptionError, "-o: unknown option.")
    end

  end


  topic '#do_toggle_global_switches()' do

    before do
      @config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                          option_verbose: true,
                                          option_quiet: true,
                                          option_debug: true,
                                          option_color: true,
                                          option_trace: true)
      @app = Benry::CmdApp::Application.new(@config)
    end

    spec "[!j6u5x] sets $VERBOSE_MODE to true if '-v' or '--verbose' specified." do
      bkup = $VERBOSE_MODE
      begin
        ["-v", "--verbose"].each do |opt|
          $VERBOSE_MODE = false
          sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
          ok {serr} == ""
          ok {$VERBOSE_MODE} == true
        end
      ensure
        $VERBOSE_MODE = bkup
      end
    end

    spec "[!p1l1i] sets $QUIET_MODE to true if '-q' or '--quiet' specified." do
      bkup = $QUIET_MODE
      begin
        ["-q", "--quiet"].each do |opt|
          $QUIET_MODE = false
          sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
          ok {serr} == ""
          ok {$QUIET_MODE} == true
        end
      ensure
        $QUIET_MODE = bkup
      end
    end

    spec "[!2zvf9] sets $COLOR_MODE to true/false according to '--color' option." do
      bkup = $COLOR_MODE
      begin
        [["--color", true], ["--color=on", true], ["--color=off", false]].each do |opt, val|
          $COLOR_MODE = !val
          sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
          ok {serr} == ""
          ok {$COLOR_MODE} == val
        end
      ensure
        $COLOR_MODE = bkup
      end
    end

    spec "[!ywl1a] sets $DEBUG_MODE to true if '-D' or '--debug' specified." do
      bkup = $DEBUG_MODE
      begin
        ["-D", "--debug"].each do |opt|
          $DEBUG_MODE = false
          sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
          ok {serr} == ""
          ok {sout} == "$DEBUG_MODE=true\n"
          ok {$DEBUG_MODE} == true
        end
      ensure
        $DEBUG_MODE = bkup
      end
    end

    spec "[!8trmz] sets $TRACE_MODE to true if '-T' or '--trace' specified." do
      bkup = $TRACE_MODE
      begin
        ["-T", "--trace"].each do |opt|
          $TRACE_MODE = false
          sout, serr = capture_sio { @app.run(opt, "test-debugopt") }
          ok {serr} == ""
          ok {$TRACE_MODE} == true
        end
      ensure
        $TRACE_MODE = bkup
      end
    end

  end


  topic '#do_handle_global_options()' do

    def new_app()
      kws = {
        app_name:       "TestApp",
        app_command:    "testapp",
        option_all:     true,
        option_verbose: true,
        option_quiet:   true,
        option_color:   true,
        option_debug:   true,
      }
      config = Benry::CmdApp::Config.new("test app", "1.0.0", **kws)
      return Benry::CmdApp::Application.new(config)
    end

    spec "[!xvj6s] prints help message if '-h' or '--help' specified." do
      expected = <<"END"
TestApp (1.0.0) -- test app

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)
  -V, --version      : print version
  -a, --all          : list all actions/options including private (hidden) ones
  -v, --verbose      : verbose mode
  -q, --quiet        : quiet mode
  --color[=<on|off>] : enable/disable color
  -D, --debug        : set $DEBUG_MODE to true

Actions:
END
      app = new_app()
      ["-h", "--help"].each do |opt|
        sout, serr = capture_sio { app.run(opt) }
        ok {serr} == ""
        ok {sout}.start_with?(expected)
      end
    end

    spec "[!lpoz7] prints help message of action if action name specified with help option." do
      expected = <<"END"
testapp sayhello -- print greeting message

Usage:
  $ testapp sayhello [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
END
      app = new_app()
      ["-h", "--help"].each do |opt|
        sout, serr = capture_sio { app.run(opt, "sayhello") }
        ok {serr} == ""
        ok {sout} == expected
      end
    end

    spec "[!fslsy] prints version if '-V' or '--version' specified." do
      app = new_app()
      ["-V", "--version"].each do |opt|
        sout, serr = capture_sio { app.run(opt, "xxx") }
        ok {serr} == ""
        ok {sout} == "1.0.0\n"
      end
    end

  end


  topic '#do_callback()' do

    def new_app(&block)
      @config = Benry::CmdApp::Config.new("test app", "1.0.0")
      return Benry::CmdApp::Application.new(@config, &block)
    end

    spec "[!xwo0v] calls callback if provided." do
      called = nil
      app = new_app do |args, global_opts, config|
        called = [args.dup, global_opts, config]
      end
      ok {called} == nil
      without_tty { app.run("sayhello") }
      ok {called} != nil
      ok {called[0]} == ["sayhello"]
      ok {called[1]} == {}
      ok {called[2]} == @config
    end

    spec "[!lljs1] calls callback only once." do
      n = 0
      app = new_app do |args, global_opts, config|
        n += 1
      end
      ok {n} == 0
      without_tty { app.run("sayhello") }
      ok {n} == 1
      without_tty { app.run("sayhello") }
      ok {n} == 1
      without_tty { app.run("sayhello") }
      ok {n} == 1
    end

  end


  topic '#do_find_action()' do

    spec "[!bm8np] returns action metadata." do
      x = @app.__send__(:do_find_action, ["sayhello"], {})
      ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
      ok {x.name} == "sayhello"
    end

    spec "[!vl0zr] error when action not found." do
      pr = proc { @app.__send__(:do_find_action, ["hiyo"], {}) }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "hiyo: unknown action.")
    end

    spec "[!gucj7] if no action specified, finds default action instead." do
      @app.config.default_action = "sayhello"
      x = @app.__send__(:do_find_action, [], {})
      ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
      ok {x.name} == "sayhello"
    end

    spec "[!388rs] error when default action not found." do
      @app.config.default_action = "hiyo"
      pr = proc { @app.__send__(:do_find_action, [], {}) }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "hiyo: unknown default action.")
    end

    spec "[!drmls] returns nil if no action specified but 'config.default_help' is set." do
      @app.config.default_action = nil
      @app.config.default_help = true
      x = @app.__send__(:do_find_action, [], {})
      ok {x} == nil
    end

    spec "[!hs589] error when action nor default action not specified." do
      @app.config.default_action = nil
      @app.config.default_help = false
      pr = proc { @app.__send__(:do_find_action, [], {}) }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "testapp: action name required (run `testapp -h` for details).")
    end

  end


  topic '#do_run_action()' do

    spec "[!62gv9] parses action options even if specified after args." do
      sout, serr = capture_sio { @app.run("sayhello", "Alice", "-l", "it") }
      ok {serr} == ""
      ok {sout} == "Ciao, Alice!\n"
    end

    spec "[!6mlol] reports error if action requries argument but nothing specified." do
      pr = proc { @app.run("test-arity1") }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "test-arity1: argument required.")
    end

    spec "[!72jla] reports error if action requires N args but specified less than N args." do
      pr = proc { @app.run("test-arity1", "foo") }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "test-arity1: too less arguments (at least 2).")
    end

    spec "[!zawxe] reports error if action requires N args but specified over than N args." do
      pr = proc { @app.run("test-arity1", "foo", "bar", "baz", "boo") }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "test-arity1: too much arguments (at most 3).")
    end

    spec "[!y97o3] action can take any much args if action has variable arg." do
      pr = proc {
        capture_sio { @app.run("test-arity2", "foo", "bar", "baz", "boo") }
      }
      ok {pr}.NOT.raise?(Exception)
    end

    spec "[!cf45e] runs action with arguments and options." do
      sout, serr = capture_sio { @app.run("sayhello", "-l", "it", "Bob") }
      ok {serr} == ""
      ok {sout} == "Ciao, Bob!\n"
    end

    spec "[!tsal4] detects looped action." do
      pr = proc { @app.run("test-loop1") }
      ok {pr}.raise?(Benry::CmdApp::LoopedActionError,
                     "test-loop1: looped action detected.")
    end

  end


  topic '#do_print_help_message()' do

    spec "[!eabis] prints help message of action if action name provided." do
      sout, serr = capture_sio { @app.run("-h", "sayhello") }
      ok {serr} == ""
      ok {sout} == <<'END'
testapp sayhello -- print greeting message

Usage:
  $ testapp sayhello [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
END
    end

    spec "[!cgxkb] error if action for help option not found." do
      ["-h", "--help"].each do |opt|
        pr = proc { @app.run(opt, "xhello") }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "xhello: action not found.")
      end
    end

    spec "[!nv0x3] prints help message of command if action name not provided." do
      sout, serr = capture_sio { @app.run("-h") }
      ok {serr} == ""
      ok {sout}.start_with?(<<'END')
TestApp (1.0.0) -- test app

Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

Options:
  -h, --help         : print help message (of action if action specified)
  -V, --version      : print version
  -a, --all          : list all actions/options including private (hidden) ones
  -D, --debug        : set $DEBUG_MODE to true

Actions:
END
    end

    spec "[!4qs7y] shows private (hidden) actions/options if '--all' option specified." do
      class HiddenTest < Benry::CmdApp::Action
        private
        @action.("hidden test")
        @option.(:_trace, "-T", "enable tracing")
        def hidden1(_trace: false)
        end
      end
      #
      ok {_run_app("-h", "--all")}  =~ /^  hidden1 +: hidden test$/
      ok {_run_app("--help", "-a")} =~ /^  hidden1 +: hidden test$/
      ok {_run_app("-h")}           !~ /^  hidden1 +: hidden test$/
      #
      ok {_run_app("-ha", "hidden1")}         =~ /^  -T +: enable tracing$/
      ok {_run_app("-h", "--all", "hidden1")} =~ /^  -T +: enable tracing$/
      ok {_run_app("--help", "hidden1")}      !~ /^  -T +: enable tracing$/
    end

    spec "[!l4d6n] `all` flag should be true or false, not nil." do
      config = Benry::CmdApp::Config.new("test app", "1.0.0", option_all: true)
      app = Benry::CmdApp::Application.new(config)
      def app.help_message(all)
        @_all_ = all
        super
      end
      msg = without_tty { app.run("-h") }
      ok {app.instance_variable_get('@_all_')} != nil
      ok {app.instance_variable_get('@_all_')} == false
      #
      msg = without_tty { app.run("-ha") }
      ok {app.instance_variable_get('@_all_')} != nil
      ok {app.instance_variable_get('@_all_')} == true
    end

    spec "[!efaws] prints colorized help message when stdout is a tty." do
      sout, serr = capture_sio(tty: true) { @app.run("-h") }
      ok {serr} == ""
      ok {sout}.include?(<<"END")
\e[34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] [<action> [<arguments>...]]
END
      ok {sout}.include?(<<"END")
\e[34mOptions:\e[0m
  \e[1m-h, --help        \e[0m : print help message (of action if action specified)
  \e[1m-V, --version     \e[0m : print version
END
      ok {sout}.include?(<<"END")
\e[34mActions:\e[0m
END
    end

    spec "[!9vdy1] prints non-colorized help message when stdout is not a tty." do
      sout, serr = capture_sio(tty: false) { @app.run("-h") }
      ok {serr} == ""
      ok {sout}.include?(<<"END")
Usage:
  $ testapp [<options>] [<action> [<arguments>...]]
END
      ok {sout}.include?(<<"END")
Options:
  -h, --help         : print help message (of action if action specified)
  -V, --version      : print version
END
      ok {sout}.include?(<<"END")
Actions:
END
    end

    spec "[!gsdcu] prints colorized help message when '--color[=on]' specified." do
      @config.option_color = true
      app = Benry::CmdApp::Application.new(@config)
      bkup = $COLOR_MODE
      begin
        sout, serr = capture_sio(tty: false) { app.run("-h", "--color") }
        ok {serr} == ""
        ok {sout}.include?(<<"END")
\e[34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] [<action> [<arguments>...]]
END
        ok {sout}.include?(<<"END")
\e[34mOptions:\e[0m
  \e[1m-h, --help        \e[0m : print help message (of action if action specified)
  \e[1m-V, --version     \e[0m : print version
END
        ok {sout}.include?(<<"END")
\e[34mActions:\e[0m
END
      ensure
        $COLOR_MODE = bkup
      end
    end

    spec "[!be8y2] prints non-colorized help message when '--color=off' specified." do
      @config.option_color = true
      app = Benry::CmdApp::Application.new(@config)
      bkup = $COLOR_MODE
      begin
        sout, serr = capture_sio(tty: true) { app.run("-h", "--color=off") }
        ok {serr} == ""
        ok {sout}.include?(<<"END")
Usage:
  $ testapp [<options>] [<action> [<arguments>...]]
END
        ok {sout}.include?(<<"END")
Options:
  -h, --help         : print help message (of action if action specified)
  -V, --version      : print version
END
        ok {sout}.include?(<<"END")
Actions:
END
      ensure
        $COLOR_MODE = bkup
      end
    end

  end


  topic '#do_validate_actions()' do

    spec "[!6xhvt] reports warning at end of help message." do
      class ValidateActionTest1 < Benry::CmdApp::Action
        prefix "validate1", alias_of: :test
        @action.("test")
        def test1(); end
      end
      @app.config.default_help = true
      begin
        [["-h"], []].each do |args|
          sout, serr = capture_sio { @app.run(*args) }
          ok {serr} == <<'END'

** [warning] in 'ValidateActionTest1' class, `alias_of: :test` specified but corresponding action not exist.
END
        end
      ensure
        ValidateActionTest1.class_eval { @__aliasof__ = nil }
      end
    end

    spec "[!iy241] reports warning if `alias_of:` specified in action class but corresponding action not exist." do
      class ValidateActionTest2 < Benry::CmdApp::Action
        prefix "validate2", alias_of: :test2
        @action.("test")
        def test(); end
      end
      begin
        sout, serr = capture_sio { @app.__send__(:do_validate_actions, [], {}) }
        ok {serr} == <<'END'

** [warning] in 'ValidateActionTest2' class, `alias_of: :test2` specified but corresponding action not exist.
END
      ensure
        ValidateActionTest2.class_eval { @__aliasof__ = nil }
      end
    end

    spec "[!h7lon] reports warning if `default:` specified in action class but corresponding action not exist." do
      class ValidateActionTest3 < Benry::CmdApp::Action
        prefix "validate3", default: :test3
        @action.("test")
        def test(); end
      end
      begin
        sout, serr = capture_sio { @app.__send__(:do_validate_actions, [], {}) }
        ok {serr} == <<'END'

** [warning] in 'ValidateActionTest3' class, `default: :test3` specified but corresponding action not exist.
END
      ensure
        ValidateActionTest3.class_eval { @__default__ = nil }
      end
    end

  end


  topic '#do_print_candidates()' do

    spec "[!0e8vt] prints candidate action names including prefix name without tailing ':'." do
      class CandidateTest2 < Benry::CmdApp::Action
        prefix "candi:date2", default: :eee
        @action.("test1")
        def ddd(); end
        @action.("test2")
        def ccc(); end
        @action.("test3")
        def eee(); end
      end
      sout, serr = capture_sio do
        @app.__send__(:do_print_candidates, ["candi:date2:"], {})
      end
      ok {serr} == ""
      ok {sout} == <<"END"
Actions:
  candi:date2        : test3
  candi:date2:ccc    : test2
  candi:date2:ddd    : test1
END
    end

    spec "[!85i5m] candidate actions should include alias names." do
      class CandidateTest3 < Benry::CmdApp::Action
        prefix "candi:date3", default: :ggg
        @action.("test1")
        def hhh(); end
        @action.("test2")
        def fff(); end
        @action.("test3")
        def ggg(); end
      end
      Benry::CmdApp.action_alias("pupu", "candi:date3:fff")
      Benry::CmdApp.action_alias("popo", "candi:date3:fff")
      Benry::CmdApp.action_alias("candi:date3:xxx", "candi:date3:hhh")
      sout, serr = capture_sio do
        @app.__send__(:do_print_candidates, ["candi:date3:"], {})
      end
      ok {serr} == ""
      ok {sout} == <<"END"
Actions:
  candi:date3        : test3
  candi:date3:fff    : test2
                       (alias: pupu, popo)
  candi:date3:hhh    : test1
                       (alias: candi:date3:xxx)
  candi:date3:xxx    : alias of 'candi:date3:hhh' action
END
    end

    spec "[!i2azi] raises error when no candidate actions found." do
      pr = proc do
        @app.__send__(:do_print_candidates, ["candi:date9:"], {})
      end
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "No actions starting with 'candi:date9:'.")
    end

    spec "[!k3lw0] private (hidden) action should not be printed as candidates." do
      class CandidateTest4 < Benry::CmdApp::Action
        prefix "candi:date4"
        @action.("test1")
        def kkk(); end
        private
        @action.("test2")
        def iii(); end
        public
        @action.("test3")
        def jjj(); end
      end
      sout, serr = capture_sio do
        @app.__send__(:do_print_candidates, ["candi:date4:"], {})
      end
      ok {serr} == ""
      ok {sout} == <<"END"
Actions:
  candi:date4:jjj    : test3
  candi:date4:kkk    : test1
END
    end

  end


  topic '#do_setup()' do

    spec "[!pkio4] sets config object to '$cmdapp_config'." do
      $cmdapp_config = nil
      @app.__send__(:do_setup,)
      ok {$cmdapp_config} != nil
      ok {$cmdapp_config} == @app.config
    end

  end


  topic '#do_teardown()' do

    spec "[!zxeo7] clears '$cmdapp_config'." do
      $cmdapp_config = "AAA"
      @app.__send__(:do_teardown, nil)
      ok {$cmdapp_config} == nil
    end

  end


end


topic Benry::CmdApp::CommandHelpBuilder do
  include CommonTestingHelper

  def _clear_index_except(klass)
    @_bkup_actions = Benry::CmdApp::Index::ACTIONS.dup()
    Benry::CmdApp::Index::ACTIONS.delete_if {|_, x| x.klass != klass }
    anames = Benry::CmdApp::Index::ACTIONS.keys()
    @_bkup_aliases = Benry::CmdApp::Index::ALIASES.dup()
    Benry::CmdApp::Index::ALIASES.delete_if {|_, a| ! anames.include?(a.action_name) }
  end

  def _restore_index()
    Benry::CmdApp::Index::ACTIONS.update(@_bkup_actions)
    Benry::CmdApp::Index::ALIASES.update(@_bkup_aliases)
  end

  before do
    @config = Benry::CmdApp::Config.new("test app", "1.0.0").tap do |config|
      config.app_name     = "TestApp"
      config.app_command  = "testapp"
      config.option_all   = true
      config.option_debug = true
    end
    @schema = Benry::CmdApp::GlobalOptionSchema.new(@config)
    @builder = Benry::CmdApp::CommandHelpBuilder.new(@config, @schema)
  end

  topic '#build_help_message()' do

    class HelpMessageTest < Benry::CmdApp::Action
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
      _clear_index_except(HelpMessageTest)
    end

    after do
      _restore_index()
    end

    expected_color = <<"END"
TestApp (1.0.0) -- test app

\e[34mUsage:\e[0m
  $ \e[1mtestapp\e[0m [<options>] [<action> [<arguments>...]]

\e[34mOptions:\e[0m
  \e[1m-h, --help        \e[0m : print help message (of action if action specified)
  \e[1m-V, --version     \e[0m : print version
  \e[1m-a, --all         \e[0m : list all actions/options including private (hidden) ones
  \e[1m-D, --debug       \e[0m : set $DEBUG_MODE to true

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
  -h, --help         : print help message (of action if action specified)
  -V, --version      : print version
  -a, --all          : list all actions/options including private (hidden) ones
  -D, --debug        : set $DEBUG_MODE to true

Actions:
  ya:ya              : greeting #2
  yes                : alias of 'yo-yo' action
  yo-yo              : greeting #1
END

    spec "[!rvpdb] returns help message." do
      msg = @builder.build_help_message()
      msg = uncolorize(msg)
      ok {msg} == expected_mono
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
  -h, --help         : print help message (of action if action specified)
  -V, --version      : print version
  -a, --all          : list all actions/options including private (hidden) ones
  -D, --debug        : set $DEBUG_MODE to true

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
  -h, --help         : print help message (of action if action specified)
  -a, --all          : list all actions/options including private (hidden) ones

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
  -h, --help         : print help message (of action if action specified)
  -a, --all          : list all actions/options including private (hidden) ones

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
  -h, --help         : print help message (of action if action specified)
  -a, --all          : list all actions/options including private (hidden) ones
  -L                 : private option

Actions:
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

    spec "[!cfijh] includes section title and content if specified by config." do
      @config.help_sections = [
        ["Example", "  $ echo 'Hello, world!'"],
        ["Tips"   , "  * Try `--help` option.\n"],
      ]
      msg = @builder.build_help_message()
      ok {msg}.end_with?(<<"END")

\e[34mExample\e[0m
  $ echo 'Hello, world!'

\e[34mTips\e[0m
  * Try `--help` option.
END
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

  end


  topic '#build_aliases()' do

    class BuildAliasTest < Benry::CmdApp::Action
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
      _clear_index_except(BuildAliasTest)
    end

    after do
      _restore_index()
    end

    def new_help_builder(**kws)
      config  = Benry::CmdApp::Config.new("test app", "1.2.3", **kws)
      schema  = Benry::CmdApp::GlobalOptionSchema.new(config)
      builder = Benry::CmdApp::CommandHelpBuilder.new(config, schema)
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

    spec "[!p3oh6] now show 'Aliases:' section if no aliases defined." do
      Benry::CmdApp::Index::ALIASES.clear()
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
