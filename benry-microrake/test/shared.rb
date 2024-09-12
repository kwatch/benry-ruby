# -*- coding: utf-8 -*-
# frozen_string_literal: true

require 'oktest'

require 'benry/microrake'
include Benry::MicroRake::Export


module MicroRakeTestHelper
  module_function

  def reset_microrake()
    mod = Benry::MicroRake
    mod.__send__(:remove_const, :TASK_MANAGER)
    mod.const_set(:TASK_MANAGER, mod::TaskManager.new())
    Object.__send__(:remove_const, :GARBAGE_FILES) if defined?(::GARBAGE_FILES)
    Object.__send__(:remove_const, :PRODUCT_FILES) if defined?(::PRODUCT_FILES)
    #
    filepath = File.absolute_path("./Taskfile.rb")
    $LOADED_FEATURES.delete(filepath)
    #
    $VERBOSE_MODE = true
    $QUIET_MODE   = false
    $DRYRUN_MODE  = false
    $TRACE_MODE   = false
  end

  $__here = Dir.pwd()
  $__testdir = "tmp/testdir"

  def setup_for_all()
    tdir = $__testdir
    FileUtils.mkdir_p(tdir) unless File.exist?(tdir)
    Dir.chdir(tdir)
    filename = "Taskfile.rb"
    str = Benry::MicroRake::Util.render_default_taskfile("urake2")
    File.write(filename, str)
  end

  def teardown_for_all()
    Dir.chdir($__here)
    FileUtils.rm_rf($__testdir)
  end

end


Oktest.global_scope do

  def capture_sout(tty: nil, &b)
    sout, serr = capture_sio(tty: tty, &b)
    ok {serr} == ""
    return sout
  end

  def create_taskfile(content)
    taskfile = "Taskfile.rb"
    backup   = taskfile + ".bkp"
    if File.exist?(taskfile) && ! File.exist?(backup)
      File.rename(taskfile, backup)
      at_end { File.rename(backup, taskfile) }
    end
    File.write(taskfile, content)
  end

  fixture :main do
    Benry::MicroRake::MainApp.new("urake2")
  end

  fixture :taskfile do
    "Taskfile.rb"
  end

end
