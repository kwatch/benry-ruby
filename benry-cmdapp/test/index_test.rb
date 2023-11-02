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


    topic '#metadata_lookup()' do

      spec "[!dcs9v] looks up action metadata recursively if alias name specified." do
        Benry::CmdApp.define_alias("ali61", "hello")
        Benry::CmdApp.define_alias("ali62", "ali61")
        Benry::CmdApp.define_alias("ali63", "ali62")
        #
        hello_md = Benry::CmdApp::INDEX.metadata_get("hello")
        ok {hello_md}.is_a?(Benry::CmdApp::ActionMetadata)
        ok {hello_md.name} == "hello"
        #
        ok {Benry::CmdApp::INDEX.metadata_lookup("hello")} == [hello_md, []]
        ok {Benry::CmdApp::INDEX.metadata_lookup("ali61")} == [hello_md, []]
        ok {Benry::CmdApp::INDEX.metadata_lookup("ali62")} == [hello_md, []]
        ok {Benry::CmdApp::INDEX.metadata_lookup("ali63")} == [hello_md, []]
      end

      spec "[!f8fqx] returns action metadata and alias args." do
        Benry::CmdApp.define_alias("ali71", ["hello", "a"])
        Benry::CmdApp.define_alias("ali72", "ali71")
        Benry::CmdApp.define_alias("ali73", ["ali72", "b", "c"])
        #
        hello_md = Benry::CmdApp::INDEX.metadata_get("hello")
        ok {Benry::CmdApp::INDEX.metadata_lookup("hello")} == [hello_md, []]
        ok {Benry::CmdApp::INDEX.metadata_lookup("ali71")} == [hello_md, ["a"]]
        ok {Benry::CmdApp::INDEX.metadata_lookup("ali72")} == [hello_md, ["a"]]
        ok {Benry::CmdApp::INDEX.metadata_lookup("ali73")} == [hello_md, ["a", "b", "c"]]
      end

    end


    topic '#prefix_add()' do

      spec "[!k27in] registers prefix if not registered yet." do
        prefix = "p7885:"
        ok {@index.prefix_exist?(prefix)} == false
        @index.prefix_add(prefix, nil)
        ok {@index.prefix_exist?(prefix)} == true
        ok {@index.prefix_get_desc(prefix)} == nil
      end

      spec "[!xubc8] registers prefix whenever desc is not a nil." do
        prefix = "p8796:"
        @index.prefix_add(prefix, "some description")
        ok {@index.prefix_exist?(prefix)} == true
        ok {@index.prefix_get_desc(prefix)} == "some description"
        #
        @index.prefix_add(prefix, "other description")
        ok {@index.prefix_get_desc(prefix)} == "other description"
      end

    end


    topic '#prefix_add_via_action()' do

      spec "[!ztrfj] registers prefix of action." do
        @index.prefix_add_via_action("p5671:hello")
        ok {@index.prefix_exist?("p5671:")}   == true
        ok {@index.prefix_get_desc("p5671:")} == nil
        #
        @index.prefix_add_via_action("p5671:fo-o:ba_r:baz9:hello2")
        ok {@index.prefix_exist?("p5671:fo-o:ba_r:baz9:")} == true
        ok {@index.prefix_exist?("p5671:fo-o:ba_r:")}      == false
        ok {@index.prefix_exist?("p5671:fo-o:")}          == false
      end

      spec "[!31pik] do nothing if prefix already registered." do
        prefix = "p0620:hello"
        @index.prefix_add(prefix, "some desc")
        @index.prefix_add_via_action(prefix)
        ok {@index.prefix_get_desc(prefix)} == "some desc"
      end

      spec "[!oqq7j] do nothing if action has no prefix." do
        ok {@index.prefix_each().count()} == 0
        @index.prefix_add_via_action("a4049")
        ok {@index.prefix_each().count()} == 0
      end

    end


    topic '#prefix_each()' do

      spec "[!67r3i] returns Enumerator object if block not given." do
        ok {@index.prefix_each()}.is_a?(Enumerator)
      end

      spec "[!g3d1z] yields block with each prefix and desc." do
        @index.prefix_add("p2358:", nil)
        @index.prefix_add("p3892:", "some desc")
        d = {}
        @index.prefix_each() {|prefix, desc| d[prefix] = desc }
        ok {d} == {"p2358:" => nil, "p3892:" => "some desc"}
      end

    end


    topic '#prefix_exist?()' do

      spec "[!79cyx] returns true if prefix is already registered." do
        @index.prefix_add("p0057:", nil)
        ok {@index.prefix_exist?("p0057:")} == true
      end

      spec "[!jx7fk] returns false if prefix is not registered yet." do
        ok {@index.prefix_exist?("p0760:")} == false
      end

    end


    topic '#prefix_get_desc()' do

      spec "[!d47kq] returns description if prefix is registered." do
        Benry::CmdApp::INDEX.prefix_add("p5679", "bla bla")
        ok {Benry::CmdApp::INDEX.prefix_get_desc("p5679")} == "bla bla"
      end

      spec "[!otp1b] returns nil if prefix is not registered." do
        ok {Benry::CmdApp::INDEX.prefix_get_desc("p8233")} == nil
      end

    end


  end


end
