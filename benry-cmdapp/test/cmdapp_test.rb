# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/ok'

require 'benry/cmdapp'



describe Benry::CmdApp::Util do


  describe '.hidden_name?()' do

    it "[!fcfic] returns true if name is '_foo'." do
      ok {Benry::CmdApp::Util.hidden_name?("_foo")} == true
    end

    it "[!po5co] returns true if name is '_foo:bar'." do
      ok {Benry::CmdApp::Util.hidden_name?("_foo:bar")} == true
    end

    it "[!9iqz3] returns true if name is 'foo:_bar'." do
      ok {Benry::CmdApp::Util.hidden_name?("foo:_bar")} == true
    end

    it "[!mjjbg] returns false if else." do
      ok {Benry::CmdApp::Util.hidden_name?("foo")} == false
      ok {Benry::CmdApp::Util.hidden_name?("foo_")} == false
      ok {Benry::CmdApp::Util.hidden_name?("foo_:bar")} == false
      ok {Benry::CmdApp::Util.hidden_name?("foo:bar_")} == false
    end

  end


  describe '.schema_empty?()' do

    it "[!8t5ju] returns true if schema empty." do
      sc = Benry::CmdOpt::Schema.new
      ok {Benry::CmdApp::Util.schema_empty?(sc)} == true
      sc.add(:help, "-h", "help")
      ok {Benry::CmdApp::Util.schema_empty?(sc)} == false
    end

    it "[!c4ljy] returns true if schema contains only private (hidden) options." do
      sc = Benry::CmdOpt::Schema.new
      sc.add(:_help, "-h", "help")
      ok {Benry::CmdApp::Util.schema_empty?(sc)} == true
      sc.add(:version, "-V", "version")
      ok {Benry::CmdApp::Util.schema_empty?(sc)} == false
    end

  end


  describe '.method2action()' do

    it "[!801f9] converts action name 'aa_bb_cc_' into 'aa_bb_cc'." do
      ok {Benry::CmdApp::Util.method2action("aa_")} == "aa"
      ok {Benry::CmdApp::Util.method2action("_aa_")} == "_aa"
    end

    it "[!9pahu] converts action name 'aa__bb__cc' into 'aa:bb:cc'." do
      ok {Benry::CmdApp::Util.method2action("aa__bb__cc")} == "aa:bb:cc"
    end

    it "[!7a1s7] converts action name 'aa_bb:_cc_dd' into 'aa-bb:_cc-dd'." do
      ok {Benry::CmdApp::Util.method2action("aa_bb:cc_dd")} == "aa-bb:cc-dd"
      ok {Benry::CmdApp::Util.method2action("aa_bb:_cc_dd")} == "aa-bb:_cc-dd"
      ok {Benry::CmdApp::Util.method2action("aa___bb")} == "aa:_bb"
    end

  end


  describe '.colorize?()' do

    it "[!801y1] returns $COLOR_MODE value if it is not nil." do
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

    it "[!0harg] returns true if stdout is a tty." do
      capture_io {
        def $stdout.tty?; true; end
        ok {Benry::CmdApp::Util.colorize?()} == true
      }
    end

    it "[!u1j1x] returns false if stdout is not a tty." do
      capture_io {
        def $stdout.tty?; false; end
        ok {Benry::CmdApp::Util.colorize?()} == false
      }
    end

  end


  describe '.del_escape_seq()' do

    it "[!wgp2b] deletes escape sequence." do
      s = "  \e[1m%-18s\e[0m : %s"
      ok {Benry::CmdApp::Util.del_escape_seq(s)} == "  %-18s : %s"
    end

  end


end


describe Benry::CmdApp::Index do


  class IndexTestAction < Benry::CmdApp::Action
    @action.("lookup test #1")
    def lookup1(); end
    #
    @action.("lookup test #2")
    def lookup2(); end
    #
    private
    @action.("lookup test #3")   # hidden
    def lookup3(); end
  end

  Benry::CmdApp.action_alias("findxx", "lookup2")


  describe '.lookup_action()' do

    it "[!vivoa] returns action metadata object." do
      x = Benry::CmdApp::Index.lookup_action("lookup1")
      ok {x} != nil
      ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
      ok {x.name} == "lookup1"
      ok {x.klass} == IndexTestAction
      ok {x.method} == :lookup1
    end

    it "[!tnwq0] supports alias name." do
      x = Benry::CmdApp::Index.lookup_action("findxx")
      ok {x} != nil
      ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
      ok {x.name} == "lookup2"
      ok {x.klass} == IndexTestAction
      ok {x.method} == :lookup2
    end

  end


  describe '.each_action_name_and_desc()' do

    before do
      @_bkup_actions = Benry::CmdApp::Index::ACTIONS.dup()
      Benry::CmdApp::Index::ACTIONS.delete_if {|_, x| x.klass != IndexTestAction }
      anames = Benry::CmdApp::Index::ACTIONS.keys()
      @_bkup_aliases = Benry::CmdApp::Index::ALIASES.dup()
      Benry::CmdApp::Index::ALIASES.delete_if {|_, x| ! anames.include?(x) }
    end

    after do
      Benry::CmdApp::Index::ACTIONS.update(@_bkup_actions)
      Benry::CmdApp::Index::ALIASES.update(@_bkup_aliases)
    end

    it "[!5lahm] yields action name and description." do
      arr = []
      Benry::CmdApp::Index.each_action_name_and_desc(false) {|a| arr << a }
      ok {arr} == [
        ["lookup1", "lookup test #1"],
        ["lookup2", "lookup test #2"],
      ]
    end

    it "[!27j8b] includes alias names when the first arg is true." do
      arr = []
      Benry::CmdApp::Index.each_action_name_and_desc(true) {|a| arr << a }
      ok {arr} == [
        ["findxx", "alias of 'lookup2' action"],
        ["lookup1", "lookup test #1"],
        ["lookup2", "lookup test #2"],
      ]
    end

    it "[!8xt8s] rejects hidden actions if 'all: false' kwarg specified." do
      arr = []
      Benry::CmdApp::Index.each_action_name_and_desc(false, all: false) {|a| arr << a }
      ok {arr} == [
        ["lookup1", "lookup test #1"],
        ["lookup2", "lookup test #2"],
      ]
    end

    it "[!5h7s5] includes hidden actions if 'all: true' kwarg specified." do
      arr = []
      Benry::CmdApp::Index.each_action_name_and_desc(false, all: true) {|a| arr << a }
      ok {arr} == [
        ["lookup1", "lookup test #1"],
        ["lookup2", "lookup test #2"],
        ["lookup3", "lookup test #3"],   # hidden action
      ]
    end

    it "[!arcia] action names are sorted." do
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

  def capture_sio(tty: false, &block)
    capture_io do
      if tty
        def $stdout.tty?; true; end
      end
      yield
    end
  end

  def without_tty(&block)
    result = nil
    capture_io { result = yield }
    return result
  end

  def with_tty(&block)
    result = nil
    capture_io do
      def $stdout.tty?; true; end
      result = yield
    end
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


describe Benry::CmdApp::ActionMetadata do
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


  describe '#hidden?()' do

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

    it "[!kp10p] returns true when action method is private." do
      ameta = Benry::CmdApp::Index::ACTIONS["pphidden3"]
      ok {ameta.hidden?} == true
      ameta = Benry::CmdApp::Index::ACTIONS["pphidden2"]
      ok {ameta.hidden?} == true
    end

    it "[!nw322] returns false when action method is not private." do
      ameta = Benry::CmdApp::Index::ACTIONS["pphidden1"]
      ok {ameta.hidden?} == false
    end

  end


  describe '#parse_options()' do

    it "[!ab3j8] parses argv and returns options." do
      args = ["-l", "fr", "Alice"]
      opts = @metadata.parse_options(args)
      ok {opts} == {:lang => "fr"}
      ok {args} == ["Alice"]
      args = ["--lang=it", "Bob"]
      opts = @metadata.parse_options(args)
      ok {opts} == {:lang => "it"}
      ok {args} == ["Bob"]
    end

  end


  describe '#run_action()' do

    it "[!veass] runs action with args and kwargs." do
      args = ["Alice"]; kwargs = {lang: "fr"}
      #
      sout, serr = capture_io { @metadata.run_action() }
      ok {sout} == "Hello, world!\n"
      ok {serr} == ""
      #
      sout, serr = capture_io { @metadata.run_action(*args) }
      ok {sout} == "Hello, Alice!\n"
      ok {serr} == ""
      #
      sout, serr = capture_io { @metadata.run_action(**kwargs) }
      ok {sout} == "Bonjour, world!\n"
      ok {serr} == ""
      #
      sout, serr = capture_io { @metadata.run_action(*args, **kwargs) }
      ok {sout} == "Bonjour, Alice!\n"
      ok {serr} == ""
    end

    def _tracing_mode(flag, &block)
      bkup = $TRACING_MODE
      $TRACING_MODE = true
      begin
        return yield
      ensure
        $TRACING_MODE = bkup
      end
    end

    it "[!tubhv] if $TRACING_MODE is on, prints tracing info." do
      args = ["Alice"]; kwargs = {lang: "it"}
      sout, serr = _tracing_mode(true) do
        capture_io {
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

    it "[!zgp14] tracing info is colored when stdout is a tty." do
      args = ["Alice"]; kwargs = {lang: "it"}
      sout, serr = _tracing_mode(true) do
        capture_io {
          def $stdout.tty?; true; end
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


  describe '#method_arity()' do

    it "[!7v4tp] returns min and max number of positional arguments." do
      ok {@metadata.method_arity()} == [0, 1]
    end

    it "[!w3rer] max is nil if variable argument exists." do
      schema = Benry::Cmdopt::Schema.new
      metadata = Benry::CmdApp::ActionMetadata.new("halo2", MetadataTestAction, :halo2, "greeting", schema)
      ok {metadata.method_arity()} == [0, nil]
    end

  end


  describe '#validate_method_params()' do

    it "[!plkhs] returns error message if keyword parameter for option not exist." do
      schema = Benry::Cmdopt::Schema.new
      schema.add(:foo, "--foo", "foo")
      metadata = Benry::CmdApp::ActionMetadata.new("halo1", MetadataTestAction, :halo1, "greeting", schema)
      msg = metadata.validate_method_params()
      ok {msg} == "should have keyword parameter 'foo' for '@option.(:foo)', but not."
    end

    it "[!1koi8] returns nil if all keyword parameters for option exist." do
      schema = Benry::Cmdopt::Schema.new
      schema.add(:lang, "-l, --lang=<lang>", "lang")
      metadata = Benry::CmdApp::ActionMetadata.new("halo1", MetadataTestAction, :halo1, "greeting", schema)
      msg = metadata.validate_method_params()
      ok {msg} == nil
    end

  end


  describe '#help_message()' do

    it "[!i7siu] returns help message of action." do
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


describe Benry::CmdApp::ActionHelpMessageBuilder do
  include ActionMetadataTestingHelper


  describe '#build_help_message()' do

    it "[!pqoup] adds detail text into help if specified." do
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

    it "[!zbc4y] adds '[<options>]' into 'Usage:' section only when any options exist." do
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

    it "[!8b02e] ignores '[<options>]' in 'Usage:' when only hidden options speicified." do
      schema = new_schema(lang: false)
      schema.add(:_lang, "-l, --lang=<en|fr|it>", "language")
      msg = new_metadata(schema).help_message("testapp")
      msg = uncolorize(msg)
      ok {msg} =~ /^  \$ testapp halo1 \[<user>\]\n/
      ok {msg} =~ /^Usage:\n  \$ testapp halo1 \[<user>\]$/
    end

    it "[!ou3md] not add extra whiespace when no arguments of command." do
      schema = new_schema(lang: true)
      msg = new_metadata(schema, :halo3).help_message("testapp")
      msg = uncolorize(msg)
      ok {msg} =~ /^  \$ testapp halo3 \[<options>\]\n/
      ok {msg} =~ /^Usage:\n  \$ testapp halo3 \[<options>\]$/
    end

    it "[!g2ju5] adds 'Options:' section." do
      schema = new_schema(lang: true)
      msg = new_metadata(schema).help_message("testapp")
      msg = uncolorize(msg)
      ok {msg}.include?("Options:\n" +
                        "  -l, --lang=<en|fr|it> : language\n")
    end

    it "[!pvu56] ignores 'Options:' section when no options exist." do
      schema = new_schema(lang: false)
      msg = new_metadata(schema).help_message("testapp")
      msg = uncolorize(msg)
      ok {msg}.NOT.include?("Options:\n")
    end

    it "[!hghuj] ignores 'Options:' section when only hidden options speicified." do
      schema = new_schema(lang: false)
      schema.add(:_lang, "-l, --lang=<en|fr|it>", "language")  # hidden option
      msg = new_metadata(schema).help_message("testapp")
      msg = uncolorize(msg)
      ok {msg}.NOT.include?("Options:\n")
    end

    it "[!0p2gt] adds postamble text if specified." do
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

    it "[!v5567] adds '\n' at end of preamble text if it doesn't end with '\n'." do
      postamble = "END"
      schema = new_schema(lang: false)
      ameta = new_metadata(schema, postamble: postamble)
      msg = ameta.help_message("testapp")
      ok {msg}.end_with?("\nEND\n")
    end

    it "[!x0z89] required arg is represented as '<arg>'." do
      schema = new_schema(lang: false)
      metadata = Benry::CmdApp::ActionMetadata.new("args1", MetadataTestAction, :args1, "", schema)
      msg = metadata.help_message("testapp")
      msg = uncolorize(msg)
      ok {msg} =~ /^  \$ testapp args1 <aa> <bb>$/
    end

    it "[!md7ly] optional arg is represented as '[<arg>]'." do
      schema = new_schema(lang: false)
      metadata = Benry::CmdApp::ActionMetadata.new("args2", MetadataTestAction, :args2, "", schema)
      msg = without_tty { metadata.help_message("testapp") }
      msg = uncolorize(msg)
      ok {msg} =~ /^  \$ testapp args2 <aa> \[<bb> \[<cc>\]\]$/
    end

    it "[!xugkz] variable args are represented as '[<arg>...]'." do
      schema = new_schema(lang: false)
      metadata = Benry::CmdApp::ActionMetadata.new("args3", MetadataTestAction, :args3, "", schema)
      msg = metadata.help_message("testapp")
      msg = uncolorize(msg)
      ok {msg} =~ /^  \$ testapp args3 <aa> \[<bb> \[<cc> \[<dd>...\]\]\]$/
    end

    it "[!eou4h] converts arg name 'xx_or_yy_or_zz' into 'xx|yy|zz'." do
      schema = new_schema(lang: false)
      metadata = Benry::CmdApp::ActionMetadata.new("args4", MetadataTestAction, :args4, "", schema)
      msg = metadata.help_message("testapp")
      msg = uncolorize(msg)
      ok {msg} =~ /^  \$ testapp args4 <xx\|yy\|zz>$/
    end

    it "[!naoft] converts arg name '_xx_yy_zz' into '_xx-yy-zz'." do
      schema = new_schema(lang: false)
      metadata = Benry::CmdApp::ActionMetadata.new("args5", MetadataTestAction, :args5, "", schema)
      msg = metadata.help_message("testapp")
      msg = uncolorize(msg)
      ok {msg} =~ /^  \$ testapp args5 <_xx-yy-zz>$/
    end

  end


end


describe Benry::CmdApp::Action do


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


  describe '#run_action_once()' do

    it "[!oh8dc] don't invoke action if already invoked." do
      sout, serr = capture_io() do
        @action.run_action_once("test3:foo:invoke2", "Alice", lang: "fr")
      end
      ok {sout} == "Bonjour, Alice!\n"
      sout, serr = capture_io() do
        @action.run_action_once("test3:foo:invoke2", "Alice", lang: "fr")
      end
      ok {sout} == ""
      ok {serr} == ""
    end

  end


  describe '#run_action!()' do

    it "[!2yrc2] invokes action even if already invoked." do
      sout, serr = capture_io() do
        @action.run_action!("test3:foo:invoke3", "Alice", lang: "fr")
      end
      ok {sout} == "Bonjour, Alice!\n"
      sout, serr = capture_io() do
        @action.run_action!("test3:foo:invoke3", "Alice", lang: "fr")
      end
      ok {sout} == "Bonjour, Alice!\n"
      sout, serr = capture_io() do
        @action.run_action!("test3:foo:invoke3", "Alice", lang: "en")
      end
      ok {sout} == "Hello, Alice!\n"
    end

  end


  describe '#__run_action()' do

    def __run_action(action_name, once, args, kwargs)
      @action.__send__(:__run_action, action_name, once, args, kwargs)
    end

    def __run_loop(action_name, once, args, kwargs)
      action = LoopedActionTest.new()
      action.__send__(:__run_action, action_name, once, args, kwargs)
    end

    it "[!7vszf] raises error if action specified not found." do
      pr = proc { __run_action("loop9", nil, ["Alice"], {}) }
      ok {pr}.raise?(Benry::CmdApp::ActionNotFoundError, "loop9: action not found.")
    end

    it "[!u8mit] raises error if action flow is looped." do
      pr = proc { __run_loop("loop1", nil, [], {}) }
      ok {pr}.raise?(Benry::CmdApp::LoopedActionError, "loop1: looped action detected.")
    end

    it "[!vhdo9] don't invoke action twice if 'once' arg is true." do
      sout, serr = capture_io() do
        __run_action("test3:foo:invoke2", true, ["Alice"], {lang: "fr"})
      end
      ok {sout} == "Bonjour, Alice!\n"
      sout, serr = capture_io() do
        __run_action("test3:foo:invoke2", true, ["Alice"], {lang: "fr"})
      end
      ok {sout} == ""
      ok {serr} == ""
    end

    it "[!r8fbn] invokes action." do
      sout, serr = capture_io() do
        __run_action("test3:foo:invoke1", false, ["Alice"], {lang: "fr"})
      end
      ok {sout} == "Bonjour, Alice!\n"
    end

  end


  describe '.prefix()' do

    it "[!1gwyv] converts symbol into string." do
      class PrefixTest1 < Benry::CmdApp::Action
        prefix :foo
      end
      prefix = PrefixTest1.instance_variable_get('@__prefix__')
      ok {prefix} == "foo:"
    end

    it "[!pz46w] error if prefix contains extra '_'." do
      pr = proc do
        class PrefixTest2 < Benry::CmdApp::Action
          prefix "foo_bar"
        end
      end
      ok {pr}.raise?(Benry::CmdApp::ActionDefError,
                     "foo_bar: invalid prefix name (please use ':' or '-' instead of '_' as word separator).")
    end

    it "[!9pu01] adds ':' at end of prefix name if prefix not end with ':'." do
      class PrefixTest3 < Benry::CmdApp::Action
        prefix "foo:bar"
      end
      prefix = PrefixTest3.instance_variable_get('@__prefix__')
      ok {prefix} == "foo:bar:"
    end

  end


  describe '.inherited()' do

    it "[!f826w] registers all subclasses into 'Action::SUBCLASSES'." do
      class InheritedTest0a < Benry::CmdApp::Action
      end
      class InheritedTest0b < Benry::CmdApp::Action
      end
      ok {Benry::CmdApp::Action::SUBCLASSES}.include?(InheritedTest0a)
      ok {Benry::CmdApp::Action::SUBCLASSES}.include?(InheritedTest0b)
    end

    it "[!2imrb] sets class instance variables in subclass." do
      class InheritedTest1 < Benry::CmdApp::Action
      end
      ivars = InheritedTest1.instance_variables().sort()
      ok {ivars} == [:@__action__, :@__aliasof__, :@__default__, :@__option__, :@__prefix__, :@action, :@copy_options, :@option]
    end

    it "[!1qv12] @action is a Proc object and saves args." do
      class InheritedTest2 < Benry::CmdApp::Action
        @action.("description", detail: "xxx", postamble: "yyy", tag: "zzz")
      end
      x = InheritedTest2.instance_variable_get('@__action__')
      ok {x} == ["description", {detail: "xxx", postamble: "yyy", tag: "zzz"}]
    end

    it "[!33ma7] @option is a Proc object and saves args." do
      class InheritedTest3 < Benry::CmdApp::Action
        @action.("description", detail: "xxx", postamble: "yyy")
        @option.(:xx, "-x, --xxx=<N>", "desc 1", type: Integer, rexp: /\A\d+\z/, enum: [2,4,8])
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
      ok {items[0].value}  == nil
      ok {items[1].key}    == :yy
      ok {items[1].optdef} == "-y, --yyy[=<on|off>]"
      ok {items[1].desc}   == "desc 2"
      ok {items[1].type}   == TrueClass
      ok {items[1].rexp}   == nil
      ok {items[1].enum}   == nil
      ok {items[1].value}  == false
    end

    it "[!gxybo] '@option.()' raises error when '@action.()' not called." do
      pr = proc do
        class InheritedTest4 < Benry::CmdApp::Action
          @option.(:xx, "-x, --xxx=<N>", "desc 1")
        end
      end
      ok {pr}.raise?(Benry::CmdApp::OptionDefError,
                     "@option.(:xx): `@action.()` required but not called.")
    end

    it "[!yrkxn] @copy_options is a Proc object and copies options from other action." do
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

    it "[!mhhn2] '@copy_options.()' raises error when action not found." do
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


  describe '.method_added()' do

    def defined_actions()
      action_names = Benry::CmdApp::Index::ACTIONS.keys()
      yield
      new_names = Benry::CmdApp::Index::ACTIONS.keys() - action_names
      metadata = new_names.length > 0 ? Benry::CmdApp::Index::ACTIONS[new_names[0]] : nil
      return new_names, metadata
    end

    it "[!idh1j] do nothing if '@__action__' is nil." do
      new_names, x = defined_actions() do
        class Added1Test < Benry::CmdApp::Action
          prefix "added1"
          def hello1(); end
        end
      end
      ok {new_names} == []
      ok {x} == nil
    end

    it "[!ernnb] clears both '@__action__' and '@__option__'." do
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

    it "[!n8tem] creates ActionMetadata object if '@__action__' is not nil." do
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

    it "[!4pbsc] raises error if keyword param for option not exist in method." do
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

    describe '[!5e5o0] when method name is same as default action name...' do

      it "[!myj3p] uses prefix name (expect last char ':') as action name." do
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

      it "[!j5oto] clears '@__default__'." do
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

    describe '[!agpwh] else...' do

      it "[!3icc4] uses method name as action name." do
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

      it "[!c643b] converts action name 'aa_bb_cc_' into 'aa_bb_cc'." do
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

      it "[!3fkb3] converts action name 'aa__bb__cc' into 'aa:bb:cc'." do
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

      it "[!o9s9h] converts action name 'aa_bb:_cc_dd' into 'aa-bb:_cc-dd'." do
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

      it "[!8hlni] when action name is same as default name, uses prefix as action name." do
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

      it "[!q8oxi] clears '@__default__' when default name matched to action name." do
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

      it "[!xfent] when prefix is provided, adds it to action name." do
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

    it "[!jpzbi] defines same name alias of action as prefix." do
      ## when symbol
      class AliasOfTest1 < Benry::CmdApp::Action
        prefix "blabla1", alias_of: :bla1    # symbol
        @action.("test")
        def bla1(); end
      end
      ok {Benry::CmdApp::Index::ALIASES["blabla1"]} == "blabla1:bla1"
      ## when string
      class AliasOfTest2 < Benry::CmdApp::Action
        prefix "bla:bla2", alias_of: "blala"    # string
        @action.("test")
        def blala(); end
      end
      ok {Benry::CmdApp::Index::ALIASES["bla:bla2"]} == "bla:bla2:blala"
    end

    it "[!tvjb0] clears '@__aliasof__' only when alias created." do
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

    it "[!997gs] not raise error when action not found." do
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

    it "[!349nr] raises error when same name action or alias with prefix already exists." do
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


describe Benry::CmdApp do


  describe '.action_alias()' do

    class Alias1Test < Benry::CmdApp::Action
      prefix "alias1"
      @action.("alias test")
      def a1(); end
      @action.("alias test")
      def a2(); end
    end

    it "[!vzlrb] registers alias name with action name." do
      Benry::CmdApp.action_alias("a4", "alias1:a1")
      ok {Benry::CmdApp::Index::ALIASES}.key?("a4")
      ok {Benry::CmdApp::Index::ALIASES["a4"]} == "alias1:a1"
    end

    it "[!5immb] convers both alias name and action name into string." do
      Benry::CmdApp.action_alias(:a5, :'alias1:a2')
      ok {Benry::CmdApp::Index::ALIASES}.key?("a5")
      ok {Benry::CmdApp::Index::ALIASES["a5"]} == "alias1:a2"
    end

    it "[!nrz3d] error if action not found." do
      pr = proc { Benry::CmdApp.action_alias(:a5, :'alias1:a5') }
      ok {pr}.raise?(Benry::CmdApp::AliasDefError,
                     "action_alias(:a5, :\"alias1:a5\"): action not found.")
    end

    it "[!vvmwd] error when action with same name as alias exists." do
      pr = proc { Benry::CmdApp.action_alias(:'alias1:a2', :'alias1:a1') }
      ok {pr}.raise?(Benry::CmdApp::AliasDefError,
                     "action_alias(:\"alias1:a2\", :\"alias1:a1\"): not allowed to define same name alias as existing action.")
    end

    it "[!i9726] error if alias already defined." do
      pr1 = proc { Benry::CmdApp.action_alias(:'a6', :'alias1:a1') }
      pr2 = proc { Benry::CmdApp.action_alias(:'a6', :'alias1:a2') }
      ok {pr1}.NOT.raise?(Exception)
      ok {pr2}.raise?(Benry::CmdApp::AliasDefError,
                      "action_alias(:a6, :\"alias1:a2\"): alias name duplicated.")
    end

  end

end


describe Benry::CmdApp::Config do


  describe '#initialize()' do

    it "[!uve4e] sets command name automatically if not provided." do
      config = Benry::CmdApp::Config.new("test")
      ok {config.app_command} != nil
      ok {config.app_command} == File.basename($0)
    end

  end


end


describe Benry::CmdApp::GlobalOptionSchema do


  describe '.create()' do

    def new_gschema(desc="", version=nil, **kwargs)
      config = Benry::CmdApp::Config.new(desc, version, **kwargs)
      x = Benry::CmdApp::GlobalOptionSchema.create(config)
      return x
    end

    it "[!enuxy] creates schema object." do
      x = new_gschema()
      ok {x}.is_a?(Benry::CmdApp::GlobalOptionSchema)
    end

    it "[!tq2ol] adds '-h, --help' option if 'config.option_help' is set." do
      x = new_gschema(option_help: true)
      ok {x.find_long_option("help")} != nil
      ok {x.find_short_option("h")}   != nil
      x = new_gschema(option_help: false)
      ok {x.find_long_option("help")} == nil
      ok {x.find_short_option("h")}   == nil
    end

    it "[!mbtw0] adds '-V, --version' option if 'config.app_version' is set." do
      x = new_gschema("", "0.0.0")
      ok {x.find_long_option("version")} != nil
      ok {x.find_short_option("V")}      != nil
      x = new_gschema("", nil)
      ok {x.find_long_option("version")} == nil
      ok {x.find_short_option("V")}      == nil
    end

    it "[!f5do6] adds '-a, --all' option if 'config.option_all' is set." do
      x = new_gschema(option_all: true)
      ok {x.find_long_option("all")} != nil
      ok {x.find_short_option("a")}  != nil
      x = new_gschema(option_all: false)
      ok {x.find_long_option("all")} == nil
      ok {x.find_short_option("a")}  == nil
    end

    it "[!cracf] adds '-v, --verbose' option if 'config.option_verbose' is set." do
      x = new_gschema(option_verbose: true)
      ok {x.find_long_option("verbose")} != nil
      ok {x.find_short_option("v")}  != nil
      x = new_gschema(option_verbose: false)
      ok {x.find_long_option("verbose")} == nil
      ok {x.find_short_option("v")}  == nil
    end

    it "[!2vil6] adds '-q, --quiet' option if 'config.option_quiet' is set." do
      x = new_gschema(option_quiet: true)
      ok {x.find_long_option("quiet")} != nil
      ok {x.find_short_option("q")}  != nil
      x = new_gschema(option_quiet: false)
      ok {x.find_long_option("quiet")} == nil
      ok {x.find_short_option("q")}  == nil
    end

    it "[!6zw3j] adds '--color=<on|off>' option if 'config.option_color' is set." do
      x = new_gschema(option_color: true)
      ok {x.find_long_option("color")} != nil
      x = new_gschema(option_quiet: false)
      ok {x.find_long_option("color")} == nil
    end

    it "[!29wfy] adds '-D, --debug' option if 'config.option_debug' is set." do
      x = new_gschema(option_debug: true)
      ok {x.find_long_option("debug")} != nil
      ok {x.find_short_option("D")}    != nil
      x = new_gschema(option_debug: false)
      ok {x.find_long_option("debug")} == nil
      ok {x.find_short_option("D")}    == nil
    end

  end


end


describe Benry::CmdApp::Application do
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
    sout, serr = capture_io { @app.run(*args) }
    ok {serr} == ""
    return sout
  end


  describe '#initialize()' do

    it "[!jkprn] creates option schema object according to config." do
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

    it "[!h786g] acceps callback block." do
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


  describe '#main()' do

    after do
      $cmdapp_config = nil
    end

    it "[!y6q9z] runs action with options." do
      sout, serr = capture_io { @app.main(["sayhello", "-l", "it", "Alice"]) }
      ok {serr} == ""
      ok {sout} == "Ciao, Alice!\n"
    end

    it "[!a7d4w] prints error message with '[ERROR]' prompt." do
      sout, serr = capture_io { @app.main(["sayhello", "Alice", "Bob"]) }
      ok {serr} == "\e[0;31m[ERROR]\e[0m sayhello: too much arguments (at most 1).\n"
      ok {sout} == ""
    end

    it "[!5oypr] returns 0 as exit code when no errors occurred." do
      ret = nil
      sout, serr = capture_io do
        ret = @app.main(["sayhello", "Alice", "-l", "it"])
      end
      ok {ret} == 0
      ok {serr} == ""
      ok {sout} == "Ciao, Alice!\n"
    end

    it "[!qk5q5] returns 1 as exit code when error occurred." do
      ret = nil
      sout, serr = capture_io do
        ret = @app.main(["sayhello", "Alice", "Bob"])
      end
      ok {ret} == 1
      ok {serr} == "\e[0;31m[ERROR]\e[0m sayhello: too much arguments (at most 1).\n"
      ok {sout} == ""
    end

  end


  describe '#run()' do

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

    it "[!t4ypg] sets $cmdapp_config at beginning." do
      sout, serr = capture_io { @app.run("check-config") }
      ok {serr} == ""
      ok {sout} == "$cmdapp_config.class=Benry::CmdApp::Config\n"
    end

    it "[!pyotc] sets global options to '@global_options'." do
      ok {@app.instance_variable_get('@global_options')} == nil
      capture_io { @app.run("--help") }
      ok {@app.instance_variable_get('@global_options')} == {:help=>true}
    end

    it "[!5iczl] skip actions if help option or version option specified." do
      def @app.do_callback(args)
        @_called_ = args.dup
      end
      capture_io { @app.run("--help") }
      ok {@app.instance_variable_get('@_called_')} == nil
      capture_io { @app.run("--version") }
      ok {@app.instance_variable_get('@_called_')} == nil
      capture_io { @app.run("sayhello") }
      ok {@app.instance_variable_get('@_called_')} == ["sayhello"]
    end

    it "[!w584g] calls callback method." do
      def @app.do_callback(args)
        @_called_ = args.dup
      end
      ok {@app.instance_variable_get('@_called_')} == nil
      capture_io { @app.run("sayhello") }
      ok {@app.instance_variable_get('@_called_')} == ["sayhello"]
    end

    it "[!pbug7] skip actions if callback method returns `:SKIP` value." do
      def @app.do_callback(args)
        @_called1 = args.dup
        return :SKIP
      end
      def @app.do_find_action(args)
        super
        @_called2 = args.dup
      end
      ok {@app.instance_variable_get('@_called1')} == nil
      ok {@app.instance_variable_get('@_called2')} == nil
      capture_io { @app.run("sayhello") }
      ok {@app.instance_variable_get('@_called1')} == ["sayhello"]
      ok {@app.instance_variable_get('@_called2')} == nil
    end

    it "[!avxos] prints candidate actions if action name ends with ':'." do
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

    it "[!l0g1l] skip actions if no action specified and 'config.default_help' is set." do
      def @app.do_find_action(args)
        ret = super
        @_args1 = args.dup
        @_result = ret
        ret
      end
      def @app.do_run_action(metadata, args)
        ret = super
        @_args2 = args.dup
        ret
      end
      @app.config.default_help = true
      capture_io { @app.run() }
      ok {@app.instance_variable_get('@_args1')} == []
      ok {@app.instance_variable_get('@_result')} == nil
      ok {@app.instance_variable_get('@_args2')} == nil
    end

    it "[!x1xgc] run action with options and arguments." do
      sout, serr = capture_io { @app.run("sayhello", "Alice", "-l", "it") }
      ok {serr} == ""
      ok {sout} == "Ciao, Alice!\n"
    end

    it "[!agfdi] reports error when action not found." do
      pr = proc { @app.run("xxx-yyy") }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "xxx-yyy: unknown action.")
    end

    it "[!v5k56] runs default action if action not specified." do
      @config.default_action = "sayhello"
      sout, serr = capture_io { @app.run() }
      ok {serr} == ""
      ok {sout} == "Hello, world!\n"
    end

    it "[!o5i3w] reports error when default action not found." do
      @config.default_action = "xxx-zzz"
      pr = proc { @app.run() }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "xxx-zzz: unknown default action.")
    end

    it "[!7h0ku] prints help if no action but 'config.default_help' is true." do
      expected, serr = capture_io { @app.run("-h") }
      ok {serr} == ""
      ok {expected} =~ /^Usage:/
      #
      @config.default_help = true
      sout, serr = capture_io { @app.run() }
      ok {serr} == ""
      ok {sout} == expected
    end

    it "[!n60o0] reports error when action nor default action not specified." do
      @config.default_action = nil
      pr = proc { @app.run() }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "testapp: action name required (run `testapp -h` for details).")
    end

    it "[!hk6iu] unsets $cmdapp_config at end." do
      bkup = $cmdapp_config
      $cmdapp_config = nil
      begin
        sout, serr = capture_io { @app.run("check-config") }
        ok {sout} == "$cmdapp_config.class=Benry::CmdApp::Config\n"
        ok {$cmdapp_config} == nil
      ensure
        $cmdapp_config = bkup
      end
    end

    it "[!wv22u] calls teardown method at end of running action." do
      def @app.do_teardown(*args)
        @_args = args
      end
      ok {@app.instance_variable_get('@_args')} == nil
      sout, serr = capture_io { @app.run("check-config") }
      ok {@app.instance_variable_get('@_args')} == [nil]
    end

    it "[!dhba4] calls teardown method even if exception raised." do
      def @app.do_teardown(*args)
        @_args = args
      end
      ok {@app.instance_variable_get('@_args')} == nil
      pr = proc { @app.run("test-exception1") }
      exc = ok {pr}.raise?(ZeroDivisionError)
      ok {@app.instance_variable_get('@_args')} == [exc]
    end

  end


  describe '#help_message()' do

    it "[!owg9y] returns help message." do
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


  describe '#do_create_global_option_schema()' do

    it "[!u3zdg] creates global option schema object according to config." do
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


  describe '#do_create_help_message_builder()' do

    it "[!pk5da] creates help message builder object." do
      config = Benry::CmdApp::Config.new("test app", "1.0.0",
                                         option_all: true, option_quiet: true)
      app = Benry::CmdApp::Application.new(config)
      x = app.__send__(:do_create_help_message_builder, config, app.schema)
      ok {x}.is_a?(Benry::CmdApp::CommandHelpMessageBuilder)
    end

  end


  describe '#do_parse_global_options()' do

    it "[!5br6t] parses only global options and not parse action options." do
      sout, serr = capture_io { @app.run("test-globalopt", "--help") }
      ok {serr} == ""
      ok {sout} == "help=true\n"
    end

  end


  describe '#do_handle_global_options()' do

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


    it "[!j6u5x] sets $VERBOSE_MODE to true if '-v' or '--verbose' specified." do
      app = new_app()
      bkup = $VERBOSE_MODE
      begin
        ["-v", "--verbose"].each do |opt|
          $VERBOSE_MODE = false
          sout, serr = capture_io { app.run(opt, "test-debugopt") }
          ok {serr} == ""
          ok {$VERBOSE_MODE} == true
        end
      ensure
        $VERBOSE_MODE = bkup
      end
    end

    it "[!p1l1i] sets $QUIET_MODE to true if '-q' or '--quiet' specified." do
      app = new_app()
      bkup = $QUIET_MODE
      begin
        ["-q", "--quiet"].each do |opt|
          $QUIET_MODE = false
          sout, serr = capture_io { app.run(opt, "test-debugopt") }
          ok {serr} == ""
          ok {$QUIET_MODE} == true
        end
      ensure
        $QUIET_MODE = bkup
      end
    end

    it "[!2zvf9] sets $COLOR_MODE to true/false according to '--color' option." do
      app = new_app()
      bkup = $COLOR_MODE
      begin
        [["--color", true], ["--color=on", true], ["--color=off", false]].each do |opt, val|
          $COLOR_MODE = !val
          sout, serr = capture_io { app.run(opt, "test-debugopt") }
          ok {serr} == ""
          ok {$COLOR_MODE} == val
        end
      ensure
        $COLOR_MODE = bkup
      end
    end

    it "[!ywl1a] sets $DEBUG_MODE to true if '-D' or '--debug' specified." do
      app = new_app()
      bkup = $DEBUG_MODE
      begin
        ["-D", "--debug"].each do |opt|
          $DEBUG_MODE = false
          sout, serr = capture_io { app.run(opt, "test-debugopt") }
          ok {serr} == ""
          ok {sout} == "$DEBUG_MODE=true\n"
        end
      ensure
        $DEBUG_MODE = bkup
      end
    end

    it "[!xvj6s] prints help message if '-h' or '--help' specified." do
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
        sout, serr = capture_io { app.run(opt) }
        ok {serr} == ""
        ok {sout}.start_with?(expected)
      end
    end

    it "[!lpoz7] prints help message of action if action name specified with help option." do
      expected = <<"END"
testapp sayhello -- print greeting message

Usage:
  $ testapp sayhello [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
END
      app = new_app()
      ["-h", "--help"].each do |opt|
        sout, serr = capture_io { app.run(opt, "sayhello") }
        ok {serr} == ""
        ok {sout} == expected
      end
    end

    it "[!fslsy] prints version if '-V' or '--version' specified." do
      app = new_app()
      ["-V", "--version"].each do |opt|
        sout, serr = capture_io { app.run(opt, "xxx") }
        ok {serr} == ""
        ok {sout} == "1.0.0\n"
      end
    end

  end


  describe '#do_set_global_switch()' do

    it "[!go9kk] sets global variable according to key." do
      bkup = [$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE]
      begin
        $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE = nil, nil, nil
        @app.__send__(:do_set_global_switch, :verbose, true)
        ok {[$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE]} == [true, nil, nil]
        #
        $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE = nil, nil, nil
        @app.__send__(:do_set_global_switch, :quiet, true)
        ok {[$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE]} == [nil, true, nil]
        #
        $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE = nil, nil, nil
        @app.__send__(:do_set_global_switch, :debug, true)
        ok {[$VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE]} == [nil, nil, true]
      ensure
        $VERBOSE_MODE, $QUIET_MODE, $DEBUG_MODE = bkup
      end
    end

  end


  describe '#do_callback()' do

    def new_app(&block)
      @config = Benry::CmdApp::Config.new("test app", "1.0.0")
      return Benry::CmdApp::Application.new(@config, &block)
    end

    it "[!xwo0v] calls callback if provided." do
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

    it "[!lljs1] calls callback only once." do
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


  describe '#do_find_action()' do

    it "[!bm8np] returns action metadata." do
      x = @app.__send__(:do_find_action, ["sayhello"])
      ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
      ok {x.name} == "sayhello"
    end

    it "[!vl0zr] error when action not found." do
      pr = proc { @app.__send__(:do_find_action, ["hiyo"]) }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "hiyo: unknown action.")
    end

    it "[!gucj7] if no action specified, finds default action instead." do
      @app.config.default_action = "sayhello"
      x = @app.__send__(:do_find_action, [])
      ok {x}.is_a?(Benry::CmdApp::ActionMetadata)
      ok {x.name} == "sayhello"
    end

    it "[!388rs] error when default action not found." do
      @app.config.default_action = "hiyo"
      pr = proc { @app.__send__(:do_find_action, []) }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "hiyo: unknown default action.")
    end

    it "[!drmls] returns nil if no action specified but 'config.default_help' is set." do
      @app.config.default_action = nil
      @app.config.default_help = true
      x = @app.__send__(:do_find_action, [])
      ok {x} == nil
    end

    it "[!hs589] error when action nor default action not specified." do
      @app.config.default_action = nil
      @app.config.default_help = false
      pr = proc { @app.__send__(:do_find_action, []) }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "testapp: action name required (run `testapp -h` for details).")
    end

  end


  describe '#do_run_action()' do

    it "[!62gv9] parses action options even if specified after args." do
      sout, serr = capture_io { @app.run("sayhello", "Alice", "-l", "it") }
      ok {serr} == ""
      ok {sout} == "Ciao, Alice!\n"
    end

    it "[!6mlol] reports error if action requries argument but nothing specified." do
      pr = proc { @app.run("test-arity1") }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "test-arity1: argument required.")
    end

    it "[!72jla] reports error if action requires N args but specified less than N args." do
      pr = proc { @app.run("test-arity1", "foo") }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "test-arity1: too less arguments (at least 2).")
    end

    it "[!zawxe] reports error if action requires N args but specified over than N args." do
      pr = proc { @app.run("test-arity1", "foo", "bar", "baz", "boo") }
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "test-arity1: too much arguments (at most 3).")
    end

    it "[!y97o3] action can take any much args if action has variable arg." do
      pr = proc {
        capture_io { @app.run("test-arity2", "foo", "bar", "baz", "boo") }
      }
      ok {pr}.NOT.raise?(Exception)
    end

    it "[!cf45e] runs action with arguments and options." do
      sout, serr = capture_io { @app.run("sayhello", "-l", "it", "Bob") }
      ok {serr} == ""
      ok {sout} == "Ciao, Bob!\n"
    end

    it "[!tsal4] detects looped action." do
      pr = proc { @app.run("test-loop1") }
      ok {pr}.raise?(Benry::CmdApp::LoopedActionError,
                     "test-loop1: looped action detected.")
    end

  end


  describe '#do_print_help_message()' do

    it "[!eabis] prints help message of action if action name provided." do
      sout, serr = capture_io { @app.run("-h", "sayhello") }
      ok {serr} == ""
      ok {sout} == <<'END'
testapp sayhello -- print greeting message

Usage:
  $ testapp sayhello [<options>] [<user>]

Options:
  -l, --lang=<en|fr|it> : language
END
    end

    it "[!cgxkb] error if action for help option not found." do
      ["-h", "--help"].each do |opt|
        pr = proc { @app.run(opt, "xhello") }
        ok {pr}.raise?(Benry::CmdApp::CommandError,
                       "xhello: action not found.")
      end
    end

    it "[!nv0x3] prints help message of command if action name not provided." do
      sout, serr = capture_io { @app.run("-h") }
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

    it "[!4qs7y] shows private (hidden) actions/options if '--all' option specified." do
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

    it "[!l4d6n] `all` flag should be true or false, not nil." do
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

    it "[!efaws] prints colorized help message when stdout is a tty." do
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

    it "[!9vdy1] prints non-colorized help message when stdout is not a tty." do
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

    it "[!gsdcu] prints colorized help message when '--color[=on]' specified." do
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

    it "[!be8y2] prints non-colorized help message when '--color=off' specified." do
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


  describe '#do_validate_actions()' do

    it "[!6xhvt] reports warning at end of help message." do
      class ValidateActionTest1 < Benry::CmdApp::Action
        prefix "validate1", alias_of: :test
        @action.("test")
        def test1(); end
      end
      @app.config.default_help = true
      begin
        [["-h"], []].each do |args|
          sout, serr = capture_io { @app.run(*args) }
          ok {serr} == <<'END'

** [warning] in 'ValidateActionTest1' class, `alias_of: :test` specified but corresponding action not exist.
END
        end
      ensure
        ValidateActionTest1.class_eval { @__aliasof__ = nil }
      end
    end

    it "[!iy241] reports warning if `alias_of:` specified in action class but corresponding action not exist." do
      class ValidateActionTest2 < Benry::CmdApp::Action
        prefix "validate2", alias_of: :test2
        @action.("test")
        def test(); end
      end
      begin
        sout, serr = capture_io { @app.__send__(:do_validate_actions) }
        ok {serr} == <<'END'

** [warning] in 'ValidateActionTest2' class, `alias_of: :test2` specified but corresponding action not exist.
END
      ensure
        ValidateActionTest2.class_eval { @__aliasof__ = nil }
      end
    end

    it "[!h7lon] reports warning if `default:` specified in action class but corresponding action not exist." do
      class ValidateActionTest3 < Benry::CmdApp::Action
        prefix "validate3", default: :test3
        @action.("test")
        def test(); end
      end
      begin
        sout, serr = capture_io { @app.__send__(:do_validate_actions) }
        ok {serr} == <<'END'

** [warning] in 'ValidateActionTest3' class, `default: :test3` specified but corresponding action not exist.
END
      ensure
        ValidateActionTest3.class_eval { @__default__ = nil }
      end
    end

  end


  describe '#do_print_candidates()' do

    it "[!0e8vt] prints candidate action names including prefix name without tailing ':'." do
      class CandidateTest2 < Benry::CmdApp::Action
        prefix "candi:date2", default: :eee
        @action.("test1")
        def ddd(); end
        @action.("test2")
        def ccc(); end
        @action.("test3")
        def eee(); end
      end
      sout, serr = capture_io do
        @app.__send__(:do_print_candidates, ["candi:date2:"])
      end
      ok {serr} == ""
      ok {sout} == <<"END"
Actions:
  candi:date2        : test3
  candi:date2:ccc    : test2
  candi:date2:ddd    : test1
END
    end

    it "[!85i5m] candidate actions should include alias names." do
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
      sout, serr = capture_io do
        @app.__send__(:do_print_candidates, ["candi:date3:"])
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

    it "[!i2azi] raises error when no candidate actions found." do
      pr = proc do
        @app.__send__(:do_print_candidates, ["candi:date9:"])
      end
      ok {pr}.raise?(Benry::CmdApp::CommandError,
                     "No actions starting with 'candi:date9:'.")
    end

  end


  describe '#do_setup()' do

    it "[!pkio4] sets config object to '$cmdapp_config'." do
      $cmdapp_config = nil
      @app.__send__(:do_setup,)
      ok {$cmdapp_config} != nil
      ok {$cmdapp_config} == @app.config
    end

  end


  describe '#do_teardown()' do

    it "[!zxeo7] clears '$cmdapp_config'." do
      $cmdapp_config = "AAA"
      @app.__send__(:do_teardown, nil)
      ok {$cmdapp_config} == nil
    end

  end


end


describe Benry::CmdApp::CommandHelpMessageBuilder do
  include CommonTestingHelper

  before do
    @config = Benry::CmdApp::Config.new("test app", "1.0.0").tap do |config|
      config.app_name     = "TestApp"
      config.app_command  = "testapp"
      config.option_all   = true
      config.option_debug = true
    end
    @schema = Benry::CmdApp::GlobalOptionSchema.create(@config)
    @builder = Benry::CmdApp::CommandHelpMessageBuilder.new(@config, @schema)
  end

  describe '#build_help_message()' do

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
      @_bkup_actions = Benry::CmdApp::Index::ACTIONS.dup()
      Benry::CmdApp::Index::ACTIONS.delete_if {|_, x| x.klass != HelpMessageTest }
      anames = Benry::CmdApp::Index::ACTIONS.keys()
      @_bkup_aliases = Benry::CmdApp::Index::ALIASES.dup()
      Benry::CmdApp::Index::ALIASES.delete_if {|_, a| ! anames.include?(a) }
    end

    after do
      Benry::CmdApp::Index::ACTIONS.update(@_bkup_actions)
      Benry::CmdApp::Index::ALIASES.update(@_bkup_aliases)
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

    it "[!rvpdb] returns help message." do
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

    it "[!34y8e] includes application name specified by config." do
      @config.app_name = "MyGreatApp"
      msg = @builder.build_help_message()
      msg = uncolorize(msg)
      ok {msg} =~ /^MyGreatApp \(1\.0\.0\) -- test app$/
    end

    it "[!744lx] includes application description specified by config." do
      @config.app_desc = "my great app"
      msg = @builder.build_help_message()
      msg = uncolorize(msg)
      ok {msg} =~ /^TestApp \(1\.0\.0\) -- my great app$/
    end

    it "[!d1xz4] includes version number if specified by config." do
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

    it "[!775jb] includes detail text if specified by config." do
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

    it "[!t3tbi] adds '\n' before detail text only when app desc specified." do
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

    it "[!rvhzd] no preamble when neigher app desc nor detail specified." do
      @config.app_desc   = nil
      @config.app_detail = nil
      msg = @builder.build_help_message()
      msg = uncolorize(msg)
      ok {msg}.start_with?(<<END)
Usage:
  $ testapp [<options>] [<action> [<arguments>...]]

END
    end

    it "[!o176w] includes command name specified by config." do
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

    it "[!proa4] includes description of global options." do
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

    it "[!in3kf] ignores private (hidden) options." do
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

    it "[!ywarr] not ignore private (hidden) options if 'all' flag is true." do
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

    it "[!bm71g] ignores 'Options:' section if no options exist." do
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

    it "[!jat15] includes action names ordered by name." do
      msg = @builder.build_help_message()
      msg = uncolorize(msg)
      ok {msg}.end_with?(<<'END')
Actions:
  ya:ya              : greeting #2
  yes                : alias of 'yo-yo' action
  yo-yo              : greeting #1
END
    end

    it "[!df13s] includes default action name if specified by config." do
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

    it "[!b3l3m] not show private (hidden) action names in default." do
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

    it "[!yigf3] shows private (hidden) action names if 'all' flag is true." do
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

    it "[!i04hh] includes postamble text if specified by config." do
      @config.app_postamble = "Home:\n  https://example.com/\n"
      msg = @builder.build_help_message()
      ok {msg}.end_with?(<<"END")
Home:
  https://example.com/
END
    end

    it "[!ckagw] adds '\n' at end of preamble text if it doesn't end with '\n'." do
      @config.app_postamble = "END"
      msg = @builder.build_help_message()
      ok {msg}.end_with?("\nEND\n")
    end

  end


end
