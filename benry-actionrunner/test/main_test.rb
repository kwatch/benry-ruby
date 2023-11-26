# -*- coding: utf-8 -*-

$0 = "arun"

require 'oktest'

require 'benry/actionrunner'


Oktest.scope do

  HELP_MESSAGE_FULL = <<"END"
\e[1marun\e[0m \e[2m(0.0.0)\e[0m --- Action runner (or task runner), much better than Rake

\e[1;34mUsage:\e[0m
  $ \e[1marun\e[0m [<options>] <action> [<arguments>...]

\e[1;34mOptions:\e[0m
  -h, --help         : print help message (of action if specified)
  -V                 : print version
  -l                 : list actions
  -L <topic>         : topic list (actions|aliases|prefixes|abbrevs)
  -a                 : list all actions/options including hidden ones
  -f <file>          : actionfile name (default: 'Actionfile.rb')
  -u                 : search for actionfile in parent or upper dir
  -p                 : change current dir to where action file exists
\e[2m  -s                 : same as '-up'\e[0m
  -g                 : generate actionfile ('Actionfile.rb') with example code
  -v                 : verbose mode
  -q                 : quiet mode
  -c                 : enable color mode
  -C                 : disable color mode
  -D                 : debug mode
  -T                 : trace mode
  -X                 : dry-run mode (not run; just echoback)
  --<name>=<value>   : set a global variable (value can be in JSON format)

\e[1;34mActions:\e[0m
  build              : create all
\e[2m  build:prepare      : prepare directory\e[0m
  build:zip          : create zip file
  clean              : delete garbage files (and product files too if '-a')
  git:stage          : put changes of files into staging area
\e[2m                       (alias: stage)\e[0m
  git:staged         : show changes in staging area
\e[2m                       (alias: staged)\e[0m
  git:status         : show status in compact format
  git:status:here    : show status of current directory
\e[2m                       (alias: git)\e[0m
  git:unstage        : remove changes from staging area
\e[2m                       (alias: unstage)\e[0m
  hello              : print greeting message
  help               : print help message (of action if specified)

\e[1;34mExample:\e[0m
  $ arun -h | less		# print help message
  $ arun -g			# generate action file ('Actionfile.rb')
  $ less Actionfile.rb		# confirm action file
  $ arun			# list actions (or: `arun -l`)
  $ arun -h hello		# show help message for 'hello' action
  $ arun hello Alice		# run 'hello' action with arguments
  Hello, Alice!
  $ arun hello Alice -l fr	# run 'hello' action with args and options
  Bonjour, Alice!
  $ arun :			# list prefixes of actions (or '::', ':::')
  $ arun xxxx:			# list actions starting with 'xxxx:'

\e[1;34mDocument:\e[0m
  https://kwatch.github.io/benry-ruby/benry-actionrunner.html
END
  HELP_MESSAGE      = HELP_MESSAGE_FULL.gsub(/^\e\[2m  \S.*\e\[0m\n/, '')

  HELP_NOFILE_FULL  = HELP_MESSAGE_FULL\
                        .split(/^\e\[1;34mActions:\e\[0m\n.*?\n\n/m)\
                        .join("\e[1;34mActions:\e[0m\n"\
                              "  help               : print help message (of action if specified)\n"\
                              "\n")
  HELP_NOFILE       = HELP_NOFILE_FULL.gsub(/^\e\[2m  \S.*\e\[0m\n/, '')

  alias_list        = <<"END"

\e[1;34mAliases:\e[0m
  stage              : alias for 'git:stage'
  staged             : alias for 'git:staged'
  git                : alias for 'git:status:here'
  unstage            : alias for 'git:unstage'
END

  ACTION_LIST_FULL  = (HELP_MESSAGE_FULL =~ /^(\e\[1;34mActions:\e\[0m\n.*?\n)\n/m) && ($1 + alias_list)
  ACTION_LIST       = ACTION_LIST_FULL.gsub(/^\e\[2m  \S.*\e\[0m\n/, '')

  ACTION_LIST_WITH_PREFIX = <<"END"
\e[1;34mActions:\e[0m
  git:stage          : put changes of files into staging area
\e[2m                       (alias: stage)\e[0m
  git:staged         : show changes in staging area
\e[2m                       (alias: staged)\e[0m
  git:status         : show status in compact format
  git:status:here    : show status of current directory
\e[2m                       (alias: git)\e[0m
  git:unstage        : remove changes from staging area
\e[2m                       (alias: unstage)\e[0m

\e[1;34mAliases:\e[0m
  stage              : alias for 'git:stage'
  staged             : alias for 'git:staged'
  git                : alias for 'git:status:here'
  unstage            : alias for 'git:unstage'
END

  HELP_OF_HELP_ACTION = <<"END"
\e[1marun help\e[0m --- print help message (of action if specified)

\e[1;34mUsage:\e[0m
  $ \e[1marun help\e[0m [<options>] [<action>]

\e[1;34mOptions:\e[0m
  -a, --all          : show all options, including private ones
END

  HELP_OF_HELLO_ACTION = <<"END"
\e[1marun hello\e[0m --- print greeting message

\e[1;34mUsage:\e[0m
  $ \e[1marun hello\e[0m [<options>] [<name>]

\e[1;34mOptions:\e[0m
  -l, --lang=<lang>  : language (en/fr/it)
END


  topic Benry::ActionRunner do

    fixture :fname do
      Benry::ActionRunner::DEFAULT_FILENAME
    end

    fixture :actionfile do |fname|
      if ! File.exist?(fname)
        main("-g")
        #capture_sio { main("-g") }
        #at_exit { File.unlink(fname) if File.exist?(fname) }
      end
      fname
    end

    fixture :noactionfile do |fname|
      File.unlink(fname) if File.exist?(fname)
      nil
    end


    topic('.main()') {

      def main(*args)
        sout, serr = capture_sio(tty: true) do
          Benry::ActionRunner.main(args)
        end
        ok {serr} == ""
        return sout
      end

      def main!(*args)
        sout, serr = capture_sio(tty: true) do
          Benry::ActionRunner.main(args)
        end
        ok {sout} == ""
        return serr
      end

      case_when "when action file not exist..." do

        before do
          @fname = Benry::ActionRunner::DEFAULT_FILENAME
          File.unlink(@fname) if File.exist?(@fname)
        end

        spec "option '-h' or '--help' prints help message without actions." do
          ok {main("-h")}     == HELP_NOFILE
          ok {main("--help")} == HELP_NOFILE
        end

        spec "option '-h' and '--help' can take an action name." do
          ok {main("-h", "help")}     == HELP_OF_HELP_ACTION
          ok {main("--help", "help")} == HELP_OF_HELP_ACTION
        end

        spec "option '-v' prints version number." do
          ok {main("-V")} == Benry::ActionRunner::VERSION + "\n"
        end

        spec "option '-l' cannot list action names." do
          ok {main!("-l")} == "\e[31m[ERROR]\e[0m Action file ('#{@fname}') not found. Create it by `arun -g` command firstly.\n"
        end

        spec "option '-g' generates action file." do
          ok {@fname}.not_exist?
          ok {main("-g")} == "[OK] Action file '#{@fname}' generated.\n"
          ok {@fname}.file_exist?
        end

        spec "action 'help' can be run." do
          ok {main("help")} == HELP_NOFILE
          ok {main("help", "-a")} == HELP_NOFILE_FULL
          ok {main("help", "help")} == HELP_OF_HELP_ACTION
        end

        spec "no arguments specified reports error message." do
          ok {main!()} == "\e[31m[ERROR]\e[0m Action file ('#{@fname}') not found. Create it by `arun -g` command firstly.\n"
        end

        spec "option '-a' without any arguments reports error message." do
          ok {main!("-a")} == "\e[31m[ERROR]\e[0m Action file ('#{@fname}') not found. Create it by `arun -g` command firstly.\n"
        end

        spec "prefix name specified reports error message." do
          ok {main!("git:")} == "\e[31m[ERROR]\e[0m Action file ('#{@fname}') not found. Create it by `arun -g` command firstly.\n"
        end

      end

      case_else "else..." do

        before do
          @fname = Benry::ActionRunner::DEFAULT_FILENAME
          unless File.exist?(@fname)
            #capture_sio { Benry::ActionRunner.main("-g") }
            config = Benry::ActionRunner::CONFIG
            app = Benry::ActionRunner::MainApplication.new(config)
            app.__send__(:generate_action_file, quiet: true)
          end
        end

        spec "option '-h' or '--help' prints help message." do
          ok {main("-h")}     == HELP_MESSAGE
          ok {main("--help")} == HELP_MESSAGE
        end

        spec "option '-h' an '--help' can take an action name." do
          ok {main("-h", "hello")} == HELP_OF_HELLO_ACTION
          ok {main("--help", "hello")} == HELP_OF_HELLO_ACTION
        end

        spec "option '-V' prints version." do
          ok {main("-V")} == Benry::ActionRunner::VERSION + "\n"
        end

        spec "option '-l' lists action names." do
          ok {main("-l")} == ACTION_LIST
        end

        spec "option '-a' includes hidden actions into help message." do
          ok {main("-ha")} == HELP_MESSAGE_FULL
          ok {main("-la")} == ACTION_LIST_FULL
        end

        spec "option '-g' reports error message." do
          ok {main!("-g")} == "\e[31m[ERROR]\e[0m Action file ('#{@fname}') already exists. If you want to generate a new one, delete it first.\n"
        end

        spec "no arguments specified lists action names." do
          ok {main()} == ACTION_LIST
        end

        spec "option '-a' without any arguments lists action including hidden ones." do
          ok {main("-a")} == ACTION_LIST_FULL
        end

        spec "run action with options and args." do
          ok {main("hello", "-lfr", "Alice")} == "Bonjour, Alice!\n"
        end

        spec "prefix name lists action names starting with prefix." do
          ok {main("git:")} == ACTION_LIST_WITH_PREFIX
        end

        spec "long options are recognized as global variable values." do
          BuildAction.class_eval do
            @action.("show global variables")
            def gvars1()
              puts "$project=#{$project.inspect}, $release=#{$release.inspect}"
            end
          end
          at_end { Benry::CmdApp.undef_action("build:gvars1") }
          expected = "$project=\"mysample1\", $release=\"3.0.0\"\n"
          ok {main("--project=mysample1", "--release=3.0.0", "build:gvars1")} == expected
        end

        spec "long option value is parsed as JSON string." do
          BuildAction.class_eval do
            @action.("show global variables")
            def gvars2()
              puts "$num=#{$num.inspect}, $str=#{$str.inspect}, $arr=#{$arr.inspect}"
            end
          end
          at_end { Benry::CmdApp.undef_action("build:gvars2") }
          expected = "$num=123, $str=\"foo\", $arr=[123, true, nil]\n"
          ok {main("--num=123", "--str=foo", "--arr=[123,true,null]", "build:gvars2")} == expected
        end

        spec "long options are displayed in debug mode." do
          sout = main("-lD", "--num=123", "--str=foo", "--arr=[123,true,null]")
          ok {sout}.start_with?(<<"END")
\e[2m[DEBUG] $num = 123\e[0m
\e[2m[DEBUG] $str = \"foo\"\e[0m
END
        end

      end

    }


  end


end
