# -*- coding: utf-8 -*-


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

  def with_important(keyval={}, &block)
    bkup = {}
    keyval.each do |name, val|
      action = Benry::CmdApp::INDEX.get_action(name)
      bkup[name] = action.important
      action.instance_variable_set('@important', val)
    end
    begin
      yield
    ensure
      bkup.each do |name, val|
        action = Benry::CmdApp::INDEX.get_action(name)
        action.instance_variable_set('@important', val)
      end
    end
  end

  module_function

  def clear_index_except(klass)
    actions = Benry::CmdApp::INDEX.instance_variable_get('@actions')
    aliases = Benry::CmdApp::INDEX.instance_variable_get('@aliases')
    @_bkup_actions = actions.dup()
    actions.delete_if {|_, x| x.klass != klass }
    anames = actions.keys()
    @_bkup_aliases = aliases.dup()
    aliases.delete_if {|_, x| ! anames.include?(x.action_name) }
  end

  def restore_index()
    actions = Benry::CmdApp::INDEX.instance_variable_get('@actions')
    aliases = Benry::CmdApp::INDEX.instance_variable_get('@aliases')
    actions.update(@_bkup_actions)
    aliases.update(@_bkup_aliases)
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
