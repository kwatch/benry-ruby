# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative 'shared'


Oktest.scope do


  topic Benry::CmdApp::MetadataIndex do

    before do
      @index = Benry::CmdApp::MetadataIndex.new
    end


    topic '#metadata_add()' do

      spec "[!8bhxu] registers metadata with it's name as key." do
        metadata = Benry::CmdApp::INDEX.metadata_get("hello")
        ok {@index.metadata_get("hello")} == nil
        @index.metadata_add(metadata)
        ok {@index.metadata_get("hello")} == metadata
      end

      spec "[!k07kp] returns registered metadata objet." do
        metadata = Benry::CmdApp::INDEX.metadata_get("hello")
        ok {@index.metadata_add(metadata)} == metadata
      end

    end


    topic '#metadata_get()' do

      spec "[!l5m49] returns metadata object corresponding to name." do
        metadata = Benry::CmdApp::INDEX.metadata_get("hello")
        @index.metadata_add(metadata)
        ok {@index.metadata_get("hello")} == metadata
      end

      spec "[!rztk2] returns nil if metadata not found for the name." do
        ok {@index.metadata_get("hello")} == nil
      end

    end


    topic '#metadata_del()' do

      spec "[!69vo7] deletes metadata object corresponding to name." do
        metadata = Benry::CmdApp::INDEX.metadata_get("hello")
        @index.metadata_add(metadata)
        ok {@index.metadata_get("hello")} == metadata
        @index.metadata_del("hello")   # !!!
        ok {@index.metadata_get("hello")} == nil
      end

      spec "[!8vg6w] returns deleted metadata object." do
        metadata = Benry::CmdApp::INDEX.metadata_get("hello")
        @index.metadata_add(metadata)
        ok {@index.metadata_del("hello")} == metadata
      end

    end


    topic '#metadata_exist?()' do

      spec "[!0ck5n] returns true if metadata object registered." do
        metadata = Benry::CmdApp::INDEX.metadata_get("hello")
        @index.metadata_add(metadata)
        ok {@index.metadata_exist?("hello")} == true
      end

      spec "[!x7ziz] returns false if metadata object not registered." do
        ok {@index.metadata_exist?("hello")} == false
      end

    end


    topic '#metadata_each()' do

      spec "[!3l6r7] returns Enumerator object if block not given." do
        x = Benry::CmdApp::INDEX.metadata_each()
        ok {x}.is_a?(Enumerator)
      end

      spec "[!r8mb3] yields each metadata object if block given." do
        n = 0
        Benry::CmdApp::INDEX.metadata_each do |md|
          n += 1
          ok {md}.is_a?(Benry::CmdApp::BaseMetadata)
        end
        ok {n} > 0
      end

    end


    topic '#action_lookup()' do

      spec "[!lfd9z] returns action metadata even if alias name specified." do
        Benry::CmdApp.define_alias("a8323", "hello")
        at_end { Benry::CmdApp.undef_alias("a8323") }
        #
        md = Benry::CmdApp::INDEX.metadata_get("a8323")
        ok {md.name} == "a8323"
        ok {md}.is_a?(Benry::CmdApp::AliasMetadata)
        ok {md}.alias?
        #
        md = Benry::CmdApp::INDEX.action_lookup("a8323")   # !!!
        ok {md.name} == "hello"
        ok {md}.is_a?(Benry::CmdApp::ActionMetadata)
        ok {md}.NOT.alias?
      end

    end


  end


end
