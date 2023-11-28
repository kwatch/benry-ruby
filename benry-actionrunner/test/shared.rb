# -*- coding: utf-8 -*-
# frozen_string_literal: true

$0 = "/usr/local/bin/arun"

require 'oktest'

require 'benry/actionrunner'



Oktest.global_scope do


  def arun(*args)
    sout, serr, status = arun!(*args)
    ok {serr} == ""
    ok {status} == 0
    return sout
  end

  def arun!(*args)
    #status = nil
    #sout, serr = capture_sio(tty: true) do
    #  status = Benry::ActionRunner.main(args)
    #end
    sout = serr = nil
    out = File.open("_sout", "w+", encoding: 'utf-8')
    err = File.open("_serr", "w+", encoding: 'utf-8')
    system "arun", *args, out: out, err: err
    err.rewind(); serr = err.read(); err.rewind(); err.truncate(0); err.close()
    out.rewind(); sout = out.read(); out.rewind(); out.truncate(0); out.close()
    status = $?.to_i
    return sout, serr, status
  ensure
    File.unlink "_sout" if File.exist?("_sout")
    File.unlink "_serr" if File.exist?("_serr")
  end

  def prepare_actionfile(action, execute=nil)
    execute ||= "puts \"Hi, \#{name}!\""
    content = <<"END"
require 'benry/actionrunner'
include Benry::ActionRunner::Export
class MyAction < Action
  @action.("test")
  def #{action}(name="world")
    #{execute}
  end
end
END
    File.write("Actionfile.rb", content, encoding: 'utf-8')
  end

  def clear_registry()
    Benry::CmdApp::REGISTRY.instance_eval do
      help_action = @metadata_dict["help"]
      @metadata_dict.clear()
      @metadata_dict["help"] = help_action
      @category_dict.clear()
      @abbrev_dict.clear()
    end
    $LOADED_FEATURES.delete(File.absolute_path("Actionfile.rb"))
    Benry::ActionRunner::CONFIG.trace_mode = nil
  end


end


module TestHelperModule
  module_function

  def setup_all()
    fname = Benry::ActionRunner::DEFAULT_FILENAME
    if File.exist?(fname)
      File.rename(fname, "__" + fname)
    end
    @_pwd = Dir.pwd()
    Dir.chdir "test"
  end

  def teardown_all()
    fname = Benry::ActionRunner::DEFAULT_FILENAME
    File.unlink(fname) if File.exist?(fname)
    Dir.chdir @_pwd
    if File.exist?("__" + fname)
      File.rename("__" + fname, fname)
    end
  end

end
