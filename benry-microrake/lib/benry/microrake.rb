# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2024 kwatch@gmail.com $
### $License: MIT License $
###


require 'fileutils'
require 'json'

require 'benry/cmdopt'


module Benry
end


module Benry::MicroRake


  VERSION   = '$Release: 0.0.0 $'.split()[1]
  APP_NAME  = "MicroRake"
  DEFAULT_TASKFILE = "Taskfile.rb"
  ENV_VAR   = "URAKE_OPTS"


  class InternalError < Exception
    def initialize(msg)
      super "** internal error: #{msg}"
    end
  end

  class BaseError < StandardError
  end

  class TaskDefinitionError < BaseError
  end

  class TaskExecutionError < BaseError
  end

  class CyclicTaskError < BaseError
  end

  class NamespaceError < BaseError
  end

  class CommandLineError < BaseError
  end


  module Util
    module_function

    def convert_value(str)
      return true if str == true || str == nil
      return JSON.parse(str)   # ex: "1" -> 1, "true" -> true
    rescue JSON::ParserError
      return str               # ex: "foo" -> "foo"
    end

    def render_default_taskfile(command)
      content = File.read(__FILE__, encoding: 'utf-8').split(/^__END__\n/, 2).last
      content = content.gsub('%COMMAND%', command)
      return content
    end

    def normalize_task_name(name)
      return name.to_s.gsub(/-/, "_")
    end

    def hyphenize_task_name(name)
      name = name.to_s
      name = name.gsub(/_/, '-')       # ex: "a_b_c" -> "a-b-c"
      name = name.gsub(/(^|:)-/, '_')  # ex: "-a" -> "_", "b:-c" -> "b:_c"
      return name
    end

    def format_argname(name)
      s = name.to_s
      s = s.gsub(/_or_/, '|')          # ex: "yes_or_no"  -> "yes|no"
      s = s.gsub(/__/, '.')            # ex: "file__html" -> "file.html"
      s = s.gsub(/_/, '-')             # ex: "src_file"   -> "src-file"
      s = s.sub(/^-/, '_')             # ex: "-foo-bar"   -> "_foo-bar"
      return s
    end

    def colorize_appname(str)
      return "\e[1m#{str}\e[0m"   # bold
    end

    def colorize_taskname(str)
      return "\e[1m#{str}\e[0m"   # bold
    end

    def colorize_secheader(str)
      ## 30: black, 31: red, 32: green, 33: yellow, 34: blue,
      ## 35: magenta, 36: cyan, 37: white, 90: gray, 2: gray
      #return "\e[1;34m#{str}\e[0m"   # blue; bold
      return "\e[36m#{str}\e[0m"     # cyan
    end

    def colorize_location(str)
      return "\e[2;3m#{str}\e[0m"    # gray, itatlic
    end

    def colorize_important(str)
      return "\e[1m#{str}\e[0m"      # bold
    end

    def colorize_unimportant(str)
      return "\e[2m#{str}\e[0m"      # gray
    end

    def colorize_hidden(str)
      return "\e[2m#{str}\e[0m"      # gray
    end

    def colorize_trace(str)
      return "\e[33m#{str}\e[0m"     # yellow
    end

    def colorize_error(str)
      return "\e[31m#{str}\e[0m"     # red
    end

    def uncolorize(str)
      return str.gsub(/\e\[.*?m/, '')
    end

    def uncolorize_unless_tty(str)
      return $stdout.tty? ? str : uncolorize(str)
    end


    class FilepathShortener

      def initialize()
        here   = Dir.pwd() + "/"
        parent = File.dirname(here) + "/"
        home   = File.expand_path("~") + "/"
        root_abspath, root_relpath = _root_path(here)
        if root_abspath && root_abspath != here
          @dict = {here => "./", parent => "../", root_abspath => root_relpath, home => "~/"}
        else
          @dict = {here => "./", parent => "../", home => "~/"}
        end
      end

      def shorten_filepath(filepath)
        return nil if filepath == nil
        @dict.each do |path, newpath|
          if filepath.start_with?(path)
            return filepath.sub(path, newpath)
          end
        end
        return filepath
      end

      private

      def _root_path(here, taskfile_fullpath=nil)
        taskfile_fullpath ||= $URAKE_TASKFILE_FULLPATH
        return nil unless taskfile_fullpath
        root_abspath = File.dirname(taskfile_fullpath) + "/"
        return nil unless here.start_with?(root_abspath)
        rest = here.sub(root_abspath, "")
        root_relpath = rest.gsub(/[^\/]+/, "..")
        return root_abspath, root_relpath
      end

    end


    class FileLinesCache

      def initialize()
        @lines_cache = {}   # ex: {filepath => [line1, line2, ...]}
      end

      def clear_cache()
        @lines_cache.clear()
      end

      def get_line_of_file_at(filepath, lineno)
        lines = (@lines_cache[filepath] ||= _get_lines_of_file(filepath))
        return lines[lineno - 1]
      end

      private

      def _get_lines_of_file(filepath)
        return File.read(filepath, encoding: 'utf-8').split("\n")
      rescue               # Errno::ENOENT
        return []
      end

    end


  end


  $URAKE_TASKFILE_FULLPATH = nil

  $VERBOSE_MODE      = true     unless defined?($VERBOSE_MODE)
  $QUIET_MODE        = false    unless defined?($QUIET_MODE)
  $DRYRUN_MODE       = false    unless defined?($DRYRUN_MODE)
  $TRACE_MODE        = false    unless defined?($TRACE_MODE)


  module UnixUtils
    include FileUtils

    proc do
      ## list up FileUtils commands verbosable
      verbosable_commands = FileUtils.commands.select {|cmd|
        params = FileUtils.method(cmd).parameters
        params.include?([:key, :verbose]) && params.include?([:key, :noop])
      }
      ## make FileUtils commands verbosed
      sb = verbosable_commands.collect {|cmd|
        "def #{cmd}(*a, **k, &b); super(*a, verbose: $VERBOSE_MODE, noop: $DRYRUN_MODE, **k, &b); end;"
      }
      eval sb.join(), binding(), __FILE__, __LINE__ - 2
    end.call()

    def self.disable_fileutils_commands()   # :nodoc:
      FileUtils.commands.each do |cmd|
        eval <<-END, binding(), __FILE__, __LINE__ + 1
          def #{cmd}(*args, **kwargs, &block)
            raise NotImplementedError.new("#{cmd}(): Cannot invoke this method because FileUtils has been disabled.")
          end
        END
      end
    end

    def prompt()
      raise NotImplementedError.new("#{self.class.name}#prompt(): not implemented yet.")
    end

    def set_prompt()
      @fileutils_label = prompt()
    end

    def cd(dir, verbose: nil, &block)
      verbose = $VERBOSE_MODE if verbose == nil
      if ! block_given?()
        return super dir, verbose: verbose
      else
        backup = (@_urake_chdir_depth ||= 0)
        begin
          return super dir, verbose: verbose do
            @_urake_chdir_depth += 1
            set_prompt()
            yield
          end
        ensure
          @_urake_chdir_depth = backup
          set_prompt()
        end
      end
    end

    alias chdir cd

    def echoback(str, verbose: $VERBOSE_MODE, noop: $DRYRUN_MODE)
      return if noop
      fu_output_message str if verbose
      nil
    end

    def echo(*args, verbose: $VERBOSE_MODE, noop: $DRYRUN_MODE)
      str = args.join(" ")
      fu_output_message "echo #{str}" if verbose
      return if noop
      puts str
      nil
    end

    def echo_n(*args, verbose: $VERBOSE_MODE, noop: $DRYRUN_MODE)
      str = args.join(" ")
      fu_output_message "echo -n #{str}" if verbose
      return if noop
      print str
      nil
    end

    def time(&block)
      start_at = Time.now
      st       = Process.times
      yield
      et       = Process.times
      end_at   = Time.now
      real_t = end_at - start_at
      user_t = (et.utime - st.utime) + (et.cutime - st.cutime)
      sys_t  = (et.stime - st.stime) + (et.cstime - st.cstime)
      $stderr.puts "%12.3f real %12.3f user %12.3f sys" % [real_t, user_t, sys_t]
      nil
    end

    def sh(command, verbose: $VERBOSE_MODE, noop: $DRYRUN_MODE, &callback)
      #print prompt(), command, "\n" if verbose
      fu_output_message command if verbose
      return if noop
      ok = system(command)
      if block_given?()
        return yield ok, $?
      elsif ok
        return ok
      else
        fail "Command failed (status=#{$?.exitstatus}): [#{command}]"
      end
    end

    def sh!(command, verbose: $VERBOSE_MODE, noop: $DRYRUN_MODE, &callback)
      #print prompt(), command, "\n" if verbose
      fu_output_message command if verbose
      return if noop
      ok = system(command)
      if ! ok && block_given?()
        return yield $?   # yield block only when the command failed
      else
        return ok
      end
    end

    def question(message, default: nil, required: false, max: 3)
      answer = nil
      i = 0
      while (i += 1) <= max
        if default == nil
          print message, ": "
        else
          print message, " (default: #{default}): "
        end
        #$stdout.flush()
        answer = $stdin.readline().strip()
        if answer == nil
          raise RuntimeError, "question(): Failed to read answer because I/O closed."
        elsif ! answer.empty?
          return answer
        elsif required
          $stderr.puts "** Answer required." if i < max
        else
          return default
        end
      end
      raise RuntimeError, "Answer expected but not entered."
    end

    def confirm(message, default: nil, max: 3)
      i = 0
      while (i += 1) <= max
        case default
        when nil   ; print message, " [y/n]: "
        when false ; print message, " [y/N]: "
        else       ; print message, " [Y/n]: "
        end
        #$stdout.flush()
        input = $stdin.readline().strip()
        case input
        when nil      ; raise RuntimeError, "confirm(): Failed to read answer because I/O closed."
        when /\A[yY]/ ; return true
        when /\A[nN]/ ; return false
        when ""       ; return default if default != nil
        end
        $stderr.puts "** Please enter 'y' or 'n'." if i < max
      end
      raise RuntimeError, "Expected 'y' or 'n', but not answered correctly."
    end

  end


  class Task

    def initialize(name, desc=nil, prerequisite=nil, argnames=nil, location=nil, schema=nil, important: nil, &block)
      @name      = name
      @desc      = desc
      @prerequisites = (prerequisite ? [prerequisite].flatten : []).freeze
      @argnames  = argnames ? argnames.freeze : nil
      @location  = location
      @important = important
      @block     = block
      if schema
        #; [!gpsw6] raises error when schema is specified but block is nil.
        block != nil  or
          raise TaskDefinitionError, "Task option schema cannot be specified when task block is empty."
        #; [!600yq] raises error if there is any contradiction between option schema and block parameters.
        _validate_block_params(block, schema)
      else
        #; [!fi4j3] creates default schema object when option schema is not specified.
        schema = TaskOptionSchema.new(block)
      end
      @schema    = schema
      @next_task = nil
    end
    attr_reader :name, :desc, :prerequisites, :argnames, :location, :block, :schema
    attr_accessor :next_task

    def hidden?()
      #; [!8kefc] 'important: false' means 'hidden: true'.
      return true if @important == false
      #; [!kuapz] if description is nil then returns true if 'important: false' is not specified.
      return @desc == nil
    end

    def important?()
      #; [!gg3gy] returns true or false if 'important:' kwarg specified.
      #; [!lk1se] returns nil if 'important:' kwarg not specified.
      return @important
    end

    private

    def _validate_block_params(block, schema)
      key_params = []
      block.parameters.each do |(ptype, pname)|
        case ptype
        when :req
          #; [!tvuag] parameter type `:req` must not appear in block parameters.
          raise InternalError.new("ptype :req appeared.")
        when :opt
          #; [!bsnmu] error when positional param of block is defined as a task option.
          if schema.opt_defined?(pname)
            raise TaskDefinitionError,
                  "Block parameter `#{pname}` is declared as a positional parameter,"+\
                  " but should be declared as a keyword parameter,"+\
                  " because it is defined as a task option in the schema."
          #elsif ! schema.arg_defined?(pname)
          #  raise TaskDefinitionError, "Block parameter `#{pname}` is not defined in schema."
          end
        when :rest
          #; [!7ube0] error when variable param of block is defined as a task option.
          if schema.opt_defined?(pname)
            raise TaskDefinitionError,
                  "Block parameter `#{pname}` is declared as a variable parameter,"+\
                  " but should be declared as a keyword parameter,"+\
                  " because it is defined as a task option in the schema."
          end
        when :key
          #; [!t2x6s] error when keyword param of block is not defined as a task option.
          if ! schema.opt_defined?(pname)
            raise TaskDefinitionError,
                  "Block parameter `#{pname}` is declared as a keyword parameter,"+\
                  " but not defined in the task option schema."
          end
          key_params << pname
        when :keyrest
          #; [!se4ol] variable keyword param of block is just ignored.
          #raise TaskDefinitionError, "Block parameter `#{pname}` is a variable keyword parameter which is not supported in MicroRake."
        else
          raise InternalError.new("ptype=#{ptype.inspect}")
        end
      end
      schema.each do |item|
        #; [!q3ylg] not raise error when 'help:' keyword param not found in task block parameters.
        next if item.key == :help
        #; [!ycykr] error when a task option is defined but there is no corresponding keyword param in the task block.
        key_params.include?(item.key)  or
          raise TaskDefinitionError,
                "Option `#{item.key}` is defined in task option schema,"+\
                " but not declared as a keyword parameter of the task block."
      end
    end

    public

    def append_task(other_task)
      #; [!jg8h1] appends other task to the end of linked list of tasks.
      t = self
      while t.next_task != nil
        t = t.next_task
      end
      t.next_task = other_task
      nil
    end

    def clone_task(new_name, new_desc=nil)
      #; [!1cp1k] copies the task object with new name and description.
      return self.class.new(new_name, new_desc || @desc, @prerequisites,
                            @argnames, @location, @schema,
                            important: @important, &@block)
    end

  end


  class TaskWrapper

    def initialize(task)
      #; [!llobx] accepts a task object.
      @task = task
    end

    def name          ; return @task.name                ; end
    def desc          ; return @task.desc                ; end
    def prerequisites ; return @task.prerequisites       ; end
    def prerequisite  ; return @task.prerequisites.first ; end

  end


  class TaskArgVals

    def initialize(argnames=nil, argvals)
      #; [!71ejo] stores argvals as instance variables.
      argnames.zip(argvals) do |k, v|
        instance_variable_set("@#{k}", v)
      end
      #; [!4pzq2] defines setter methods for argvals.
      #class <<self
      self.class.class_eval do
        attr_reader *argnames
      end
    end

    def [](key)
      #; [!qsi9j] returns argval corresponding to key.
      return instance_variable_get("@#{key}")
    end

  end


  class TaskHelpBuilder

    def initialize(task)
      @task = task
    end

    def build_task_help(command, all: false)
      #; [!johw0] returns help message of the task.
      #; [!mr7yw] adds '[<options>]' into 'Usage:' section only when the task has options.
      #; [!bt8ut] adds '[<arg1> [<arg2>]]' into 'Usage:' section only when the task has args.
      #; [!wua6b] adds 'Options:' section only when the task has options.
      #; [!22q3f] includes hidden options when `all: true` specified.
      t = @task
      arg_names, opt_names, has_restarg = _retrieve_arg_and_opt_names(t.block)
      has_opt = ! t.schema.empty?(all: all)
      has_arg = ! arg_names.empty?
      sb = []
      sb << Util.colorize_appname("#{command} #{t.name}") << " --- #{t.desc}\n"
      sb << "\n"
      sb << Util.colorize_secheader("Usage:") << "\n"
      sb << "  $ #{command} #{t.name}"
      sb << " [<options>]" if has_opt
      sb << _build_arguments_str(arg_names, has_restarg) if has_arg
      sb << "\n"
      if has_opt
        sb << "\n"
        sb << Util.colorize_secheader("Options:") << "\n"
        sb << t.schema.option_help(all: all)
      end
      sb << "\n"
      return sb.join()
    end

    private

    def _build_arguments_str(arg_names, has_restarg)
      sb = []
      #; [!h175w] arg name 'a_b_c' will be pritned as 'a-b-c'.
      #; [!q7lwp] arg name 'a_or_b_or_c' will be printed as 'a|b|c'.
      #; [!nyq2o] arg name 'file__html' will be printed as 'file.html'.
      sb << arg_names.collect {|x| " [<#{Util.format_argname(x)}>" }.join("")
      #; [!xerus] variable arg name will be printed as '<var>...".
      sb << "..." if has_restarg
      sb << ("]" * arg_names.length)
      return sb.join()
    end

    def _retrieve_arg_and_opt_names(block)
      #; [!axtdb] returns positional param names, keyword param names, and flag of rest arg.
      arg_names    = []
      opt_names    = []
      has_restarg  = false
      block.parameters.each do |(ptype, pname)|
        case ptype
        when :req  ; arg_names << pname
        when :opt  ; arg_names << pname
        when :rest ; arg_names << pname ; has_restarg = true
        when :key  ; opt_names << pname
        when :keyrest
        else
          raise InternalError.new("ptype=#{ptype.inspect}")
        end
      end if block
      return arg_names, opt_names, has_restarg
    end

  end


  class TaskBaseContext

    def initialize(task_manager)
      @__task_manager = task_manager
      @__curr_task = nil
      @__dones     = {}   # ex: {Task.new.object_id=>true}
      @__running   = []   # ex: ["task1", "prereq1"]
    end

    def current_task()
      return @__curr_task
    end

    def run_task(task_name, *args, **opts)
      mgr = @__task_manager
      if task_name.is_a?(Task)
        task = task_name
      else
        task = mgr.find_task(task_name, self)  or
          raise TaskExecutionError, "run_task(#{task_name.ispect}): Task not found."
      end
      backup = @__curr_task
      begin
        return _run_task(task, args, opts)
      ensure
        @__curr_task = backup
      end
    end

    private

    def _run_task(task, args, opts)
      mgr = @__task_manager
      name = _normalize(task.name)
      if @__dones[task.object_id]
        _report_trace("skip:  #{name}  (alrady done)") if $TRACE_MODE
        return false
      end
      _report_trace("enter: #{name}") if $TRACE_MODE
      tsk = task; ret = nil
      while tsk != nil
        _report_trace("next:  #{name}") if $TRACE_MODE && tsk != task
        TaskManager.detect_cyclic_task(tsk, @__running)
        _with_running(tsk) do
          tsk.prerequisites.each do |pre_name|
            pre_task = mgr.find_task(pre_name, tsk)  or
              raise TaskExecutionError, "#{pre_name}: Prerequisite task not found."
            run_task(pre_task)  # run prerequisite task with no args nor opts
          end
          _invoke_task(tsk, args, opts)  # run task block with args and opts
        end
        tsk = tsk.next_task
      end
      _report_trace("exit:  #{name}") if $TRACE_MODE
      @__dones[task.object_id] = true    # done
      return true
    end

    def _invoke_task(task, args, opts)
      if task.argnames
        args = [TaskWrapper.new(task), TaskArgVals.new(task.argnames, args)]
      end
      self.instance_exec(*args, **opts, &task.block) if task.block
    end

    def _normalize(name)
      Util.normalize_task_name(name)
    end

    def _with_running(task, &b)
      @__running.push(task)
      yield
      popped = @__running.pop()
      popped == task  or
        raise InternalError.new("task=#{task.inspect}, popped=#{popped.inspect}")
    end

    def _report_trace(msg)
      space = " " * (@__running.length + 1)
      s = "**#{space}#{msg}"
      s = Util.colorize_trace(s) if $stderr.tty?
      $stderr.puts s
    end

  end


  class TaskContext < TaskBaseContext
    include UnixUtils

    def initialize(task_manager)
      super
      set_prompt()
    end

    def prompt()
      space = " " * ((@_urake_chdir_depth ||= 0) + 1)
      if $stdout.tty?
        ## 30: black, 31: red, 32: green, 33: yellow, 34: blue,
        ## 35: magenta, 36: cyan, 37: white, 90: gray
        #return "\e[35m[urake]\e[0m$#{space}"     # magenta
        #return "\e[34m[urake]\e[0m$#{space}"     # blue
        return "\e[90m[urake]\e[0m$#{space}"     # gray
      else
        return "[urake]$#{space}"
      end
    end

  end


  class TaskManager

    def initialize()
      @tasks   = {}   # ex: {"test"=>Task.new("test", ...)}
    end

    def add_task(task)
      @tasks[_normalize(task.name)] = task
      self
    end

    def get_task(name)
      return @tasks[_normalize(name)]
    end

    def has_task?(name)
      return @tasks.key?(_normalize(name))
    end

    def delete_task(name)
      return @tasks.delete(_normalize(name))
    end

    def each_task(&block)
      return to_enum(:each_task) unless block_given?
      @tasks.values.each(&block)
      self
    end

    def find_task(relative_name, base_task_or_namespace)
      name = relative_name.to_s
      if name =~ /\A:/
        return get_task(name[1..-1])          # ex: ":a:b:foo" -> "a:b:foo"
      end
      base = base_task_or_namespace
      case base
      when Task
        items = base.name.to_s.split(":")       # ex: "a:b:c" -> ["a","b","c"]
        items.pop()                             # ex: ["a","b","c"] -> ["a","b"]
      when nil
        items = []
      else
        items = base.to_s.split(":")
      end
      while ! items.empty?
        full_name = (items + [name]).join(":")  # ex: "a:b:foo"
        return get_task(full_name) if has_task?(full_name)
        items.pop()
      end
      return get_task(name)                   # ex: "foo"
    end

    def run_task(task, *args, **opts)
      ctx = TaskContext.new(self)
      return ctx.run_task(task, *args, **opts)
    end

    private

    def _normalize(name)
      Util.normalize_task_name(name)
    end

    public

    def self.detect_cyclic_task(task, stack)
      i = stack.index(task)
      if i
        tasks = stack[i..-1] + [task]
        s1 = tasks.collect(&:name).join("->")
        shortener = Util::FilepathShortener.new()
        s2 = tasks.collect {|t|
          location = shortener.shorten_filepath(t.location)
          location = location.split(/:in `/).first if location
          "    %-20s : %s" % [t.name, location]
        }.join("\n")
        s2 = Util.colorize_unimportant(s2) if $stdout.tty?
        raise CyclicTaskError, "Cyclic task detected. (#{s1})\n#{s2}"
      end
    end

  end

  TASK_MANAGER = TaskManager.new()


  class TaskOptionSchema < Benry::CmdOpt::Schema

    HELP_SCHEMA_ITEM = Benry::CmdOpt::SchemaItem.new(
        :help, "-h, --help", "show help message",
        "h", "help", nil, false, hidden: true
    ).freeze

    def initialize(block=nil)
      super()
      add_item(HELP_SCHEMA_ITEM)
      if block
        block.parameters.each do |(ptype, pname)|
          case ptype
          when :req, :opt, :rest   # skip
          when :key
            case pname.to_s
            when /\Aopt_(\w)\z/   ; add(pname, "-#{$1}", "")
            when /\Aopt_(\w)_\z/  ; add(pname, "-#{$1} <val>", "")
            else                  ; add(pname, "--#{pname}[=<val>]", "")
            end
          when :keyrest
            #raise TaskDefinitionError, "#{pname}: Variable keyword parameter of task block is not supported."
          else
            raise InternalError.new("ptype=#{ptype.inspect}")
          end
        end
      end
      @should_convert_option_value = (block != nil)
    end

    def add_opt(key, optdef, desc, *rest, **kwargs)
      syms, rest2 = rest.partition {|x|
        x.is_a?(Symbol) && _boolean_key?(x)
      }
      syms.each {|x| kwargs[x] = true }
      return add(key, optdef, desc, *rest2, **kwargs)
    end

    def opt_defined?(key)
      return get(key) != nil
    end

    def should_convert_option_value?()
      return @should_convert_option_value
    end

    private

    def _boolean_key?(key)
      return BOOLEAN_KEYS.key?(key)
    end

    BOOLEAN_KEYS = {hidden: true, important: true, multiple: true}

  end


  class TaskOptionParser < Benry::CmdOpt::Parser

    def parse(args, all: true)
      opts = super
      if @schema.should_convert_option_value?
        opts2 = {}
        opts.each {|k, v| opts2[k] = _convert_value(v) }
        return opts2
      else
        return opts
      end
    end

    protected

    def parse_long_option(optstr, optdict)
      if optstr =~ /\A--(opt[-_]\w[-_]?)(?:=(.*))?\z/
        return handle_unknown_long_option(optstr, $1, $2 || true)
      end
      super
    end

    private

    def _convert_value(v)
      return Util.convert_value(v)
    end

  end


  module Export
    module_function

    def desc(desc, option_schema=nil, hidden: nil, important: nil)
      #; [!sddvl] creates schema object according to option schema definition.
      schema = nil
      if option_schema
        option_schema.is_a?(Hash)  or
          raise TaskDefinitionError, "desc(): Second argument should be a Hash object, but got #{option_schema.class} object (#{option_schema.inspect})."
        schema = TaskOptionSchema.new
        option_schema.each do |sym, arr|
          #if arr[0] =~ /\A\s*-/
            schema.add_opt(sym, *arr)
          #else
          #  schema.add_arg(sym, *arr)
          #end
        end
      end
      #; [!f6b6g] `hidden: true` is regarded as `important: false` internally.
      #; [!7fdl0] if `hidden: false` specified, description should not be nil.
      case hidden
      when nil       ;
      when true      ; important = false if important == nil
      when false     ; desc ||= ""
      end
      @_task_desc = [desc, schema, important]
    end

    def task(name, argnames=nil, &block)
      #; [!cb1wg] records method call location into task object.
      location = caller(1, 1).first
      #; [!bx3sr] creates a new task object and returns it.
      task = __create_task(name, argnames, location, :task, &block)
      name = task.name
      mgr = TASK_MANAGER
      if mgr.has_task?(task.name)
        #; [!z313l] if there is other task with same name, then appends new task to it.
        existing_task = mgr.get_task(name)
        existing_task.append_task(task)
      else
        #; [!8qlbs] new task object should be registered.
        mgr.add_task(task)
      end
      return task
    end

    def task!(name, argnames=nil, &block)
      #; [!7eeci] records method call location into task object.
      location = caller(1, 1).first
      #; [!214kt] creates a new task object and returns it.
      task = __create_task(name, argnames, location, :'task!', &block)
      mgr = TASK_MANAGER
      if mgr.has_task?(task.name)
        #; [!29qo8] if there is other task with same name, then removes it and registers new one.
        mgr.delete_task(task.name)
        mgr.add_task(task)
      else
        #; [!oodzr] raises error if there is no task with same name.
        raise TaskDefinitionError,
              #"task!(#{name.inspect}): Overwriting non-existing task."
              "task!(#{name.inspect}): Task to overwrite should exist, but not defined."
      end
      return task
    end

    def append_to_task(task_name, &block)
      #; [!s8mib] records method call location into task object.
      location = caller(1, 1).first
      #; [!bbmoy] raises error if `desc()` is called before this method.
      @_task_desc == nil  or
        raise TaskDefinitionError,
              "append_to_task(#{task_name.inspect}): Cannot be called with `desc()`."
      #; [!km0n6] creates a new task object and returns it.
      task = __create_task(task_name, nil, location, :append_to_task, &block)
      mgr = TASK_MANAGER
      if mgr.has_task?(task.name)
        #; [!9aq2i] appends new task object to existing task object.
        existing_task = mgr.get_task(task.name)
        existing_task.append_task(task)
      else
        #; [!usmb1] raises error if other task with same name doesn't exist.
        raise TaskDefinitionError,
              "append_to_task(#{task_name.inspect}): Task should exist, but not defined."
      end
      return task
    end

    def __create_task(name, argnames, location, func, &block)
      #; [!277vd] retrieves data set by `desc()`.
      if @_task_desc
        desc, schema, important = @_task_desc
        #; [!v3dvm] data should be cleared after retrieved.
        @_task_desc = nil
      else
        desc = schema = important = nil
      end
      #; [!0jper] retrieves prerequisite names from task name or argnames.
      name, argnames, prerequisite = __retrieve_prerequisite(name, argnames, func)
      #; [!14p62] considers namespace.
      if defined?(@_task_namespace) && ! @_task_namespace.empty?
        name = (@_task_namespace + [name]).join(":")
      end
      #; [!f9z9f] converts argnames into symbols.
      if argnames
        argnames = [argnames].flatten.collect {|x| x.to_s.intern }
      end
      #; [!ydlra] creates new task object and returns it.
      task = Task.new(name, desc, prerequisite, argnames, location, schema,
                      important: important, &block)
      return task
    end
    private :__create_task

    def __retrieve_prerequisite(task_name, argnames, func)
      #; [!nmbok] if task name is a Hash, then retrieves prerequisite names from it.
      prerequisite = nil
      if task_name.is_a?(Hash)
        dict = task_name
        dict.each do |k, v|
          task_name    = k
          prerequisite = v
          break
        end
      end
      #; [!yysmo] if argnames is a Hash, then retrieves prerequisite names from it.
      if argnames && argnames.is_a?(Hash)
        dict = argnames
        dict.each do |k, v|
          argnames     = k
          prerequisite = v
          break
        end
      end
      #; [!ujwvs] returns task name, argnamens, and prerequisite names.
      return task_name, argnames, prerequisite
    end
    private :__retrieve_prerequisite

    def find_task(task_name)
      #; [!ja7vq] considers current namespace.
      if defined?(@_task_namespace) && ! @_task_namespace.empty?
        namespace = @_task_namespace.join(":")
      else
        namespace = nil
      end
      #; [!39ufc] returns task object if task found.
      #; [!kgp19] returns nil if task not found.
      mgr = TASK_MANAGER
      return mgr.find_task(task_name, namespace)
    end

    def task?(task_name)
      #; [!2edan] returns true if the task is defined, false otherwise.
      return find_task(task_name) != nil
    end

    def file(*args, **kwargs, &block)
      #; [!ro813] raises NotImplementedError if `file()` is called.
      raise NotImplementedError.new("'file()' is not implemented in MicroRake.")
    end

    def namespace(name, alias_for: nil, &block)
      #; [!6986t] raises error if namespace name contains invalid char other than '\w' and ':'.
      name_ = name.to_s
      name_ =~ /\A[:\w]+\z/  or
        raise NamespaceError, "#{name}: Namespace name contains invalid character."
      #; [!dbusz] raises error if namespace name contains '::'.
      ! (name_ =~ /::/)  or
        raise NamespaceError, "'#{name}': Invalid namespace name."
      #; [!or5wf] converts namespace name ':foo' or 'foo:' to 'foo' automatically.
      name_ = name_.sub(/\A:/, '').sub(/:\z/, '')
      #; [!gzrnb] stacks namespace name with normalized.
      ns_name = Util.normalize_task_name(name_)
      (@_task_namespace ||= []) << ns_name
      begin
        yield
        #; [!80kn0] registers new alias task if `alias_for:` specified.
        if alias_for
          #; [!v1z88] considers namespace when finding original task of alias.
          #; [!elivv] raises error when original task of alias not found.
          mgr = TASK_MANAGER
          full_ns = @_task_namespace.join(":")
          original_task = mgr.find_task(alias_for, full_ns)  or
            raise NamespaceError, "'#{alias_for}': No such task."
          #; [!bq3ol] creates an alias task which is a clone of original one with different description.
          desc = "alias for '#{original_task.name}'"
          alias_task = original_task.clone_task(full_ns, desc)
          mgr.add_task(alias_task)
        end
        return ns_name
      ensure
        #; [!uxx3a] namespace name should be popped from namespace stack.
        popped = @_task_namespace.pop()
        popped == ns_name  or
          raise InternalError.new("popped=#{popped.inspect}, ns_name=#{ns_name.inspect}")
      end
    end

    def use_commands_instead_of_fileutils(module_)
      #; [!9yfrl] disables FileUtils commands.
      UnixUtils.disable_fileutils_commands()
      #; [!taukw] enables commands of the module.
      TaskContext.include(module_)   # ex: Benry::UnixCommand
    end

  end


  class MainApp

    def initialize(command=nil, _gopt_schema: nil, _task_manager: nil)
      @command = command || File.basename($0)
      @gopt_schema  = _gopt_schema || GLOBAL_OPTION_SCHEMA
      @task_manager = _task_manager || TASK_MANAGER
      @action_handler = CommandActionHandler.new(@command, @gopt_schema, @task_manager)
      @backtrace_enabled = false
    end
    attr_reader :command

    GLOBAL_OPTION_SCHEMA = Benry::CmdOpt::Schema.new.tap do |schema|
      schema.add(:all      , "-A, --all"      , "include hidden tasks for '-T'")
      schema.add(:backtrace, "    --backtrace", "print backtrace when error raised")
      schema.add(:dir      , "-C, --directory=<dir>", "change directory (tips: '-C .' not change dir)")
      schema.add(:describe , "-D, --describe" , "list tasks with description")
      schema.add(:execexit , "-e, --execute=<code>", "execute Ruby code and exit")
      schema.add(:execcont , "-E, --execute-continuee=<code>", "execute Ruby code and NOT exit")
      schema.add(:taskfile , "-f, --taskfile=<file>" , "Taskfile name (default: #{DEFAULT_TASKFILE})")
      schema.add(:rakefile , "    --rakefile=<file>" , "same as '--taskfile' (for Rake compatibility)")
      schema.add(:filter   , "-F <regexp>"    , "filter tasks for -T/-D/-P/-W")
      schema.add(:libdir   , "-I, --libdir=<dir>", "add dir to library path (multiple ok)", multiple: true)
      schema.add(:list     , "-l"             , "list tasks without command name")
      schema.add(:dryrun   , "-n, --dry-run"  , "dry-run mode (not execute)")
      schema.add(:nosearch , "-N, --no-search", "not search taskfile in parent dir")
      schema.add(:new      , "    --new"      , "print example code of taskfile")
      #schema.add(:prereqs  , "-P, --prereqs"  , "show prerequisites of each task")
      schema.add(:prereqs  , "-P, --prereqs"  , "detect cyclic task dependencies")
      schema.add(:quiet    , "-q, --quiet"    , "quiet mode (suppress echoback)")
      schema.add(:silent   , "-s, --silent"   , "silent mode (more quiet)")
      schema.add(:tasks    , "-T, --tasks"    , "list tasks with command name")
      schema.add(:userake  , "-u"             , "use 'Rakefile' instead of 'Taskfile.rb'")
      schema.add(:version  , "-V, --version"  , "print version")
      #schema.add(:verbose  , "-v, --verbose"  , "(TODO)")
      schema.add(:trace    , "-t, --trace"    , "trace task call with backtrace enabled")
      schema.add(:where    , "-W, --where"    , "filepath and lineno where task defined")
      schema.add(:help     , "-h, --help"     , "print help message")
    end

    def main(argv=ARGV)
      #; [!dtl8y] adds `$URAKE_OPTS` to command-line arguments.
      envvar = ENV[ENV_VAR]
      if envvar && ! envvar.empty?
        argv = envvar.split() + argv
      end
      #
      begin
        status_code = run(*argv)
        return status_code
      rescue => exc
        raise if @backtrace_enabled
        handle_exception(exc)
        return 1
      end
    end

    def run(*args)
      parser = Benry::CmdOpt::Parser.new(@gopt_schema)
      global_opts = parser.parse(args, all: false)
      g_opts = global_opts
      #
      done = handle_global_opts(g_opts)
      return 0 if done
      toggle_global_mode(g_opts)
      #
      filename = determine_task_filename(g_opts)
      filepath = find_task_file(filename, g_opts[:nosearch])
      if filepath == nil
        if args.empty?
          @action_handler.do_when_no_tasks_specified(false)
          return 0
        end
        raise CommandLineError, "#{filename}: Task file not found."
      end
      #
      change_dir_if_necessary(g_opts[:dir], filepath, filename, g_opts[:silent]) do
        require_rubyscript(filepath)
        if (rubycode = g_opts[:execexit] || g_opts[:execcont])
          @action_handler.do_exec_code(rubycode)
          return 0 if g_opts[:execexit]
        end
        run_the_task(args, g_opts)
      end
      #
      return 0
    end

    protected

    def handle_global_opts(g_opts)
      handler = @action_handler
      #; [!pcn0t] '-h' or '--help' option prints help message.
      if g_opts[:help]
        handler.do_help()
        return true
      end
      #; [!d0hln] '-V' or '--version' option prints version.
      if g_opts[:version]
        handler.do_version()
        return true
      end
      #; [!iw6ug] '-I' or '--libdir' option adds library path to `$LOAD_PATH`.
      regexp = _filter2regexp(g_opts[:filter])
      if g_opts[:libdir]
        #; [!f7729] skips if library path already exists in `$LOAD_PATH`.
        g_opts[:libdir].each do |x|
          ## same as Rake's behaviour (append to end of libpath)
          $LOAD_PATH << x unless $LOAD_PATH.include?(x)
          ## but item should be inserted into the head of path list, shouldn't it?
          #$LOAD_PATH.unshift(x) unless $LOAD_PATH.include?(x)
        end
      end
      #; [!07yf1] '-T' or '--tasks' option lists task names with command name.
      #; [!6t9fa] '-l' option lists task names without command name.
      if g_opts[:tasks] || g_opts[:list]
        load_task_file(g_opts)
        handler.do_list_tasks(all: g_opts[:all], filter: regexp, with_command: g_opts[:tasks])
        return true
      end
      #; [!yoqzz] '-D' or '--describe' option lists task names with description.
      if g_opts[:describe]
        load_task_file(g_opts)
        handler.do_list_descriptions(all: g_opts[:all], filter: regexp)
        return true
      end
      #; [!02xlo] '-P' or '--prereqs' option lists prerequisites of each task.
      #; [!26hf6] '-P' or '--prereqs' option reports cyclic task dependency.
      if g_opts[:prereqs]
        load_task_file(g_opts)
        handler.do_list_prerequisites(all: g_opts[:all], filter: regexp)
        return true
      end
      #; [!s3jek] '-W' or '--where' option lists locations of each task.
      if g_opts[:where]
        load_task_file(g_opts)
        handler.do_list_locations(all: g_opts[:all], filter: regexp)
        return true
      end
      #; [!59ev8] '--new' option prints example code of taskfile.
      if g_opts[:new]
        handler.do_new_taskfile()
        return true
      end
      #; [!vggoh] '--backtrace' option enables to print backtrace when error raised.
      #; [!byhaa] '-t' or '--trace' option enables to print backtrace when error raised.
      @backtrace_enabled = g_opts[:backtrace] || g_opts[:trace] || false
      #; [!jiixo] returns true if no need to do more, false if else.
      return false
    end

    def _filter2regexp(filter_pattern)
      return nil unless filter_pattern
      return Regexp.compile(filter_pattern)
    rescue RegexpError
      raise CommandLineError.new("#{filter_pattern}: Invalid regexp pattern.")
    end
    private :_filter2regexp

    def _handle(g_opts, flag, load_task_file_p=false, &b)  # not used
      return false unless flag
      load_task_file(g_opts) if load_task_file_p
      yield
      return true
    end
    private :_handle

    def toggle_global_mode(g_opts)
      $VERBOSE_MODE = false if g_opts[:quiet] || g_opts[:silent]
      $QUIET_MODE   = true  if g_opts[:quiet] || g_opts[:silent]
      $DRYRUN_MODE  = true  if g_opts[:dryrun]
      $TRACE_MODE   = true  if g_opts[:trace]
    end

    def determine_task_filename(g_opts)
      filename = g_opts[:taskfile] || g_opts[:rakefile] \
                 || (g_opts[:userake] ? 'Rakefile' : DEFAULT_TASKFILE)
      return filename
    end

    def find_task_file(filename, nosearch=false, max: 20)
      if File.exist?(filename)
        return File.absolute_path(filename)
      elsif nosearch
        return nil
      end
      #
      dirpath = Dir.pwd()
      i = 0
      while (i += 1) <= max
        filepath = File.join(dirpath, filename)
        if File.exist?(filepath)
          return filepath
        end
        dirpath2 = File.dirname(dirpath)
        break if dirpath2 == dirpath
        dirpath = dirpath2
      end
      return nil
    end

    def load_task_file(g_opts)
      filename = determine_task_filename(g_opts)
      filepath = find_task_file(filename, g_opts[:nosearch])
      filepath != nil  or
        raise CommandLineError, "#{filename}: Task file not found."
      require_rubyscript(filepath)
    end

    def require_rubyscript(filepath)
      $URAKE_TASKFILE_FULLPATH = filepath
      if filepath.end_with?(".rb")
        require filepath
      else
        load filepath
      end
    end

    def change_dir_if_necessary(dir, filepath, filename, silent, &b)
      dirpath = dir == '.' ? nil \
              : dir        ? dir \
              : File.exist?(filename) ? nil \
              : filepath[0..-(filename.length+1)]  # File.dirname(filepath)
      if dirpath == nil
        yield
      else
        back_to = Dir.pwd()
        Dir.chdir(dirpath)
        $stderr.puts "(in #{dirpath})" unless silent
        begin
          yield
        ensure
          Dir.chdir(back_to)
        end
      end
    end

    def run_the_task(args, g_opts)
      mgr = @task_manager
      #; [!zw84u] runs 'default' task if defined and no task name specified.
      if ! args.empty?
      elsif mgr.has_task?("default")
        args = ["default"]
      #; [!yq0sh] prints short usage if no task name specified nor 'default' task defined.
      else
        @action_handler.do_when_no_tasks_specified(true)
        return
      end
      #; [!vfn69] handles `task[var1,var2]` style argument.
      task_name = args.shift()
      if task_name =~ /\[(.*)\]\z/
        task_name = $`
        task_argvals = $1.split(',')
      else
        task_argvals = nil
      end
      #; [!nhvus] raises error when task not defined.
      task = mgr.get_task(task_name)  or
        raise CommandLineError, "#{task_name}: Task not defined."
      #; [!o9ouk] handles 'name=val' style arg as environment variables.
      while ! args.empty? && args[0] =~ /\A(\w+)=(.*)\z/
        ENV[$1] = $2
        args.shift()
      end
      #; [!1cwjs] parses task options even after arguments.
      #; [!8dn6t] not parse task options after '--'.
      parser = TaskOptionParser.new(task.schema)
      task_opts = parser.parse(args, all: true)
      #; [!xs3gw] if '-h' or '--help' option specified for task, show help message of the task.
      if task_opts[:help]
        #; [!4wzxj] global option '-A' or '--all' affects to task help message.
        s = TaskHelpBuilder.new(task).build_task_help(@command, all: g_opts[:all])
        print Util.uncolorize_unless_tty(s)
        return
      end
      #; [!wqfjl] runs the task with args and options if task name specified.
      args = task_argvals if task_argvals
      mgr.run_task(task, *args, **task_opts)
    end

    def handle_exception(exc)
      puts = $stdout.tty? ? proc {|s| $stdout.puts s } \
                          : proc {|s| $stdout.puts Util.uncolorize(s) }
      puts.("#{Util.colorize_error('[ERROR]')} #{exc.message}")
      return if skip_backtrace?(exc)
      shortener = Util::FilepathShortener.new()
      filecache = Util::FileLinesCache.new()
      filter_backtrace(exc.backtrace).each do |bt|
        bt2 = shortener.shorten_filepath(bt)
        puts.("    " + Util.colorize_location("from #{bt2}"))  # gray, italic
        if bt =~ /:(\d+):in `/
          filepath = $`
          lineno   = $1.to_i
          line = filecache.get_line_of_file_at(filepath, lineno)
          puts.("        #{line.strip}") if line
        end
      end
      filecache.clear_cache()
    end

    def skip_backtrace?(exc)
      case exc
      #when Benry::CmdOpt::SchemaError     ; return true
      when Benry::CmdOpt::OptionError     ; return true
      when CommandLineError               ; return true
      when CyclicTaskError                ; return true
      end
      return false
    end

    def filter_backtrace(backtrace)
      this_file = __FILE__ + ":"
      command_file = "/#{@command}:"
      return backtrace.reject {|bt|
        bt.start_with?(this_file) || bt.include?(command_file)
      }
    end

  end


  def self.main(argv=nil, command=nil)
    main_app = MainApp.new(command || File.basename($0))
    status_code = main_app.main(argv || ARGV)
    return status_code
  end


  class CommandActionHandler

    def initialize(command, gopt_schema, task_manager)
      @command = command
      @gopt_schema = gopt_schema
      @task_manager = task_manager
    end

    def help_message(command)
      name = APP_NAME
      schema = @gopt_schema
      return <<END
#{Util.colorize_appname(name)} (#{VERSION}) --- Better Rake, args & options available for every task.

#{Util.colorize_secheader("Usage:")}
  \e[1m#{command}\e[0m [<options>] <task> [<arguments...>]

#{Util.colorize_secheader("Options:")}
#{schema.option_help(23).chomp()}

#{Util.colorize_secheader("Tasks:")}
  Run `#{command} -T` to list task names.

#{Util.colorize_secheader("Example:")}
  $ #{command} --new > Taskfile.rb     # generate an example taskfile
  $ #{command} -T                      # list tasks
  $ #{command} hello                   # run a task
  $ #{command} hello Alice --lang=fr   # run a task with args and options
  $ #{command} hello --help            # (or '-h') help message of the task
END
    end

    def short_usage(command, taskfile_exist)
      msg = taskfile_exist \
          ? "`#{command} -T` for task list." \
          : "`#{command} --new` to create 'Taskfile.rb'."
      return <<END
Usage: #{command} [<options>] <task>

(Hint: Run `#{command} -h` for help, and #{msg})
END
    end

    def do_help()
      s = help_message(@command)
      print Util.uncolorize_unless_tty(s)
    end

    def do_version()
      puts VERSION
    end

    def _each_task_with_hyphenized_name(all, &b)
      mgr = @task_manager
      mgr.each_task.collect {|task|
        name = Util.hyphenize_task_name(task.name)  # ex: "a_b_c" -> "a-b-c"
        [name, task]
      }.sort_by {|pair| pair[0] }.each do |(name, task)|
        next if ! all && task.hidden?
        if task.argnames
          name = "%s[%s]" % [name, task.argnames.join(",")]
        end
        yield name, task
      end
    end
    private :_each_task_with_hyphenized_name

    def _colorize_according_to_task(s, task)
      return Util.colorize_hidden(s)    if task.hidden?     # gray color
      return Util.colorize_important(s) if task.important?  # bold
      return s
    end
    private :_colorize_according_to_task

    def do_list_tasks(all: false, filter: nil, with_command: true)
      format = with_command ?    # true if '-T', false if '-l'
               "#{@command} %-16s # %s" : "%-20s # %s"
      sb = []
      _each_task_with_hyphenized_name(all) do |name, task|
        next if filter && filter !~ name
        firstline = task.desc =~ /(.*)$/ ? $1 : nil
        s = format % [name, firstline]
        s = _colorize_according_to_task(s, task)
        sb << s << "\n"
      end
      print Util.uncolorize_unless_tty(sb.join())
    end

    def do_list_descriptions(all: false, filter: nil)
      format = "#{@command} %s"
      sb = []
      _each_task_with_hyphenized_name(all) do |name, task|
        next if filter && filter !~ name
        s = format % name
        s = _colorize_according_to_task(s, task)
        sb << s << "\n"
        if task.desc
          text = task.desc.gsub(/^/, "    ")
          text.chomp!
          sb << text << "\n"
        end
        sb << "\n"
      end
      print Util.uncolorize_unless_tty(sb.join())
    end

    def do_list_locations(all: false, filter: nil)
      format = "%-25s"
      shortener = Util::FilepathShortener.new()
      sb = []
      _each_task_with_hyphenized_name(all) do |name, task|
        next if filter && filter !~ name
        location = shortener.shorten_filepath(task.location)
        location = location.split(/:in `/).first if location
        s = format % name
        s = _colorize_according_to_task(s, task)
        sb << s << " " << location << "\n"
      end
      print Util.uncolorize_unless_tty(sb.join())
    end

    def do_list_prerequisites(all: false, filter: nil)
      mgr = @task_manager
      buf = []
      mgr.each_task do |task|
        next if filter && filter !~ task.name
        _traverse_task(task) do |tsk|
          _traverse_prerequeistes(tsk, 0, buf, [])
        end
      end
      print buf.join()
    end

    def _traverse_prerequeistes(task, depth, buf, stack)
      TaskManager.detect_cyclic_task(task, stack)
      mgr = @task_manager
      indent = "    " * depth
      name = Util.hyphenize_task_name(task.name)
      buf << indent << name << "\n"
      _traverse_task(task) do |tsk|
        stack.push(tsk)
        tsk.prerequisites.each do |pre_name|
          pre_task = mgr.find_task(pre_name, tsk)  or
            raise TaskDefinitionError, "#{pre_name}: Prerequisite task not found."
          _traverse_prerequeistes(pre_task, depth+1, buf, stack)
        end
        (popped = stack.pop()) == tsk  or
          raise InternalError.new("popped=#{popped.inspect}, tsk=#{tsk.inspect}")
      end
    end
    private :_traverse_prerequeistes

    def _traverse_task(task)
      tsk = task
      while tsk != nil
        yield tsk
        tsk = tsk.next_task
      end
    end

    def do_exec_code(ruby_code)
      eval ruby_code if ruby_code
    end

    def do_new_taskfile()
      print Util.render_default_taskfile(@command)
    end

    def do_when_no_tasks_specified(taskfile_exist)
      s = short_usage(@command, taskfile_exist)
      print Util.uncolorize_unless_tty(s)
    end

  end


end


if __FILE__ == $0
  include Benry::MicroRake::Export
  exit Benry::MicroRake.main()
end


__END__
# coding: utf-8
# frozen_string_literal: true

##
## if you prefere Benry::UnxCommand rather than FileUtils ...
##
#require 'benry/unixcommand'
#use_commands_instead_of_fileutils(Benry::UnixCommand)


##
## task examples
##
desc "print help message"
task :help do
  sh "%COMMAND% --help"
end

#task :default => :help

desc "delete garbage files (& product files too if '-a')", {
       :all => ["-a, --all", "delete product files, too"],
     }
task :clean do |all: false|
  garbages = GARBAGE_FILES.collect {|x| Dir.glob(x) }.flatten()
  products = PRODUCT_FILES.collect {|x| Dir.glob(x) }.flatten()
  rm_r garbages
  rm_r products if all
end

GARBAGE_FILES = ["*~", "*.tmp"]    # or CLEAN
PRODUCT_FILES = ["*.gem"]          # or CLOBBER


##
## arguments and options example
##
## Ex:
##   $ %COMMAND% hello                       # no arguments nor options
##   $ %COMMAND% hello Alice                 # arguments
##   $ %COMMAND% hello -c --lang=fr Alice    # arguments and options
##
desc "greeting message", {
       :lang  => ["-l, --lang=<en|fr|it>", "language", ["en","fr","it"]],
       :color => ["-c, --color[=<on|off>]", "enable color", TrueClass],
     }
task :hello do |name="world", lang: "en", color: false|
  case lang
  when "en" ; msg = "Hello, #{name}!"
  when "fr" ; msg = "Bonjour, #{name}!"
  when "it" ; msg = "Chao, #{name}!"
  else
    raise "#{lang}: Unknown language."
  end
  if color
    msg = "\e[36m#{msg}\e[0m"
  end
  puts msg
end


##
## namespace example
##
namespace :git, alias_for: "status:here" do

  desc "git status"
  task :status do |dir=nil|
    sh "git status -sb #{dir}"
  end

  desc "git status of current directory"
  task "status:here" do
    run_task(:status, ".")    # run "git:status" task with an argument
  end

  namespace :stash, alias_for: :list do

    desc "list stashes"
    task :list do
      sh "git stash list"
    end

    desc "show stash"
    task :show do |id|
      sh "git stash show #{id}"
    end

  end

end
