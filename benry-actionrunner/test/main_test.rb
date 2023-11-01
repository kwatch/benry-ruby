# -*- coding: utf-8 -*-

$0 = "arun"

require 'oktest'

require 'benry/actionrunner'


Oktest.scope do

  HELP_MESSAGE_FULL = <<"END"
\e[1marun\e[0m (0.0.0) --- Action runner (or task runner), much better than Rake

\e[1;34mUsage:\e[0m
  $ \e[1marun\e[0m [<options>] <action> [<arguments>...]

\e[1;34mOptions:\e[0m
  -h, --help         : print help message (of action if specified)
  -V, --version      : print version
  -l, --list         : list actions
  -a, --all          : list hidden actions/options, too
  -f, --file=<file>  : actionfile name (default: 'Actionfile.rb')
  -s, --search       : search for actionfile in parent or upper dir
  -d, --chdir        : change current dir to where actionfile exists
\e[2m  -u, --searchdir    : same as '-sd'\e[0m
  -g, --generate     : generate actionfile ('Actionfile.rb') with example code
  -v, --verbose      : verbose mode
  -q, --quiet        : quiet mode
  --color[=<on|off>] : color mode
      --debug        : debug mode
  -T, --trace        : trace mode

\e[1;34mActions:\e[0m
  build              : create all
\e[2m  build:prepare      : prepare directory\e[0m
  build:zip          : create zip file
  clean              : delete garbage files (and product files too if '-a')
  git                : alias of 'git:status:here'
  git:stage          : put changes of files into staging area
  git:staged         : show changes in staging area
  git:status         : show status in compact format
  git:status:here    : show status of current directory
  git:unstage        : remove changes from staging area
  hello              : print greeting message
  help               : print help message (of action if specified)
  stage              : alias of 'git:stage'
  staged             : alias of 'git:staged'
  unstage            : alias of 'git:unstage'

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
  $ arun xxxx:			# list actions starting with 'xxxx:'
  $ arun :			# list prefixes of actions (or '::')

\e[1;34mDocument:\e[0m
  https://kwatch.github.io/benry-ruby/benry-actionrunner.html
END
  HELP_MESSAGE      = HELP_MESSAGE_FULL.gsub(/^\e\[2m.*\e\[0m\n/, '')

  HELP_NOFILE_FULL  = HELP_MESSAGE_FULL\
                        .split(/^\e\[1;34mActions:\e\[0m\n.*?\n\n/m)\
                        .join("\e[1;34mActions:\e[0m\n"\
                              "  help               : print help message (of action if specified)\n"\
                              "\n")
  HELP_NOFILE       = HELP_NOFILE_FULL.gsub(/^\e\[2m.*\e\[0m\n/, '')

  ACTION_LIST_FULL  = (HELP_MESSAGE_FULL =~ /^(\e\[1;34mActions:\e\[0m\n.*?\n)\n/m) && $1
  ACTION_LIST       = ACTION_LIST_FULL.gsub(/^\e\[2m.*\e\[0m\n/, '')

  ACTION_LIST_WITH_PREFIX = <<"END"
\e[1;34mActions:\e[0m
  git:stage          : put changes of files into staging area
  git:staged         : show changes in staging area
  git:status         : show status in compact format
  git:status:here    : show status of current directory
  git:unstage        : remove changes from staging area

\e[1;34mAliases:\e[0m
  git                : alias of 'git:status:here'
  stage              : alias of 'git:stage'
  staged             : alias of 'git:staged'
  unstage            : alias of 'git:unstage'
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
      Benry::ActionRunner::ACTIONRUNNER_FILENAME
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


    topic '.main()' do

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
          @fname = Benry::ActionRunner::ACTIONRUNNER_FILENAME
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
          ok {main("-V")} == Benry::ActionRunner::ACTIONRUNNER_VERSION + "\n"
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
          @fname = Benry::ActionRunner::ACTIONRUNNER_FILENAME
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
          ok {main("-V")} == Benry::ActionRunner::ACTIONRUNNER_VERSION + "\n"
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

      end

    end


  end


end
