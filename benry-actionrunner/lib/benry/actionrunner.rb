# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2023 kwatch@gmail.com $
### $License: MIT License $
###


require 'benry/cmdapp'
require 'benry/unixcommand'


#$DRYRUN_MODE = false


module Benry::ActionRunner


  VERSION          = "$Release: 0.0.0 $".split()[1]
  DOCUMENT_URL     = "https://kwatch.github.io/benry-ruby/benry-actionrunner.html"
  DEFAULT_FILENAME = "Actionfile.rb"


  class Action < Benry::CmdApp::Action
    include Benry::UnixCommand

    #def prompt()
    #  return "[#{CONFIG.app_command}]$ "
    #end

  end


  app_desc = "Action runner (or task runner), much better than Rake"
  CONFIG = Benry::CmdApp::Config.new(app_desc, VERSION).tap do |config|
    action_file = DEFAULT_FILENAME
    command = File.basename($0)
    config.app_command = command
    #config.app_detail = nil
    x = command
    example = <<END
  $ #{x} -h | less		# print help message
  $ #{x} -g			# generate action file ('#{action_file}')
  $ less #{action_file}		# confirm action file
  $ #{x}			# list actions (or: `#{x} -l`)
  $ #{x} -h hello		# show help message for 'hello' action
  $ #{x} hello Alice		# run 'hello' action with arguments
  Hello, Alice!
  $ #{x} hello Alice -l fr	# run 'hello' action with args and options
  Bonjour, Alice!
  $ #{x} :			# list prefixes of actions (or '::', ':::')
  $ #{x} xxxx:			# list actions starting with 'xxxx:'
END
    config.help_postamble = {
      "Example:"  => example,
      "Document:" => "  #{DOCUMENT_URL}\n",
    }
  end


  GLOBAL_OPTION_SCHEMA = Benry::CmdApp::GLOBAL_OPTION_SCHEMA_CLASS.new(nil).tap do |schema|
    topics = ["action", "actions", "alias", "aliases",
              "category", "categories", "abbrev", "abbrevs",
              "category1", "categories1", "category2", "categories2",
              "category3", "categories3", "category4", "categories4",
              "metadata"]
    schema.add(:help     , "-h, --help", "print help message (of action if specified)")
    schema.add(:version  , "-V"        , "print version")
    schema.add(:list     , "-l"        , "list actions")
    schema.add(:topic    , "-L <topic>", "topic list (actions|aliases|prefixes|abbrevs)", enum: topics)
    schema.add(:all      , "-a"        , "list all actions/options including hidden ones")
    schema.add(:file     , "-f <file>" , "actionfile name (default: '#{DEFAULT_FILENAME}')")
    schema.add(:search   , "-u"        , "search for actionfile in parent or upper dir")
    schema.add(:chdir    , "-w"        , "change current dir to where action file exists")
    schema.add(:searchdir, "-s"        , "same as '-up'", hidden: true)
    schema.add(:generate , "-g"        , "generate actionfile ('#{DEFAULT_FILENAME}') with example code")
    schema.add(:verbose  , "-v"        , "verbose mode")
    schema.add(:quiet    , "-q"        , "quiet mode")
    schema.add(:color    , "-c"        , "enable color mode")
    schema.add(:nocolor  , "-C"        , "disable color mode")
    schema.add(:debug    , "-D"        , "debug mode")
    schema.add(:trace    , "-T"        , "trace mode")
    schema.add(:dryrun   , "-X"        , "dry-run mode (not run; just echoback)")
  end


  module ApplicationHelpBuilderModule
    def section_options(*args, **kwargs)
      #; [!xsfzi] adds '--<name>=<value>' to help message.
      arr = ["--<name>=<value>", "set a global variable (value can be in JSON format)"]
      s = super
      s += (@config.format_option % arr) + "\n"
      return s
    end
  end
  Benry::CmdApp::APPLICATION_HELP_BUILDER_CLASS.prepend(ApplicationHelpBuilderModule)


  class GlobalOptionParser < Benry::CmdApp::GLOBAL_OPTION_PARSER_CLASS

    def initialize(schema, &callback)
      super
      @callback = callback
    end

    def handle_unknown_long_option(optstr, name, value)
      return super if value == nil
      return super if @callback == nil
      @callback.call(name, value, optstr)
    end

  end


  def self.main(argv=ARGV)
    #; [!wmcup] handles '$ACRIONRUNNER_OPTION' value.
    envstr = ENV["ACTIONRUNNER_OPTION"]
    if envstr && ! envstr.empty?
      argv = envstr.split() + argv
    end
    app = MainApplication.new(CONFIG, GLOBAL_OPTION_SCHEMA)
    status_code = app.main(argv)
    #; [!hujvl] returns status code.
    return status_code
  end


  class MainApplication < Benry::CmdApp::Application

    def initialize(*args, **kwargs)
      super
      @flag_search = false                 # true when '-s' option specified
      @flag_chdir  = false                 # true when '-w' option specified
      @action_file = DEFAULT_FILENAME      # ex: 'Actionfile.rb'
      @global_vars = {}                    # names and values of global vars
      @_loaded     = false                 # true when action file loaded
    end

    protected

    def parse_global_options(args)
      #; [!bpedh] parses `--<name>=<val>` as global variables.
      @global_vars = {}
      parser = GlobalOptionParser.new(@option_schema) do |name, value, _optstr|
        @global_vars[name] = value
      end
      #; [!0tz4j] stops parsing options when any argument found.
      global_opts = parser.parse(args, all: false)  # raises OptionError
      #; [!gkp9b] returns global options.
      return global_opts
    end

    def toggle_global_options(global_opts)  # override
      #; [!3kdds] global option '-C' sets `$COLOR_mode = false`.
      global_opts[:color] = false if global_opts[:nocolor]
      super
      d = global_opts
      #; [!1882x] global option '-u' sets instance var.
      #; [!bokge] global option '-w' sets instance var.
      @flag_search = true if d[:search] || d[:searchdir]
      @flag_chdir  = true if d[:chdir]  || d[:searchdir]
      #; [!4sk24] global option '-f' changes filename.
      @action_file = d[:file] if d[:file]
      #; [!9u400] sets `$BENRY_ECHOBACK = true` if option `-v` specified.
      #; [!jp2mw] sets `$BENRY_ECHOBACK = false` if option `-q` specified.
      $BENRY_ECHOBACK = true  if d[:verbose]
      $BENRY_ECHOBACK = false if d[:quiet]
      nil
    end

    def handle_global_options(global_opts, args)  # override
      #; [!psrmp] loads action file (if exists) before displaying help message.
      if global_opts[:help]
        load_action_file(required: false)
        return super
      end
      #; [!9wfaw] loads action file before listing actions by '-l' or '-L' option.
      #; [!qanx2] option '-l' and '-L' requires action file.
      if global_opts[:list] || global_opts[:topic]
        load_action_file(required: true)
        return super
      end
      #; [!7995e] option '-g' generates action file.
      if global_opts[:generate]
        generate_action_file()
        return 0
      end
      #; [!k5nuk] option '-h' or '--help' prints help message.
      #; [!dmxt2] option '-V' prints version number.
      #; [!i4qm5] option '-v' sets `$VERBOSE_MODE = true`.
      #; [!5nwnv] option '-q' sets `$QUIET_MODE = true`.
      #; [!klxkr] option '-c' sets `$COLOR_MODE = true`.
      #; [!kqbwd] option '-C' sets `$COLOR_MODE = false`.
      #; [!oce46] option '-D' sets `$DEBUG_MODE = true`.
      #; [!mq5ko] option '-T' enables trace mode.
      #; [!jwah3] option '-X' sets `$DRYRUN_MODE = true`.
      return super
    end

    def handle_action(args, global_opts)
      #; [!qdrui] loads action file before performing actions.
      #; [!4992c] raises error if action specified but action file not exist.
      load_action_file(required: (args[0] != "help"))
      return super
    end

    def skip_backtrace?(bt)  # override
      #; [!k8ddu] ignores backtrace of 'actionrunner.rb'.
      #; [!89mz3] ignores backtrace of 'kernel_require.rb'.
      #; [!ttt98] ignores backtrace of 'arun'.
      return true if bt.include?(__FILE__)
      return true if bt.include?('/core_ext/kernel_require.rb')
      return true if bt.include?('/arun:')
      #; [!z72yj] not ignore backtrace of others.
      return false
    end

    private

    def load_action_file(required: true)
      #; [!nx22j] returns false if action file already loaded.
      return false if @_loaded
      #; [!aov55] loads action file if exists.
      filename = @action_file  or raise "** internal error"
      brownie  = Brownie.new(@config)
      filepath = brownie.search_and_load_action_file(filename, @flag_search, @flag_chdir)
      #; [!ssmww] raises error when `required: true` and action file not exist.
      filepath != nil || ! required  or
        raise Benry::CmdApp::CommandError,
              "Action file ('#{filename}') not found." \
              " Create it by `#{@config.app_command} -g` command firstly."
      #; [!vwtwe] it is AFTER loading action file to set global variables.
      brownie.populate_global_variables(@global_vars)
      @global_vars.clear()
      #; [!8i55a] prevents to load action file more than once.
      @_loaded = true
      #; [!f68yv] returns true if action file loaded successfully.
      return true
    end

    def generate_action_file(quiet: $QUIET_MODE)
      #; [!dta7r] generates action file.
      filename = @action_file  or raise "** internal error"
      brownie  = Brownie.new(@config)
      content  = brownie.render_action_file_content(filename)
      #; [!tmlqt] prints action file content if filename is '-'.
      #; [!ymrjh] prints action file content if stdout is not a tty.
      if filename == "-" || ! $stdout.tty?
        print content
        #; [!9e3c0] returns nil if action file is not generated.
        return nil
      end
      #; [!685cq] raises error if action file already exist.
      ! File.exist?(filename)  or
        raise Benry::CmdApp::CommandError,
              "Action file ('#{filename}') already exists." \
              " If you want to generate a new one, delete it first."
      File.write(filename, content, encoding: 'utf-8')
      #; [!n09pl] reports result if action file generated successfully.
      #; [!iq0p2] reports nothing if option '-q' specified.
      puts "[OK] Action file '#{filename}' generated." unless quiet
      #; [!bf60l] returns action file name if generated.
      return filename
    end

  end


  class Brownie

    def initialize(config)
      @config = config
    end

    def search_and_load_action_file(filename, flag_search, flag_chdir, _pwd: Dir.pwd())
      #; [!c9e1h] if action file exists in current dir, load it regardless of options.
      #; [!m5oj7] if action file exists in parent dir, find and load it if option '-s' specified.
      if File.exist?(filename) ; dir = "."
      elsif flag_search        ; dir = _search_dir_where_file_exist(filename, _pwd)
      else                     ; dir = nil
      end
      #; [!079xs] returns nil if action file not found.
      #; [!7simq] changes current dir to where action file exists if option '-w' specified.
      #; [!dg2qv] action file can has directory path.
      if    dir == nil ; return nil
      elsif dir == "." ; fpath = filename
      elsif flag_chdir ; fpath = filename ; _chdir(dir)
      else             ; fpath = File.join(dir, filename)
      end
      #; [!d987b] loads action file if exists.
      abspath = File.absolute_path(fpath)
      require abspath
      #; [!x9xxl] returns absolute path of action file if exists.
      return abspath
    end

    private

    def _search_dir_where_file_exist(filename, dir=Dir.pwd(), max=20)
      n = -1
      found = while (n += 1) < max
        break true if File.exist?(File.join(dir, filename))
        parent = File.dirname(dir)
        break false if parent == dir
        dir = parent
      end
      return nil unless found
      return "."  if n == 0
      return ".." if n == 1
      return ("../" * n).chomp("/")
    end

    def _chdir(dir)
      Action.new(@config).instance_eval { cd(dir) }
      nil
    end

    public

    def populate_global_variables(global_vars)
      #; [!cr2ph] sets global variables.
      #; [!3kow3] normalizes global variable names.
      #; [!03x7t] decodes JSON string into Ruby object.
      #; [!1ol4a] print global variables if debug mode is on.
      global_vars.each do |name, str|
        var = name.gsub(/[^\w]/, '_')
        val = _decode_value(str)
        eval "$#{var} = #{val.inspect}"
        _debug_global_var(var, val) if $DEBUG_MODE
      end
      nil
    end

    private

    def _decode_value(str)
      #; [!omxyf] decodes string as JSON format.
      require 'json' unless defined?(JSON)
      return JSON.load(str)
    rescue JSON::ParserError
      #; [!tvwvn] returns string as it is if failed to parse as JSON.
      return str
    end

    def _debug_global_var(var, val)
      #; [!05l5f] prints var name and it's value.
      #; [!7lwvz] colorizes output if color mode enabled.
      msg = "[DEBUG] $#{var} = #{val.inspect}"
      msg = @config.deco_debug % msg if Benry::CmdApp::Util.color_mode?
      puts msg
      $stdout.flush()
    end

    public

    def render_action_file_content(filename)
      #; [!oc03q] returns content of action file.
      #content = DATA.read()
      content = File.read(__FILE__, encoding: 'utf-8').split(/\n__END__\n/)[-1]
      content = content.gsub('%COMMAND%', @config.app_command)
      content = content.gsub('%ACTIONFILE%', filename)
      return content
    end

  end


  module Export

    CONFIG = Benry::ActionRunner::CONFIG
    Action = Benry::ActionRunner::Action

    module_function

    def define_alias(alias_name, action_name, tag: nil, important: nil, hidden: nil)
      return Benry::CmdApp.define_alias(alias_name, action_name, tag: tag, important: important, hidden: hidden)
    end

    def undef_alias(alias_name)
      return Benry::CmdApp.undef_alias(alias_name)
    end

    def undef_action(action_name)
      return Benry::CmdApp.undef_action(action_name)
    end

    def define_abbrev(abbrev, prefix)
      return Benry::CmdApp.define_abbrev(abbrev, prefix)
    end

    def undef_abbrev(abbrev)
      return Benry::CmdApp.undef_abbrev(abbrev)
    end

    def current_app()
      return Benry::CmdApp.current_app()
    end

  end


end


if __FILE__ == $0
  exit Benry::ActionRunner.main()
end


__END__
# -*- coding: utf-8 -*-
# frozen_string_literal: true


##
## @(#) Action file for '%COMMAND%' command.
##
## Example:
##
##   $ %COMMAND% -h | less      # print help message
##   $ %COMMAND% -g             # generate action file ('%ACTIONFILE%')
##   $ less %ACTIONFILE%  # confirm action file
##   $ %COMMAND%                # list actions (or: `%COMMAND% -l`)
##
##   $ %COMMAND% -h hello       # show help message for 'hello' action
##   $ %COMMAND% hello Alice    # run 'hello' action with arguments
##   Hello, Alice!
##   $ %COMMAND% hello -l fr    # run 'hello' action with options
##   Bonjour, world!
##
##   $ %COMMAND% :        # list prefixes of actions (or '::', ':::', etc)
##   $ %COMMAND% git:     # list actions filtered by prefix "git:"
##   $ %COMMAND% git      # run 'git' action (or alias)
##


require 'benry/actionrunner'

include Benry::ActionRunner::Export


##
## Define actions
##
class MyAction < Action

  @action.("print greeting message")
  @option.(:lang, "-l, --lang=<lang>", "language (en/fr/it)")
  def hello(name="world", lang: "en")
    case lang
    when "en" ; puts "Hello, #{name}!"
    when "fr" ; puts "Bonjour, #{name}!"
    when "it" ; puts "Chao, #{name}!"
    else
      raise "#{lang}: Unknown language."
    end
  end

  @action.("delete garbage files (and product files too if '-a')")
  @option.(:all, "-a, --all", "delete product files, too")
  def clean(all: false)
    rm :rf, GARBAGE_FILES if ! GARBAGE_FILES.empty?
    rm :rf, PRODUCT_FILES if ! PRODUCT_FILES.empty? && all == true
  end

end

GARBAGE_FILES = ["*~", "*.tmp"]     # will be deleted by `arun clean`
PRODUCT_FILES = ["*.gem"]           # will be deleted by `arun clean --all`


##
## Define action with prefix ('git:')
##
class GitAction < Action
  #prefix "git:"
  #prefix "git:", action: "status:here"    # rename 'git:status:here' action to 'git'
  category "git:", alias_for: "status:here"   # define 'git' as an alias of 'git:status:here' action

  @action.("show status in compact format")
  def status(*files)
    sys "git status -sb #{files.join(' ')}"
  end

  @action.("show status of current directory")
  def status__here()         # method name 'x__y__z' => action name 'x:y:z'
    sys "git status -sb ."
  end

  @action.("put changes of files into staging area")
  @option.(:interactive, "-i", "select changes interactively")
  def stage(file, *files, interactive: false)
    opts = []
    opts << " -i" if interactive
    sys "git add#{opts.join(' ')} #{file.join(' ')}"
  end

  @action.("show changes in staging area")
  def staged()
    sys "git diff --cached"
  end

  @action.("remove changes from staging area")
  def unstage()
    sys "git reset HEAD"
  end

end


##
## Example of aliases
##
define_alias "stage"    , "git:stage"
define_alias "staged"   , "git:staged"
define_alias "unstage"  , "git:unstage"


##
## More example
##
$project = "example"
$release = "1.0.0"

class BuildAction < Action
  category "build:", action: "all"
  #prefix "build:", alias_of: "all"

  def target_name()
    return "#{$project}-#{$release}"
  end

  ## hidden action
  @action.("prepare directory", hidden: true)   # hidden action
  def prepare()
    dir = target_name()
    mkdir dir unless File.directory?(dir)
  end

  @action.("create zip file")
  def zip_()                   # last '_' char avoids to override existing method
    run_once "prepare"         # run prerequisite action only once
    dir = target_name()
    store "README.md", "Rakefile.rb", "lib/**/*", "test/**/*", to: dir
    sys "zip -r #{dir}.zip #{dir}"
    sys "unzip -l #{dir}.zip"
  end

  @action.("create all")
  def all()
    run_once "zip"             # run prerequisite action only once
  end

end
