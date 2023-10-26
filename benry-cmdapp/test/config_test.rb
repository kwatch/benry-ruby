# -*- coding: utf-8 -*-
# frozen_string_literal: true


require 'oktest'

require 'benry/cmdapp'


Oktest.scope do


  topic Benry::CmdApp::Config do

    before do
      @config = Benry::CmdApp::Config.new("testapp", "1.2.3")
    end


    topic '#initialize()' do

      spec "[!pzp34] if `option_version` is not specified, then set true if `app_version` is provided." do
        c = Benry::CmdApp::Config.new("x", "1.0.0", option_version: nil)
        ok {c.option_version} == true
        c = Benry::CmdApp::Config.new("x",          option_version: nil)
        ok {c.option_version} == false
        #
        c = Benry::CmdApp::Config.new("x", "1.0.0", option_version: true)
        ok {c.option_version} == true
        c = Benry::CmdApp::Config.new("x",          option_version: true)
        ok {c.option_version} == true
        #
        c = Benry::CmdApp::Config.new("x", "1.0.0", option_version: false)
        ok {c.option_version} == false
        c = Benry::CmdApp::Config.new("x",          option_version: false)
        ok {c.option_version} == false
      end

    end


    topic '#each()' do

      spec "[!yxi7r] returns Enumerator object if block not given." do
        ok {@config.each()}.is_a?(Enumerator)
      end

      spec "[!64zkf] yields each config name and value." do
        d = {}
        @config.each do |k, v|
          ok {k}.is_a?(Symbol)
          d[k] = v
        end
        ok {d}.NOT.empty?
      end

      spec "[!0zatj] sorts key names if `sort: true` passed." do
        keys1 = []; keys2 = []
        @config.each {|k, v| keys1 << k }
        @config.each(sort: true) {|k, v| keys2 << k }
        ok {keys1} != keys2
        ok {keys1.sort} == keys2
      end

    end


  end


end
