# -*- coding: utf-8 -*-

###
### File commands like FileUtils module
###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2021 kwatch@gmail.com $
### $License: MIT License $
###


#require 'fileutils'


module Benry


  module UnixCommand

    class Error < StandardError
    end

    module_function

    def __err(msg)
      raise ArgumentError.new(msg)
    end


    def prompt()
      #; [!uilyk] returns prompt string.
      return "$ "
    end

    def prompt!(depth)
      #; [!q992e] adds indentation after prompt.
      return prompt() + ' ' * depth
    end

    def echoback(cmd)
      #; [!x7atu] prints argument string into $stdout with prompt.
      puts "#{prompt!(@__depth ||= 0)}#{cmd}"
    end
    #alias fu_output_message echoback
    #private :fu_output_message

    def __echoback?()
      return self.class.const_get(:BENRY_ECHOBACK)
    end

    BENRY_ECHOBACK = true


    def echo(*args)
      __echo('echo', args)
    end

    def __echo(cmd, args)
      #; [!mzbdj] echoback command arguments.
      optchars = __prepare(cmd, args, "n", nil)
      not_nl   = optchars.include?('n')
      #; [!cjggd] prints arguments.
      #; [!vhpw3] not print newline at end if '-n' option specified.
      print args.join(" ")
      puts "" unless not_nl
    end


    def sys(*args, &b)
      __sys('sys', args, false, &b)
    end

    def sys!(*args, &b)
      __sys('sys!', args, true, &b)
    end

    def __sys(cmd, args, ignore_error, &b)
      optchars = __prepare(cmd, args, "q", nil) { nil }
      quiet_p  = optchars.include?("q")
      #; [!rqe7a] echoback command and arguments when `:p` not specified.
      #; [!ptipz] not echoback command and arguments when `:p` specified.
      echoback(args.join(" ")) if ! quiet_p && __echoback?()
      #; [!dccme] accepts one string, one array, or multiple strings.
      #; [!r9ne3] shell is not invoked if arg is one array or multiple string.
      if args[0].is_a?(Array)
        result = system(*args[0])
      else
        result = system(*args)
      end
      #; [!agntr] returns process status if command succeeded.
      #; [!clfig] yields block if command failed.
      #; [!deu3e] not yield block if command succeeded.
      #; [!chko8] block argument is process status.
      #; [!0yy6r] (sys) not raise error if block result is truthy
      #; [!xsspi] (sys) raises error if command failed.
      #; [!tbfii] (sys!) returns process status if command failed.
      stat = $?
      return stat if result
      if block_given?()
        result = yield stat
        return stat if result
      end
      return stat if ignore_error
      raise "Command failed with status (#{$?.exitstatus}): #{args.join(' ')}"
    end


    def ruby(*args, &b)
      __ruby('ruby', args, false, &b)
    end

    def ruby!(*args, &b)
      __ruby('ruby!', args, true, &b)
    end

    def __ruby(cmd, args, ignore_error, &b)
      #; [!98qro] echoback command and args.
      #; [!u5f5l] run ruby command.
      #; [!2jano] returns process status object if ruby command succeeded.
      #; [!69clt] (ruby) error when ruby command failed.
      #; [!z1f03] (ruby!) ignores error even when ruby command failed.
      ruby = RbConfig.ruby
      if args.length == 1
        __sys(cmd, ["#{ruby} #{args[0]}"], ignore_error, &b)
      else
        __sys(cmd, [ruby]+args, ignore_error, &b)
      end
    end


    def popen2( *args, **kws, &b); __popen(:popen2 , args, kws, &b); end   # :nodoc:
    def popen2e(*args, **kws, &b); __popen(:popen2e, args, kws, &b); end   # :nodoc:
    def popen3( *args, **kws, &b); __popen(:popen3 , args, kws, &b); end   # :nodoc:

    def __popen(cmd, args, kws, &b)   # :nodoc:
      #; [!8que2] calls 'Open3.popen2()'.
      #; [!s6g1r] calls 'Open3.popen2e()'.
      #; [!evlx7] calls 'Open3.popen3()'.
      require 'open3' unless defined?(::Open3)
      echoback(args.join(" ")) if __echoback?()
      return ::Open3.__send__(cmd, *args, **kws, &b)
    end

    def capture2(  *args, **kws); __capture(:capture2 , args, kws, false); end
    def capture2e( *args, **kws); __capture(:capture2e, args, kws, false); end
    def capture3(  *args, **kws); __capture(:capture3 , args, kws, false); end
    def capture2!( *args, **kws); __capture(:capture2 , args, kws, true ); end
    def capture2e!(*args, **kws); __capture(:capture2e, args, kws, true ); end
    def capture3!( *args, **kws); __capture(:capture3 , args, kws, true ); end

    def __capture(cmd, args, kws, ignore_error)   # :nodoc:
      #; [!5p4dw] calls 'Open3.capture2()'.
      #; [!jgn71] calls 'Open3.capture2e()'.
      #; [!n91rh] calls 'Open3.capture3()'.
      #; [!2s1by] error when command failed.
      #; [!qr3ka] error when command failed.
      #; [!thnyv] error when command failed.
      #; [!357e1] ignore errors even if command failed.
      #; [!o0b7c] ignore errors even if command failed.
      #; [!rwfiu] ignore errors even if command failed.
      require 'open3' unless defined?(::Open3)
      echoback(args.join(" ")) if __echoback?()
      arr = ::Open3.__send__(cmd, *args, **kws)
      ignore_error || arr[-1].exitstatus == 0  or
        raise "Command failed with status (#{arr[-1].exitstatus}): #{args.join(' ')}"
      return arr if ignore_error
      arr.pop()
      return arr.length == 1 ? arr[0] : arr
    end


    def cd(arg, &b)
      cmd = 'cd'
      #; [!gnmdg] expands file pattern.
      #; [!v7bn7] error when pattern not matched to any file.
      #; [!08wuv] error when pattern matched to multiple files.
      #; [!hs7u8] error when argument is not a directory name.
      dir = __glob_onedir(cmd, arg)
      #; [!cg5ns] changes current directory.
      here = Dir.pwd
      echoback("cd #{dir}") if __echoback?()
      Dir.chdir(dir)
      #; [!uit6q] if block given, then back to current dir.
      if block_given?()
        @__depth ||= 0
        @__depth += 1
        begin
          yield
        ensure
          @__depth -= 1
          echoback("cd -") if __echoback?()
          Dir.chdir(here)
        end
      end
      #; [!cg298] returns path before changing directory.
      return here
    end
    alias chdir cd

    def pushd(arg, &b)
      cmd = 'pushd'
      #; [!xl6lg] raises error when block not given.
      block_given?()  or
        raise ArgumentError, "pushd: requires block argument."
      #; [!nvkha] expands file pattern.
      #; [!q3itn] error when pattern not matched to any file.
      #; [!hveaj] error when pattern matched to multiple files.
      #; [!y6cq9] error when argument is not a directory name.
      dir = __glob_onedir(cmd, arg)
      #; [!7ksfd] replaces home path with '~'.
      here = Dir.pwd
      home = File.expand_path("~")
      here2 = here.start_with?(home) ? here.sub(home, "~") : here
      #; [!rxtd0] changes directory and yields block.
      echoback("pushd #{dir}") if __echoback?()
      @__depth ||= 0
      @__depth += 1
      Dir.chdir(dir)
      yield
      @__depth -= 1
      #; [!9jszw] back to origin directory after yielding block.
      echoback("popd    # back to #{here2}") if __echoback?()
      Dir.chdir(here)
      here
    end


    def __prepare(cmd, args, short_opts, to=nil)   # :nodoc:
      optchars = ""
      errmsg = nil
      while args[0].is_a?(Symbol)
        optstr = args.shift().to_s.sub(/^-/, '')
        optstr.each_char do |c|
          if short_opts.include?(c)
            optchars << c
          else
            errmsg ||= "#{cmd}: -#{c}: unknown option."
          end
        end
      end
      #
      if block_given?()
        yield optchars, args, to
      elsif __echoback?()
        buf = [cmd]
        buf << "-#{optchars}" unless optchars.empty?
        buf.concat(args)
        buf << to if to
        echoback(buf.join(" "))
      else
        nil
      end
      #
      __err errmsg if errmsg
      return optchars
    end

    def __filecheck1(cmd, args)  # :nodoc:
      n = args.length
      if    n < 2 ; __err "#{cmd}: requires two arguments."
      elsif n > 2 ; __err "#{cmd}: too much arguments."
      end
      #
      arr = Dir.glob(args[0]); n = arr.length
      if    n < 1 ; src = args[0]
      elsif n > 1 ; __err "#{cmd}: #{args[0]}: unexpectedly matched to multiple files (#{arr.sort.join(', ')})."
      else        ; src = arr[0]
      end
      #
      arr = Dir.glob(args[1]); n = arr.length
      if    n < 1 ; dst = args[1]
      elsif n > 1 ; __err "#{cmd}: #{args[1]}: unexpectedly matched to multiple files (#{arr.sort.join(', ')})."
      else        ; dst = arr[0]
      end
      #
      return src, dst
    end

    def __glob_onedir(cmd, to)    # :nodoc:
      arr = Dir.glob(to); n = arr.length
      if    n < 1 ; __err "#{cmd}: #{to}: directory not found."
      elsif n > 1 ; __err "#{cmd}: #{to}: unexpectedly matched to multiple filenames (#{arr.sort.join(', ')})."
      end
      dir = arr[0]
      File.directory?(dir)  or
        __err "#{cmd}: #{dir}: Not a directory."
      return dir
    end

    def __filecheck2(cmd, filenames, dir, overwrite)   # :nodoc:
      if ! overwrite
        filenames.each do |fname|
          newfile = File.join(dir, File.basename(fname))
          ! File.exist?(newfile)  or
            __err "#{cmd}: #{newfile}: file or directory already exists (to overwrite it, call '#{cmd}!' instead of '#{cmd}')."
        end
      end
    end

    def __glob_filenames(cmd, args, ignore)   # :nodoc:
      filenames = []
      block_p = block_given?()
      args.each do |arg|
        arr = Dir.glob(arg)
        if ! arr.empty?
          filenames.concat(arr)
        elsif block_p
          yield arg, filenames
        else
          ignore  or
            __err "#{cmd}: #{arg}: file or directory not found (add '-f' option to ignore missing files)."
        end
      end
      return filenames
    end


    def cp(*args, to: nil)
      __cp('cp', args, to: to, overwrite: false)
    end

    def cp!(*args, to: nil)
      __cp('cp!', args, to: to, overwrite: true)
    end

    def __cp(cmd, args, to: nil, overwrite: nil)  # :nodoc:
      #; [!mtuec] echoback copy command and arguments.
      optchars = __prepare(cmd, args, "prfl", to)
      recursive = optchars.include?("r")
      preserve  = optchars.include?("p")
      ignore    = optchars.include?("f")
      hardlink  = optchars.include?("l")
      #; [!u98f8] when `to:` keyword arg not specified...
      if ! to
        #; [!u39p0] error when number of arguments is not 2.
        #; [!fux6x] error when source pattern matched to multiple files.
        #; [!y74ux] error when destination pattern matched to multiple files.
        src, dst = __filecheck1(cmd, args)
        #
        if File.file?(src)
          #; [!qfidz] error when destination is a directory.
          ! File.directory?(dst)  or
            __err "#{cmd}: #{dst}: cannot copy into directory (requires `to: '#{dst}'` keyword option)."
          #; [!073so] (cp) error when destination already exists to avoid overwriting it.
          #; [!cpr7l] (cp!) overwrites existing destination file.
          ! File.exist?(dst) || overwrite  or
            __err "#{cmd}: #{dst}: file already exists (to overwrite it, call `#{cmd}!` instead of `#{cmd}`)."
        elsif File.directory?(src)
          #; [!0tw8r] error when source is a directory but '-r' not specified.
          recursive  or
            __err "#{cmd}: #{src}: is a directory (requires `:-r` option)."
          #; [!lf6qi] error when target already exists.
          ! File.exist?(dst)  or
            __err "#{cmd}: #{dst}: already exists."
        elsif File.exist?(src)
          #; [!4xxpe] error when source is a special file.
          __err "#{cmd}: #{src}: cannot copy special file."
        else
          #; [!urh40] do nothing if source file not found and '-f' option specified.
          return if ignore
          #; [!lr2bj] error when source file not found and '-f' option not specified.
          __err "#{cmd}: #{src}: not found."
        end
        #; [!lac46] keeps file mtime if '-p' option specified.
        #; [!d49vw] not keep file mtime if '-p' option not specified.
        #; [!kqgdl] copy a directory recursively if '-r' option specified.
        #; [!ko4he] copy a file into new file if '-r' option not specifieid.
        #; [!ubthp] creates hard link instead of copy if '-l' option specified.
        #; [!yu51t] error when copying supecial files such as character device.
        #FileUtils.cp_r src, dst, preserve: preserve, verbose: false if recursive
        #FileUtils.cp src, dst, preserve: preserve, verbose: false unless recursive
        __cp_file(cmd, src, dst, preserve, hardlink)
      #; [!z8xce] when `to:` keyword arg specified...
      else
        #; [!ms2sv] error when destination directory not exist.
        #; [!q9da3] error when destination pattern matched to multiple filenames.
        #; [!lg3uz] error when destination is not a directory.
        dir = __glob_onedir(cmd, to)
        #; [!slavo] error when file not exist but '-f' option not specified.
        filenames = __glob_filenames(cmd, args, ignore)
        #; [!1ceaf] (cp) error when target file or directory already exists.
        #; [!melhx] (cp!) overwrites existing files.
        __filecheck2(cmd, filenames, dir, overwrite)
        #; [!bi897] error when copying directory but '-r' option not specified.
        if ! recursive
          filenames.each do |fname|
            ! File.directory?(fname)  or
              __err "#{cmd}: #{fname}: cannot copy directory (add '-r' option to copy it)."
          end
        end
        #; [!k8gyx] keeps file timestamp (mtime) if '-p' option specified.
        #; [!zoun9] not keep file timestamp (mtime) if '-p' option not specified.
        #; [!654d2] copy files recursively if '-r' option specified.
        #; [!i5g8r] copy files non-recursively if '-r' option not specified.
        #; [!p7ah8] creates hard link instead of copy if '-l' option specified.
        #; [!e90ii] error when copying supecial files such as character device.
        #FileUtils.cp_r filenames, dir, preserve: preserve, verbose: false if recursive
        #FileUtils.cp   filenames, dir, preserve: preserve, verbose: false unless recursive
        filenames.each do |fname|
          newfile = File.join(dir, File.basename(fname))
          __cp_file(cmd, fname, newfile, preserve, hardlink)
        end
      end
    end

    def __cp_file(cmd, srcpath, dstpath, preserve, hardlink, bufsize=4096)   # :nodoc:
      ftype = File.ftype(srcpath)
      case ftype
      when 'link'
        File.symlink(File.readlink(srcpath), dstpath)
      when 'file'
        if hardlink
          File.link(srcpath, dstpath)
        else
          File.open(srcpath, 'rb') do |sf|
            File.open(dstpath, 'wb') do |df; bytes|
              df.write(bytes) while (bytes = sf.read(bufsize))
            end
          end
          __cp_meta(srcpath, dstpath) if preserve
        end
      when 'directory'
        Dir.mkdir(dstpath)
        Dir.open(srcpath) do |d|
          d.each do |x|
            next if x == '.' || x == '..'
            __cp_file(cmd, File.join(srcpath, x), File.join(dstpath, x), preserve, hardlink, bufsize)
          end
        end
        __cp_meta(srcpath, dstpath) if preserve
      else # characterSpecial, blockSpecial, fifo, socket, unknown
        __err "#{cmd}: #{srcpath}: cannot copy #{ftype} file."
      end
    end

    def __cp_meta(src, dst)    # :nodoc:
      stat = File.stat(src)
      File.chmod(stat.mode, dst)
      File.chown(stat.uid, stat.gid, dst)
      File.utime(stat.atime, stat.mtime, dst)
    end


    def mv(*args, to: nil)
      __mv('mv', args, to: to, overwrite: false)
    end

    def mv!(*args, to: nil)
      __mv('mv!', args, to: to, overwrite: true)
    end

    def __mv(cmd, args, to: nil, overwrite: nil)  # :nodoc:
      #; [!ajm59] echoback command and arguments.
      optchars = __prepare(cmd, args, "f", to)
      ignore = optchars.include?("f")
      #; [!g732t] when `to:` keyword argument not specified...
      if !to
        #; [!0f106] error when number of arguments is not 2.
        #; [!xsti2] error when source pattern matched to multiple files.
        #; [!4wam3] error when destination pattern matched to multiple files.
        src, dst = __filecheck1(cmd, args)
        #
        if !File.exist?(src)
          #; [!397kn] do nothing when file or directory not found but '-f' option specified.
          return if ignore
          #; [!1z89i] error when source file or directory not found.
          __err "#{cmd}: #{src}: not found."
        end
        #
        if File.exist?(dst)
          #; [!ude1j] cannot move file into existing directory.
          if File.file?(src) && File.directory?(dst)
            __err "#{cmd}: cannot move file '#{src}' into directory '#{dst}' without 'to:' keyword option."
          end
          #; [!2aws0] cannt rename directory into existing file or directory.
          if File.directory?(src)
            __err "#{cmd}: cannot rename directory '#{src}' to existing file or directory."
          end
          #; [!3fbpu] (mv) error when destination file already exists.
          #; [!zpojx] (mv!) overwrites existing files.
          overwrite  or
            __err "#{cmd}: #{dst}: already exists (to overwrite it, call `#{cmd}!` instead of `#{cmd}`)."
        end
        #; [!9eqt3] rename file or directory.
        #FileUtils.mv src, dst, verbose: false
        File.rename(src, dst)
      #; [!iu87y] when `to:` keyword argument specified...
      else
        #; [!wf6pc] error when destination directory not exist.
        #; [!8v4dn] error when destination pattern matched to multiple filenames.
        #; [!ppr6n] error when destination is not a directory.
        dir = __glob_onedir(cmd, to)
        #; [!bjqwi] error when file not exist but '-f' option not specified.
        filenames = __glob_filenames(cmd, args, ignore)
        #; [!k21ns] (mv) error when target file or directory already exists.
        #; [!vcaf5] (mv!) overwrites existing files.
        __filecheck2(cmd, filenames, dir, overwrite)
        #; [!ri2ia] move files into existing directory.
        #FileUtils.mv filenames, dir, verbose: false
        filenames.each do |fname|
          newfile = File.join(dir, File.basename(fname))
          File.rename(fname, newfile)
        end
      end
    end


    def rm(*args)
      __rm('rm', args)
    end

    def __rm(cmd, args)    # :nodoc:
      #; [!bikrs] echoback command and arguments.
      optchars = __prepare(cmd, args, "rf", nil)
      recursive = optchars.include?("r")
      ignore    = optchars.include?("f")
      #; [!va1j0] error when file not exist but '-f' option not specified.
      #; [!t6vhx] ignores missing files if '-f' option specified.
      filenames = __glob_filenames(cmd, args, ignore)
      #; [!o92yi] cannot remove directory unless '-r' option specified.
      if ! recursive
        filenames.each do |fname|
          ! File.directory?(fname)  or
            __err "#{cmd}: #{fname}: cannot remove directory (add '-r' option to remove it)."
        end
      end
      #; [!srx8w] remove directories recursively if '-r' option specified.
      #; [!mdgjc] remove files if '-r' option not specified.
      #FileUtils.rm_r filenames, verbose: false, secure: true if recursive
      #FileUtils.rm   filenames, verbose: false unless recursive
      __each_file(filenames, recursive) do |type, fpath|
        case type
        when :sym  ; File.unlink(fpath)
        when :dir  ; Dir.rmdir(fpath)
        when :file ; File.unlink(fpath)
        end
      end
    end


    def mkdir(*args)
      __mkdir('mkdir', args)
    end

    def __mkdir(cmd, args)    # :nodoc:
      optchars = __prepare(cmd, args, "pm", nil)
      mkpath = optchars.include?("p")
      mode   = optchars.include?("m") ? args.shift() : nil
      #; [!wd7rm] error when mode is invalid.
      case mode
      when nil              ; # pass
      when Integer          ; # pass
      when /\A\d+\z/        ; mode = mode.to_i(8)
      when /\A\w+[-+]\w+\z/ ; __err "#{cmd}: #{mode}: '-m' option doesn't support this style mode (use '0755' tyle instead)."
      else                  ; __err "#{cmd}: #{mode}: invalid mode."
      end
      #; [!xusor] raises error when argument not specified.
      ! args.empty?  or
        __err "#{cmd}: argument required."
      #
      filenames = []
      args.each do |arg|
        arr = Dir.glob(arg)
        if arr.empty?
          #; [!xx7mv] error when parent directory not exist but '-p' option not specified.
          if ! File.directory?(File.dirname(arg))
            mkpath  or
              __err "#{cmd}: #{arg}: parent directory not exists (add '-p' to create it)."
          end
          filenames << arg
        #; [!51pmg] error when directory already exists but '-p' option not specified.
        #; [!pydy1] ignores existing directories if '-p' option specified.
        elsif File.directory?(arr[0])
          mkpath  or
            __err "#{cmd}: #{arr[0]}: directory already exists."
        #; [!om8a6] error when file already exists.
        else
          __err "#{cmd}: #{arr[0]}: file exists."
        end
      end
      #; [!jc8hm] '-m' option specifies mode of new directories.
      if mkpath
        #; [!0zeu3] create intermediate path if '-p' option specified.
        #FileUtils.mkdir_p args, mode: mode, verbose: false
        pr = proc do |fname|
          parent = File.dirname(fname)
          parent != fname  or
            raise "internal error: fname=#{fname.inspect}, parent=#{parent.inspect}"
          pr.call(parent) unless File.directory?(parent)
          Dir.mkdir(fname)
          File.chmod(mode, fname) if mode
        end
        filenames.each {|fname| pr.call(fname) }
      else
        #; [!l0pr8] create directories if '-p' option not specified.
        #FileUtils.mkdir   args, mode: mode, verbose: false
        filenames.each {|fname|
          Dir.mkdir(fname)
          File.chmod(mode, fname) if mode
        }
      end
    end


    def rmdir(*args)
      __rmdir('rmdir', args)
    end

    def __rmdir(cmd, args)   # :nodoc:
      optchars = __prepare(cmd, args, "", nil)
      _ = optchars           # avoid waring of `ruby -wc`
      #; [!bqhdd] error when argument not specified.
      ! args.empty?  or
        __err "#{cmd}: argument required."
      #; [!o1k3g] error when directory not exist.
      dirnames = __glob_filenames(cmd, args, false) do |arg, filenames|
        __err "#{cmd}: #{arg}: No such file or directory."
      end
      #
      dirnames.each do |dname|
        #; [!ch5rq] error when directory is a symbolic link.
        if File.symlink?(dname)
          __err "#{cmd}: #{dname}: Not a directory."
        #; [!igfti] error when directory is not empty.
        elsif File.directory?(dname)
          found = Dir.open(dname) {|d|
            d.any? {|x| x != '.' && x != '..' }
          }
          ! found  or
            __err "#{cmd}: #{dname}: Directory not empty."
        #; [!qnnqy] error when argument is not a directory.
        elsif File.exist?(dname)
          __err "#{cmd}: #{dname}: Not a directory."
        else
          raise "** internal error: dname=#{dname.inspect}"
        end
      end
      #; [!jgmw7] remove empty directories.
      #FileUtils.rmdir dirnames, verbose: false
      dirnames.each do |dname|
        Dir.rmdir(dname)
      end
    end


    def ln(*args, to: nil)
      __ln('ln', args, to: to, overwrite: false)
    end

    def ln!(*args, to: nil)
      __ln('ln!', args, to: to, overwrite: true)
    end

    def __ln(cmd, args, to: nil, overwrite: nil)    # :nodoc:
      #; [!ycp6e] echobacks command and arguments.
      #; [!umk6m] keyword arg `to: xx` is echobacked as `-t xx`.
      optchars = __prepare(cmd, args, "s", to) do |optchars, args_, to_|
        buf = [cmd]
        buf << "-t #{to_}" if to_
        buf << "-#{optchars}n"         # `-n` means "don't follow symbolic link"
        echoback(buf.concat(args).join(" ")) if __echoback?()
      end
      symbolic = optchars.include?("s")
      #; [!qtbp4] when `to:` keyword argument not specified...
      if !to
        #; [!n1zpi] error when number of arguments is not 2.
        #; [!2rxqo] error when source pattern matched to multiple files.
        #; [!ysxdq] error when destination pattern matched to multiple files.
        src, dst = __filecheck1(cmd, args)
        #
        if ! symbolic
          #; [!4ry8j] (hard link) error when source file not exists.
          File.exist?(src)  or
            __err "#{cmd}: #{src}: No such file or directory."
          #; [!tf29w] (hard link) error when source is a directory.
          ! File.directory?(src)  or
            __err "#{cmd}: #{src}: Is a directory."
        end
        #; [!zmijh] error when destination is a directory without `to:` keyword argument.
        if File.directory?(dst)
          __err "#{cmd}: #{dst}: cannot create link under directory without `to:` keyword option."
        end
        #; [!nzci0] (ln) error when destination already exists.
        if ! overwrite
          ! File.exist?(dst)  or
            __err "#{cmd}: #{dst}: File exists (to overwrite it, call `#{cmd}!` instead of `#{cmd}`)."
        #; [!dkqgq] (ln!) overwrites existing destination file.
        else
          File.unlink(dst) if File.symlink?(dst) || File.file?(dst)
        end
        #; [!oxjqv] create symbolic link if '-s' option specified.
        #; [!awig1] (symlink) can create symbolic link to non-existing file.
        #; [!5kl3w] (symlink) can create symbolic link to directory.
        if symbolic
          File.unlink(dst) if overwrite && File.symlink?(dst)
          File.symlink(src, dst)
        #; [!sb29p] create hard link if '-s' option not specified.
        else
          File.link(src, dst) unless symbolic
        end
      #; [!5x2wr] when `to:` keyword argument specified...
      else
        #; [!5gfxk] error when destination directory not exist.
        #; [!euu5d] error when destination pattern matched to multiple filenames.
        #; [!42nb7] error when destination is not a directory.
        dir = __glob_onedir(cmd, to)
        #; [!x7wh5] (symlink) can create symlink to unexisting file.
        #; [!ml1vm] (hard link) error when source file not exist.
        filenames = __glob_filenames(cmd, args, false) do |arg, filenames|
          if symbolic
            filenames << arg
          else
            __err "#{cmd}: #{arg}: No such file or directory."
          end
        end
        #; [!mwukw] (ln) error when target file or directory already exists.
        #; [!c3vwn] (ln!) error when target file is a directory.
        #__filecheck2(cmd, filenames, dir, overwrite)
        filenames.each do |fname|
          newfile = File.join(dir, fname)
          if File.symlink?(newfile)
            overwrite  or
              __err "#{cmd}: #{newfile}: symbolic link already exists (to overwrite it, call `#{cmd}!` instead of `#{cmd}`)."
          elsif File.file?(newfile)
            overwrite  or
              __err "#{cmd}: #{newfile}: File exists (to overwrite it, call `#{cmd}!` instead of `#{cmd}`)."
          elsif File.directory?(newfile)
            __err "#{cmd}: #{newfile}: directory already exists."
          end
        end
        #
        filenames.each do |fname|
          newfile = File.join(dir, File.basename(fname))
          #; [!bfcki] (ln!) overwrites existing symbolic links.
          #; [!ipy2c] (ln!) overwrites existing files.
          if File.symlink?(newfile) || File.file?(newfile)
            File.unlink(newfile) if overwrite
          end
          #; [!c8hpp] (hard link) create hard link under directory if '-s' option not specified.
          #; [!9tv9g] (symlik) create symbolic link under directory if '-s' option specified.
          if symbolic
            File.symlink(fname, newfile)
          else
            File.link(fname, newfile)
          end
        end
      end
    end


    def atomic_symlink!(src, dst)
      cmd = 'atomic_symlink!'
      #; [!gzp4a] creates temporal symlink and rename it when symlink already exists.
      #; [!lhomw] creates temporal symlink and rename it when symlink not exist.
      if File.symlink?(dst) || ! File.exist?(dst)
        tmp = "#{dst}.#{rand().to_s[2..5]}"
        echoback("ln -s #{src} #{tmp} && mv -Tf #{tmp} #{dst}") if __echoback?()
        File.symlink(src, tmp)
        File.rename(tmp, dst)
      #; [!h75kp] error when destination is normal file or directory.
      else
        __err "#{cmd}: #{dst}: not a symbolic link."
      end
    end


    def pwd()
      #; [!aelx6] echoback command and arguments.
      echoback("pwd") if __echoback?()
      #; [!kh3l2] prints current directory path.
      puts Dir.pwd
    end


    def touch(*args)
      __touch('touch', *args)
    end

    def __touch(cmd, *args)    # :nodoc:
      #; [!ifxob] echobacks command and arguments.
      optchars = __prepare(cmd, args, "amrc", nil)
      access_time = optchars.include?("a")
      modify_time = optchars.include?("m")
      not_create  = optchars.include?("c")
      ref_file    = optchars.include?("r") ? args.shift() : nil
      #; [!c7e51] error when reference file not exist.
      ref_file.nil? || File.exist?(ref_file)  or
        __err "#{cmd}: #{ref_file}: not exist."
      #; [!pggnv] changes both access time and modification time in default.
      if access_time == false && modify_time == false
        access_time = true
        modify_time = true
      end
      #; [!o9h74] expands file name pattern.
      filenames = []
      args.each do |arg|
        arr = Dir.glob(arg)
        if arr.empty?
          filenames << arg
        else
          filenames.concat(arr)
        end
      end
      #; [!9ahsu] changes timestamp of files to current datetime.
      now = Time.now
      filenames.each do |fname|
        atime = mtime = now
        #; [!wo080] if reference file specified, use it's timestamp.
        if ref_file
          atime = File.atime(ref_file)
          mtime = File.mtime(ref_file)
        end
        #; [!726rq] creates empty file if file not found and '-c' option not specified.
        #; [!cfc40] skips non-existing files if '-c' option specified.
        if ! File.exist?(fname)
          next if not_create
          File.open(fname, 'w') {|f| f.write("") }
        end
        #; [!s50bp] changes only access timestamp if '-a' option specified.
        #; [!k7zap] changes only modification timestamp if '-m' option specified.
        #; [!b5c1n] changes both access and modification timestamps in default.
        if false
        elsif access_time && modify_time
          File.utime(atime, mtime, fname)
        elsif access_time
          File.utime(atime, File.mtime(fname), fname)
        elsif modify_time
          File.utime(File.atime(fname), mtime, fname)
        end
      end
    end


    def chmod(*args)
      __chmod("chmod", args)
    end

    def __chmod(cmd, args, _debug=false)    # :nodoc:
      #; [!pmmvj] echobacks command and arguments.
      optchars = __prepare(cmd, args, "R", nil)
      recursive = optchars.include?("R")
      #; [!94hl9] error when mode not specified.
      mode_s = args.shift()  or
        __err "#{cmd}: argument required."
      #; [!c8zhu] mode can be integer or octal string.
      mode_i = nil; mask = op = nil
      case mode_s
      when Integer
        mode_i = mode_s
        #; [!j3nqp] error when integer mode is invalid.
        (0..0777).include?(mode_i)  or
          __err "#{cmd}: #{mode_i}: Invalid file mode."
      when /\A[0-7][0-7][0-7][0-7]?\z/
        mode_i = mode_s.to_i(8)    # octal -> decimal
      #; [!ox3le] converts 'u+r' style mode into mask.
      when /\A([ugoa])([-+])([rwxst])\z/
        who = $1; op = $2; perm = $3
        i = "ugoa".index(who)  or raise "internal error: who=#{who.inspect}"
        mask = CHMOD_MODES[perm][i]
      #; [!axqed] error when mode is invalid.
      else
        __err "#{cmd}: #{mode_s}: Invalid file mode."
      end
      return mode_i, mask if _debug
      #; [!ru371] expands file pattern.
      #; [!ou3ih] error when file not exist.
      #; [!8sd4b] error when file pattern not matched to anything.
      filenames = __glob_filenames(cmd, args, false) do |arg, filenames|
        __err "#{cmd}: #{arg}: No such file or directory."
      end
      #; [!q1psx] changes file mode.
      #; [!4en6n] skips symbolic links.
      #; [!4e7ve] changes mode recursively if '-R' option specified.
      __each_file(filenames, recursive) do |type, fpath|
        next if type == :sym
        if mode_i
          mode = mode_i
        else
          mode = File.stat(fpath).mode
          mode = case op
                 when '+' ; mode | mask
                 when '-' ; mode & ~mask
                 end
        end
        File.chmod(mode, fpath)
      end
    end

    def __each_file(filenames, recursive, &b)    # :nodoc:
      filenames.each do |fname|
        __each_path(fname, recursive, &b)
      end
    end

    def __each_path(fpath, recursive, &b)    # :nodoc:
      if File.symlink?(fpath)
        yield :sym, fpath
      elsif File.directory?(fpath) && recursive
        Dir.open(fpath) do |d|
          d.each do |x|
            next if x == '.' || x == '..'
            __each_path(File.join(fpath, x), recursive, &b)
          end
        end
        yield :dir, fpath
      else
        yield :file, fpath
      end
    end

    CHMOD_MODES = {
      ## perm => [user, group, other, all]
      'r' => [ 0400,  0040,  0004,  0444],
      'w' => [ 0200,  0020,  0002,  0222],
      'x' => [ 0100,  0010,  0001,  0111],
      's' => [04000, 02000,     0, 06000],
      't' => [    0,     0,     0, 01000],
    }.freeze


    def chown(*args)
      __chown("chown", args)
    end

    def __chown(cmd, args, _debug=false)    # :nodoc:
      #; [!5jqqv] echobacks command and arguments.
      optchars = __prepare(cmd, args, "R", nil)
      recursive = optchars.include?("R")
      #; [!hkxgu] error when owner not specified.
      owner = args.shift()  or
        __err "#{cmd}: argument required."
      #; [!0a35v] accepts integer as user id.
      owner = owner.to_s if owner.is_a?(Integer)
      #; [!b5qud] accepts 'user:group' argument.
      #; [!18gf0] accepts 'user' argument.
      #; [!mw5tg] accepts ':group' argument.
      case owner
      when /\A(\w+):?\z/     ; user = $1 ; group = nil
      when /\A(\w+):(\w+)\z/ ; user = $1 ; group = $2
      when /\A:(\w+)\z/      ; user = nil; group = $1
      else
        __err "#{cmd}: #{owner}: invalid owner."
      end
      #; [!jyecc] converts user name into user id.
      #; [!kt7mp] error when invalid user name specified.
      begin
        user_id = user ? __chown_uid(user) : nil
      rescue ArgumentError
        __err "#{cmd}: #{user}: unknown user name."
      end
      #; [!f7ye0] converts group name into group id.
      #; [!szlsb] error when invalid group name specified.
      begin
        group_id = group ? __chown_gid(group) : nil
      rescue ArgumentError
        __err "#{cmd}: #{group}: unknown group name."
      end
      return user_id, group_id if _debug
      #; [!138eh] expands file pattern.
      #; [!tvpey] error when file not exist.
      #; [!ovkk8] error when file pattern not matched to anything.
      filenames = __glob_filenames(cmd, args, false) do |arg, filenames|
        __err "#{cmd}: #{arg}: No such file or directory."
      end
      #
      #; [!7tf3k] changes file mode.
      #; [!m6mrg] skips symbolic links.
      #; [!b07ff] changes file mode recursively if '-R' option specified.
      __each_file(filenames, recursive) do |type, fpath|
        next if type == :sym
        File.chown(user_id, group_id, fpath)
      end
    end

    def __chown_uid(user)    # :nodoc:
      require 'etc' unless defined?(::Etc)
      case user
      when nil       ; return nil
      when /\A\d+\z/ ; return user.to_i
      else           ; return (x = Etc.getpwnam(user)) ? x.uid : nil  # ArgumentError
      end
    end

    def __chown_gid(group)    # :nodoc:
      require 'etc' unless defined?(::Etc)
      case group
      when nil       ; return nil
      when /\A\d+\z/ ; return group.to_i
      else           ; return (x = Etc.getgrnam(group)) ? x.gid : nil  # ArgumentError
      end
    end


    def store(*args, to:)
      __store('store', args, false, to: to)
    end

    def store!(*args, to:)
      __store('store!', args, true, to: to)
    end

    def __store(cmd, args, overwrite, to:)
      #; [!9wr1o] error when `to:` keyword argument not specified.
      ! to.nil?  or
        __err "#{cmd}: 'to:' keyword argument required."
      #; [!n43u2] echoback command and arguments.
      optchars = __prepare(cmd, args, "pfl", to)
      preserve = optchars.include?("p")
      ignore   = optchars.include?("f")
      hardlink = optchars.include?("l")
      #; [!588e5] error when destination directory not exist.
      #; [!lm43y] error when destination pattern matched to multiple filenames.
      #; [!u5zoy] error when destination is not a directory.
      dir = __glob_onedir(cmd, to)
      #; [!g1duw] error when absolute path specified.
      args.each do |arg|
        #! File.absolute_path?(arg)  or   # Ruby >=  2.7
        File.absolute_path(arg) != arg  or
          __err "#{cmd}: #{arg}: absolute path not expected (only relative path expected)."
      end
      #; [!je1i2] error when file not exist but '-f' option not specified.
      filenames = __glob_filenames(cmd, args, ignore)
      #; [!5619q] (store) error when target file or directory already exists.
      #; [!cw08t] (store!) overwrites existing files.
      if ! overwrite
        filenames.each do |fpath|
          newpath = File.join(dir, fpath)
          ! File.exist?(newpath)  or
            __err "#{cmd}: #{newpath}: destination file or directory already exists."
        end
      end
      #; [!4y4zy] copy files with keeping filepath.
      #; [!f0n0y] copy timestamps if '-p' option specified.
      #; [!w8oq6] creates hard links if '-l' option specified.
      #; [!7n869] error when copying supecial files such as character device.
      pathcache = {}
      filenames.each do |fpath|
        newpath = File.join(dir, fpath)
        __mkpath(File.dirname(newpath), pathcache)
        __cp_file(cmd, fpath, newpath, preserve, hardlink, bufsize=4096)
      end
    end

    def __mkpath(dirpath, pathcache={})
      if ! pathcache.include?(dirpath)
        parent = File.dirname(dirpath)
        __mkpath(parent, pathcache) unless parent == dirpath
        Dir.mkdir(dirpath) unless File.exist?(dirpath)
        pathcache[dirpath] = true
      end
    end


    def zip(*args)
      __zip('zip', args, false)
    end

    def zip!(*args)
      __zip('zip', args, true)
    end

    def __zip(cmd, args, overwrite)
      #; [!zzvuk] requires 'zip' gem automatically.
      require 'zip' unless defined?(::Zip)
      #; [!zk1qt] echoback command and arguments.
      optchars = __prepare(cmd, args, "r0123456789", nil)
      recursive = optchars.include?('r')
      complevel = (optchars =~ /(\d)/ ? $1.to_i : nil)
      #; [!lrnj7] zip filename required.
      zip_filename = args.shift()  or
        __err "#{cmd}: zip filename required."
      #; [!khbiq] zip filename can be glob pattern.
      #; [!umbal] error when zip file glob pattern matched to mutilple filenames.
      arr = Dir.glob(zip_filename); n = arr.length
      if    n < 1 ; nil
      elsif n > 1 ; __err "#{cmd}: #{zip_filename}: matched to multiple filenames (#{arr.sort.join(', ')})."
      else        ; zip_filename = arr[0]
      end
      #; [!oqzna] (zip) raises error if zip file already exists.
      ! File.exist?(zip_filename) || overwrite  or
        __err "#{cmd}: #{zip_filename}: already exists (to overwrite it, call `#{cmd}!` command instead of `#{cmd}` command)."
      #; [!uu8uz] expands glob pattern.
      #; [!nahxa] error if file not exist.
      filenames = __glob_filenames(cmd, args, false) do |arg, _|
        __err "#{cmd}: #{arg}: file or directory not found."
      end
      #; [!qsp7c] cannot specify absolute path.
      filenames.each do |fname|
        if File.absolute_path(fname) == fname   # Ruby >= 2.7: File.absolute_path?()
          __err "#{cmd}: #{fname}: not support absolute path."
        end
      end
      #; [!e995z] (zip!) removes zip file if exists.
      File.unlink(zip_filename) if File.exist?(zip_filename)
      #; [!3sxmg] supports complession level (0~9).
      orig = Zip.default_compression
      Zip.default_compression = complevel if complevel
      #; [!p8alf] creates zip file.
      begin
        zipf = ::Zip::File.open(zip_filename, create: true) do |zf|  # `compression_level: n` doesn't work. why?
          filenames.each do |fname|
            __zip_add(cmd, zf, fname, recursive)
          end
          zf
        end
      ensure
        #; [!h7yxl] restores value of `Zip.default_compression`.
        Zip.default_compression = orig if complevel
      end
      #; [!fvvn8] returns zip file object.
      return zipf
    end

    def __zip_add(cmd, zf, fpath, recursive)
      ftype = File.ftype(fpath)
      case ftype
      when 'link'; zf.add(fpath, fpath)
      when 'file'; zf.add(fpath, fpath)
      when 'directory'
        zf.add(fpath, fpath)
        #; [!bgdg7] adds files recursively into zip file if '-r' option specified.
        Dir.open(fpath) do |dir|
          dir.each do |x|
            next if x == '.' || x == '..'
            __zip_add(cmd, zf, File.join(fpath, x), recursive)
          end
        end if recursive
      else
        #; [!jgt96] error when special file specified.
        __err "#{cmd}: #{fpath}: #{ftype} file not supported."
      end
    end


    def unzip(*args)
      __unzip('unzip', args, false)
    end

    def unzip!(*args)
      __unzip('unzip!', args, true)
    end

    def __unzip(cmd, args, overwrite)
      #; [!eqx48] requires 'zip' gem automatically.
      require 'zip' unless defined?(::Zip)
      #; [!ednxk] echoback command and arguments.
      optchars = __prepare(cmd, args, "d", nil)
      outdir   = optchars.include?('d') ? args.shift() : nil
      #; [!1lul7] error if zip file not specified.
      zip_filename = args.shift()  or
        __err "#{cmd}: zip filename required."
      #; [!0yyg8] target directory should not exist, or be empty.
      if outdir
        if ! File.exist?(outdir)
          # pass
        elsif File.directory?(outdir)
          #; [!1ls2h] error if target directory not empty.
          found = Dir.open(outdir) {|dir|
            dir.find {|x| x != '.' && x != '..' }
          }
          ! found  or
            __err "#{cmd}: #{outdir}: directory not empty."
        else
          #; [!lb6r5] error if target directory is not a directory.
          __err "#{cmd}: #{outdir}: not a directory."
        end
      end
      #; [!o1ot5] expands glob pattern.
      #; [!92bh4] error if glob pattern matched to multiple filenames.
      #; [!esnke] error if zip file not found.
      arr = Dir.glob(zip_filename); n = arr.length
      if    n < 1 ; __err "#{cmd}: #{zip_filename}: zip file not found."
      elsif n > 1 ; __err "#{cmd}: #{zip_filename}: matched to multiple filenames (#{arr.sort.join(' ')})."
      else        ; zip_filename = arr[0]
      end
      #
      filenames = args
      filenames = nil if filenames.empty?
      #; [!dzk7c] creates target directory if not exists.
      __mkpath(outdir, {}) if outdir && ! File.exist?(outdir)
      #
      orig = ::Zip.on_exists_proc
      begin
        #; [!06nyv] (unzip!) overwrites existing files.
        ::Zip.on_exists_proc = overwrite
        extglob = File::FNM_EXTGLOB
        #; [!ekllx] (unzip) error when file already exists.
        ::Zip::File.open(zip_filename) do |zf|
          zf.each do |x|
            next if filenames && ! filenames.find {|pat| File.fnmatch?(pat, x.name, extglob) }
            #; [!zg60i] error if file has absolute path.
            outdir || File.absolute_path(x.name) != x.name  or
              __err "#{cmd}: #{x.name}: cannot extract absolute path."
            #
            next if x.directory?
            fpath = outdir ? File.join(outdir, x.name) : x.name
            overwrite || ! File.exist?(fpath)  or
              __err "#{cmd}: #{fpath}: file already exists (to overwrite it, call `#{cmd}!` command instead of `#{cmd}` command)."
          end
        end
        #; [!0tedi] extract zip file.
        ::Zip::File.open(zip_filename) do |zf|
          zf.each do |x|
            #; [!ikq5w] if filenames are specified, extracts files matched to them.
            next if filenames && ! filenames.find {|pat| File.fnmatch?(pat, x.name, extglob) }
            #; [!dy4r4] if '-d' option specified, extracts files under target directory.
            if outdir
              x.extract(File.join(outdir, x.name))
            #; [!5u645] if '-d' option not specified, extracts files under current directory.
            else
              x.extract()
            end
          end
        end
      ensure
        #; [!sjf80] (unzip!) `Zip.on_exists_proc` should be recovered.
        ::Zip.on_exists_proc = orig
      end
    end


    def time(format=nil, &b)
      #; [!ddl3a] measures elapsed time of block and reports into stderr.
      pt1 = Process.times()
      t1  = Time.new
      yield
      t2  = Time.new
      pt2 = Process.times()
      user = pt2.cutime - pt1.cutime
      sys  = pt2.cstime - pt1.cstime
      real = t2 - t1
      format ||= "        %.3fs real       %.3fs user       %.3fs sys"
      $stderr.puts ""
      $stderr.puts format % [real, user, sys]
    end


  end


end
