# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake::TaskOptionSchema do


    topic ':HELP_SCHEMA_ITEM' do

      spec "[!b3pwr] common help option item should be immutable." do
        schema_item = Benry::MicroRake::TaskOptionSchema::HELP_SCHEMA_ITEM
        ok {schema_item}.frozen?
      end

      spec "[!nhe46] common help option should be a hidden option." do
        schema_item = Benry::MicroRake::TaskOptionSchema::HELP_SCHEMA_ITEM
        ok {schema_item}.hidden?
      end

    end


    fixture :schema do
      Benry::MicroRake::TaskOptionSchema.new()
    end


    topic '#initialize()' do

      spec "[!526sc] option values should be converted when `convert: true` specified." do
        schema = Benry::MicroRake::TaskOptionSchema.new(convert: true)
        ok {schema}.should_convert_option_value?
        schema = Benry::MicroRake::TaskOptionSchema.new()
        ok {schema}.NOT.should_convert_option_value?
      end

      spec "[!jd8ia] enables help option automatically." do
        schema = Benry::MicroRake::TaskOptionSchema.new()
        ok {schema.get(:help)} != nil
      end

    end


    topic '.create_from()' do

      spec "[!qrw35] accepts a Proc object." do
        block = proc do |a, b=nil, x: nil, y: nil| nil end
        schema = Benry::MicroRake::TaskOptionSchema.create_from(block)
        ok {schema.get(:x)} != nil
        ok {schema.get(:y)} != nil
      end

      spec "[!1etq1] required and optional params are ignored." do
        block = proc do |a, b=nil, x: nil, y: nil| nil end
        schema = Benry::MicroRake::TaskOptionSchema.create_from(block)
        ok {schema.get(:a)} == nil
        ok {schema.get(:b)} == nil
      end

      spec "[!jrx0g] regards keyword param 'opt_<x>' as a short option with no args." do
        block = proc do |opt_x: nil| nil end
        schema = Benry::MicroRake::TaskOptionSchema.create_from(block)
        ok {schema.get(:opt_x).short} == "x"
        ok {schema.get(:opt_x).long} == nil
        ok {schema.get(:opt_x).arg_requireness} == :none   # !!!
      end

      spec "[!z0gee] regards keyword param 'opt_<x>_' as a short option with an arg." do
        block = proc do |opt_x_: nil| nil end
        schema = Benry::MicroRake::TaskOptionSchema.create_from(block)
        ok {schema.get(:opt_x_).short} == "x"
        ok {schema.get(:opt_x_).long} == nil
        ok {schema.get(:opt_x_).arg_requireness} == :required   # !!!
      end

      spec "[!m5qgk] regards keyword param as an arg-required long option when name ends with '_'." do
        block = proc do |lang_: nil| nil end
        schema = Benry::MicroRake::TaskOptionSchema.create_from(block)
        ok {schema.get(:lang_).short} == nil
        ok {schema.get(:lang_).long} == "lang"
        ok {schema.get(:lang_).arg_requireness} == :required   # !!!
      end

      spec "[!js2dl] regards keyword param as a normal long option when name doesn't end with '_'." do
        block = proc do |color: false| nil end
        schema = Benry::MicroRake::TaskOptionSchema.create_from(block)
        ok {schema.get(:color).short} == nil
        ok {schema.get(:color).long} == "color"
        ok {schema.get(:color).arg_requireness} == :none   # !!!
      end

      spec "[!akhrr] returns new schema object." do
        block = proc do |color: false| nil end
        schema = Benry::MicroRake::TaskOptionSchema.create_from(block)
        ok {schema}.is_a?(Benry::MicroRake::TaskOptionSchema)
      end

    end


    topic '#add_opt()' do

      spec "[!fkfds] regards `add_opt(..., :hidden)` as `add_opt(..., hidden: true)`." do
        |schema|
        schema.add_opt(:foo, "--foo", "foo option")
        schema.add_opt(:bar, "--bar", "bar option", :hidden, :important, :multiple)
        ok {schema.get(:foo)}.NOT.hidden?
        ok {schema.get(:foo).important?} == nil
        ok {schema.get(:foo)}.NOT.multiple?
        ok {schema.get(:bar)}.hidden?
        ok {schema.get(:bar)}.important?
        ok {schema.get(:bar)}.multiple?
      end

      spec "[!4j9jc] adds an option schema item." do
        |schema|
        schema.add_opt(:file, "-f, --file=<FILE>", "filename")
        ok {schema.get(:file).short} == "f"
        ok {schema.get(:file).long} == "file"
        ok {schema.get(:file).help} == "filename"
      end

    end


    topic '#opt_defined?()' do

      spec "[!e7wst] returns true if option defined, false if else." do
        |schema|
        schema.add_opt(:file, "-f, --file=<FILE>", "filename")
        ok {schema.opt_defined?(:file)} == true
        ok {schema.opt_defined?(:lang)} == false
      end

    end


    topic '#should_convert_option_value?()' do

      spec "[!0ec65] returns true if non-nil block passed to constructor." do
        schema = Benry::MicroRake::TaskOptionSchema.new(convert: true)
        ok {schema}.should_convert_option_value?
        schema = Benry::MicroRake::TaskOptionSchema.new(convert: false)
        ok {schema}.NOT.should_convert_option_value?
        schema = Benry::MicroRake::TaskOptionSchema.create_from(proc do end)
        ok {schema}.should_convert_option_value?
      end

    end


    topic '#_boolean_key?()' do

      spec "[!57tc3] returns true if key is :hidden, :important, or :multiple." do
        |schema|
        schema.instance_exec(self) do |_|
          _.ok {_boolean_key?(:hidden)}    == true
          _.ok {_boolean_key?(:important)} == true
          _.ok {_boolean_key?(:multiple)}  == true
          _.ok {_boolean_key?(:foobar)}    == false
        end
      end

    end


  end


end
