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

    end


    topic '#color_mode?()' do

      spec "[!5ohdt] if `@color_mode` is set, returns it's value." do
        @config.color_mode = true
        ok {@config.color_mode?} == true
        @config.color_mode = false
        ok {@config.color_mode?} == false
      end

      spec "[!9dszi] if `@color_mode` is not set, returns true when stdout is a tty." do
        @config.color_mode = nil
        capture_sio(tty: true ) { ok {@config.color_mode?} == true  }
        capture_sio(tty: false) { ok {@config.color_mode?} == false }
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
