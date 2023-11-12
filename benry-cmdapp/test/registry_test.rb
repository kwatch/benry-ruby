# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative 'shared'


Oktest.scope do


  topic Benry::CmdApp::Registry do

    def new_registry_with_filter(*categories)
      idx = Benry::CmdApp::Registry.new()
      Benry::CmdApp::REGISTRY.metadata_each do |md|
        idx.metadata_add(md) if md.name.start_with?(*categories)
      end
      return idx
    end

    before do
      @registry = Benry::CmdApp::Registry.new
    end


    topic '#metadata_add()' do

      spec "[!8bhxu] registers metadata with it's name as key." do
        metadata = Benry::CmdApp::REGISTRY.metadata_get("hello")
        ok {@registry.metadata_get("hello")} == nil
        @registry.metadata_add(metadata)
        ok {@registry.metadata_get("hello")} == metadata
      end

      spec "[!k07kp] returns registered metadata objet." do
        metadata = Benry::CmdApp::REGISTRY.metadata_get("hello")
        ok {@registry.metadata_add(metadata)} == metadata
      end

    end


    topic '#metadata_get()' do

      spec "[!l5m49] returns metadata object corresponding to name." do
        metadata = Benry::CmdApp::REGISTRY.metadata_get("hello")
        @registry.metadata_add(metadata)
        ok {@registry.metadata_get("hello")} == metadata
      end

      spec "[!rztk2] returns nil if metadata not found for the name." do
        ok {@registry.metadata_get("hello")} == nil
      end

    end


    topic '#metadata_del()' do

      spec "[!69vo7] deletes metadata object corresponding to name." do
        metadata = Benry::CmdApp::REGISTRY.metadata_get("hello")
        @registry.metadata_add(metadata)
        ok {@registry.metadata_get("hello")} == metadata
        @registry.metadata_del("hello")   # !!!
        ok {@registry.metadata_get("hello")} == nil
      end

      spec "[!8vg6w] returns deleted metadata object." do
        metadata = Benry::CmdApp::REGISTRY.metadata_get("hello")
        @registry.metadata_add(metadata)
        ok {@registry.metadata_del("hello")} == metadata
      end

    end


    topic '#metadata_exist?()' do

      spec "[!0ck5n] returns true if metadata object registered." do
        metadata = Benry::CmdApp::REGISTRY.metadata_get("hello")
        @registry.metadata_add(metadata)
        ok {@registry.metadata_exist?("hello")} == true
      end

      spec "[!x7ziz] returns false if metadata object not registered." do
        ok {@registry.metadata_exist?("hello")} == false
      end

    end


    topic '#metadata_each()' do

      spec "[!3l6r7] returns Enumerator object if block not given." do
        x = Benry::CmdApp::REGISTRY.metadata_each()
        ok {x}.is_a?(Enumerator)
      end

      spec "[!r8mb3] yields each metadata object if block given." do
        n = 0
        Benry::CmdApp::REGISTRY.metadata_each do |md|
          n += 1
          ok {md}.is_a?(Benry::CmdApp::BaseMetadata)
        end
        ok {n} > 0
      end

      spec "[!qvc77] ignores hidden metadata if `all: false` passed." do
        found = false
        Benry::CmdApp::REGISTRY.metadata_each(all: false) {|md| found = true if md.hidden? }
        ok {found} == false
        #
        found = false
        Benry::CmdApp::REGISTRY.metadata_each {|md| found = true if md.hidden? }
        ok {found} == true
      end

    end


    topic '#metadata_lookup()' do

      spec "[!dcs9v] looks up action metadata recursively if alias name specified." do
        Benry::CmdApp.define_alias("ali61", "hello")
        Benry::CmdApp.define_alias!("ali62", "ali61")
        Benry::CmdApp.define_alias!("ali63", "ali62")
        #
        hello_md = Benry::CmdApp::REGISTRY.metadata_get("hello")
        ok {hello_md}.is_a?(Benry::CmdApp::ActionMetadata)
        ok {hello_md.name} == "hello"
        #
        ok {Benry::CmdApp::REGISTRY.metadata_lookup("hello")} == [hello_md, []]
        ok {Benry::CmdApp::REGISTRY.metadata_lookup("ali61")} == [hello_md, []]
        ok {Benry::CmdApp::REGISTRY.metadata_lookup("ali62")} == [hello_md, []]
        ok {Benry::CmdApp::REGISTRY.metadata_lookup("ali63")} == [hello_md, []]
      end

      spec "[!f8fqx] returns action metadata and alias args." do
        Benry::CmdApp.define_alias("ali71", ["hello", "a"])
        Benry::CmdApp.define_alias!("ali72", "ali71")
        Benry::CmdApp.define_alias!("ali73", ["ali72", "b", "c"])
        #
        hello_md = Benry::CmdApp::REGISTRY.metadata_get("hello")
        ok {Benry::CmdApp::REGISTRY.metadata_lookup("hello")} == [hello_md, []]
        ok {Benry::CmdApp::REGISTRY.metadata_lookup("ali71")} == [hello_md, ["a"]]
        ok {Benry::CmdApp::REGISTRY.metadata_lookup("ali72")} == [hello_md, ["a"]]
        ok {Benry::CmdApp::REGISTRY.metadata_lookup("ali73")} == [hello_md, ["a", "b", "c"]]
      end

    end


    topic '#prefix_add()' do

      spec "[!k27in] registers prefix if not registered yet." do
        prefix = "p7885:"
        ok {@registry.prefix_exist?(prefix)} == false
        @registry.prefix_add(prefix, nil)
        ok {@registry.prefix_exist?(prefix)} == true
        ok {@registry.prefix_get_desc(prefix)} == nil
      end

      spec "[!xubc8] registers prefix whenever desc is not a nil." do
        prefix = "p8796:"
        @registry.prefix_add(prefix, "some description")
        ok {@registry.prefix_exist?(prefix)} == true
        ok {@registry.prefix_get_desc(prefix)} == "some description"
        #
        @registry.prefix_add(prefix, "other description")
        ok {@registry.prefix_get_desc(prefix)} == "other description"
      end

    end


    topic '#prefix_add_via_action()' do

      spec "[!ztrfj] registers prefix of action." do
        @registry.prefix_add_via_action("p5671:hello")
        ok {@registry.prefix_exist?("p5671:")}   == true
        ok {@registry.prefix_get_desc("p5671:")} == nil
        #
        @registry.prefix_add_via_action("p5671:fo-o:ba_r:baz9:hello2")
        ok {@registry.prefix_exist?("p5671:fo-o:ba_r:baz9:")} == true
        ok {@registry.prefix_exist?("p5671:fo-o:ba_r:")}      == false
        ok {@registry.prefix_exist?("p5671:fo-o:")}          == false
      end

      spec "[!31pik] do nothing if prefix already registered." do
        prefix = "p0620:hello"
        @registry.prefix_add(prefix, "some desc")
        @registry.prefix_add_via_action(prefix)
        ok {@registry.prefix_get_desc(prefix)} == "some desc"
      end

      spec "[!oqq7j] do nothing if action has no prefix." do
        ok {@registry.prefix_each().count()} == 0
        @registry.prefix_add_via_action("a4049")
        ok {@registry.prefix_each().count()} == 0
      end

    end


    topic '#prefix_each()' do

      spec "[!67r3i] returns Enumerator object if block not given." do
        ok {@registry.prefix_each()}.is_a?(Enumerator)
      end

      spec "[!g3d1z] yields block with each prefix and desc." do
        @registry.prefix_add("p2358:", nil)
        @registry.prefix_add("p3892:", "some desc")
        d = {}
        @registry.prefix_each() {|prefix, desc| d[prefix] = desc }
        ok {d} == {"p2358:" => nil, "p3892:" => "some desc"}
      end

    end


    topic '#prefix_exist?()' do

      spec "[!79cyx] returns true if prefix is already registered." do
        @registry.prefix_add("p0057:", nil)
        ok {@registry.prefix_exist?("p0057:")} == true
      end

      spec "[!jx7fk] returns false if prefix is not registered yet." do
        ok {@registry.prefix_exist?("p0760:")} == false
      end

    end


    topic '#prefix_get_desc()' do

      spec "[!d47kq] returns description if prefix is registered." do
        Benry::CmdApp::REGISTRY.prefix_add("p5679", "bla bla")
        ok {Benry::CmdApp::REGISTRY.prefix_get_desc("p5679")} == "bla bla"
      end

      spec "[!otp1b] returns nil if prefix is not registered." do
        ok {Benry::CmdApp::REGISTRY.prefix_get_desc("p8233")} == nil
      end

    end


    topic '#prefix_count_actions()' do

      spec "[!8wipx] includes prefix of hidden actions if `all: true` passed." do
        idx = new_registry_with_filter("giit:", "md:")
        ok {idx.prefix_count_actions(1, all: true) }.key?("md:")
        ok {idx.prefix_count_actions(1, all: false)}.NOT.key?("md:")
      end

      spec "[!5n3qj] counts prefix of specified depth." do
        idx = new_registry_with_filter("giit:", "md:")
        expected1 = {"giit:"=>13}
        expected2 = {"giit:branch:"=>2, "giit:"=>0, "giit:commit:"=>1,
                     "giit:repo:"=>7,
                     "giit:staging:"=>3}
        expected3 = {"giit:branch:"=>2, "giit:"=>0, "giit:commit:"=>1,
                     "giit:repo:config:"=>3, "giit:repo:"=>2, "giit:repo:remote:"=>2,
                     "giit:staging:"=>3}
        ok {idx.prefix_count_actions(1)} == expected1
        ok {idx.prefix_count_actions(2)} == expected2
        ok {idx.prefix_count_actions(3)} == expected3
        ok {idx.prefix_count_actions(4)} == expected3
        ok {idx.prefix_count_actions(5)} == expected3
      end

      spec "[!r2frb] counts prefix of lesser depth." do
        idx = new_registry_with_filter("giit:", "md:")
        x = idx.prefix_count_actions(1)
        ok {x}.key?("giit:")
        ok {x}.NOT.key?("giit:branch:")
        ok {x}.NOT.key?("giit:repo:config:")
        x = idx.prefix_count_actions(2)
        ok {x}.key?("giit:")
        ok {x}.key?("giit:branch:")
        ok {x}.NOT.key?("giit:repo:config:")
        x = idx.prefix_count_actions(3)
        ok {x}.key?("giit:")
        ok {x}.key?("giit:branch:")
        ok {x}.key?("giit:repo:config:")
      end

    end


    topic '#abbrev_add()' do

      spec "[!n475k] registers abbrev with prefix." do
        @registry.abbrev_add("g:", "git:")
        ok {@registry.abbrev_exist?("g:")} == true
        ok {@registry.abbrev_get_prefix("g:")} == "git:"
      end

    end


    topic '#abbrev_get_prefix()' do

      spec "[!h1dvb] returns prefix bound to abbrev." do
        @registry.abbrev_add("g:", "git:")
        ok {@registry.abbrev_get_prefix("g:")} == "git:"
      end

    end


    topic '#abbrev_exist?()' do

      spec "[!tjbdy] returns true/false if abbrev registered or not." do
        ok {@registry.abbrev_exist?("g:")} == false
        @registry.abbrev_add("g:", "git:")
        ok {@registry.abbrev_exist?("g:")} == true
      end

    end


    topic '#abbrev_each()' do

      spec "[!2oo4o] yields each abbrev name and prefix." do
        @registry.abbrev_add("g1:", "git:")
        @registry.abbrev_add("g2:", "git:")
        arr = []
        @registry.abbrev_each do |*args|
          arr << args
        end
        ok {arr} == [["g1:", "git:"], ["g2:", "git:"]]
      end

    end


    topic '#abbrev_resolve()' do

      spec "[!n7zsy] replaces abbrev in action name with prefix." do
        @registry.abbrev_add("g:", "git:")
        ok {@registry.abbrev_resolve("g:stage")} == "git:stage"
      end

      spec "[!kdi3o] returns nil if abbrev not found in action name." do
        @registry.abbrev_add("g:", "git:")
        ok {@registry.abbrev_resolve("gi:stage")} == nil
        ok {@registry.abbrev_resolve("h:stage")}  == nil
        ok {@registry.abbrev_resolve("gitstage")} == nil
      end

    end


  end


end
