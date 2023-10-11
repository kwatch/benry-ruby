# -*- coding: utf-8 -*-

require 'oktest'

require 'benry/config'




class TestCommonConfig < Benry::Config
  add :db_name            , "db1"
  add :db_user            , "user1"
  add :db_pass            , ABSTRACT
  add :session_secret     , SECRET
end

class TestConfig < TestCommonConfig
  set :db_pass            , "pass1"
  set :session_secret     , "abc123"
end

class TestConfig2 < TestCommonConfig
  #set :db_pass            , "pass1"
  set :session_secret     , "abc123"
end

class TestConfig3 < TestCommonConfig
  set :db_pass            , "pass1"
  #set :session_secret     , "abc123"
end

class TestConfig4 < TestCommonConfig
  set :db_pass            , ABSTRACT['DBPASS']
  set :session_secret     , ABSTRACT['SESS_SECRET']
end



Oktest.scope do


  topic Benry::Config::AbstractValue do


    topic '#initialize()' do

      spec "[!6hcf9] accepts environment variable name." do
        v = Benry::Config::AbstractValue.new(:FOO)
        ok {v.envvar} == :FOO
      end

    end


    topic '#[]' do

      spec "[!p0acp] returns new object with environment variable name." do
        foo = Benry::Config::ABSTRACT[:FOO]
        ok {foo.class} == Benry::Config::AbstractValue
        ok {foo.envvar} == :FOO
        #
        bar = Benry::Config::SECRET[:BAR]
        ok {bar.class} == Benry::Config::SecretValue
        ok {bar.envvar} == :BAR
      end
    end


  end



  topic Benry::Config do


    topic '#initialize()' do

      spec "[!7rdq4] traverses parent class and gathers config values." do
        config = TestConfig.new
        ok {config.db_name} == "db1"
        ok {config.db_user} == "user1"
        ok {config.db_pass} == "pass1"
        ok {config.session_secret} == "abc123"
      end

      case_when "[!v9f3k] when envvar name not specified..." do

        spec "[!z9mno] raises ConfigError if ABSTRACT or SECRET is not overriden." do
          pr = proc { TestConfig2.new }
          ok {pr}.raise?(Benry::ConfigError,
                         "config ':db_pass' should be set, but not.")
          #
          pr = proc { TestConfig3.new }
          ok {pr}.raise?(Benry::ConfigError,
                         "config ':session_secret' should be set, but not.")
        end

      end

      case_when "[!ida3r] when envvar name specified..." do

        spec "[!txl88] raises ConfigError when envvar not set." do
          ENV['DBPASS'] = nil
          ENV['SESS_SECRET'] = nil
          pr = proc { TestConfig4.new }
          ok {pr}.raise?(Benry::ConfigError,
                         "environment variable '$DBPASS' should be set for config item ':db_pass'.")
          #
          ENV['DBPASS'] = "pass1"
          pr = proc { TestConfig4.new }
          ok {pr}.raise?(Benry::ConfigError,
                         "environment variable '$SESS_SECRET' should be set for config item ':session_secret'.")
        end

        spec "[!y47ul] sets envvar value as config value if envvar provided." do
          ENV['DBPASS']      = "<PASS>"
          ENV['SESS_SECRET'] = "<SECRETVALUE>"
          conf = TestConfig4.new
          ok {conf.db_pass}        == "<PASS>"
          ok {conf.session_secret} == "<SECRETVALUE>"
        end

      end

    end


    topic '.add()' do

      spec "[!m7w96] raises ConfigError when already added." do
        pr = proc do
          TestCommonConfig.class_eval do
            add :db_name,  "db9"
          end
        end
        ok {pr}.raise?(Benry::ConfigError,
                       "add :db_name : already defined (use set() instead).")
      end

      spec "[!s620t] adds new key and value." do
        ok {TestCommonConfig.instance_variable_get('@__dict')} == {
          :db_name        => "db1",
          :db_user        => "user1",
          :db_pass        => Benry::Config::ABSTRACT,
          :session_secret => Benry::Config::SECRET,
        }
      end

      spec "[!o0ts4] defines getter method." do
        cls = Class.new(Benry::Config) do
          add :foo  , "FOO"
        end
        obj = cls.new
        ok {obj}.respond_to?(:foo)
        ok {obj.foo} == "FOO"
      end

    end


    topic '.set()' do

      spec "[!fxc4h] raises ConfigError when not defined yet." do
        pr = proc do
          TestCommonConfig.class_eval do
            set :db_port,  5432
          end
        end
        ok {pr}.raise?(Benry::ConfigError,
                       "set :db_port : not defined (use add() instead).")
      end

      spec "[!cv8iz] overrides existing value." do
        ok {TestConfig.instance_variable_get('@__dict')} == {
          :db_pass        => "pass1",
          :session_secret => "abc123",
        }
        #
        config = TestConfig.new
        ok {config.db_pass} == "pass1"
        ok {config.session_secret} == "abc123"
      end

    end


    topic '.put()' do

      spec "[!abd3f] raises nothing whener defined or not." do
        pr = proc do
          Class.new(TestCommonConfig) do
            put :db_name    , "db9"      # existing
            put :db_port    , "5432"     # not existing
          end
        end
        ok {pr}.NOT.raise?(Exception)
      end

      spec "[!gu2f0] sets key and value." do
        cls = Class.new(TestCommonConfig) do
          put :db_name    , "db9"     # existing
          put :db_port    , 5432      # not existing
        end
        ok {cls.instance_variable_get('@__dict')} == {
          :db_name   => "db9",
          :db_port   => 5432,
        }
      end

      spec "[!84kbr] defines getter method." do
        cls = Class.new(TestCommonConfig) do
          put :db_name    , "db9"     # existing
          put :db_port    , 5432      # not existing
        end
        ok {cls}.method_defined?(:db_name)
        ok {cls}.method_defined?(:db_port)
      end

    end


    topic '#[]' do

      spec "[!z9r30] returns config value." do
        config = TestConfig.new()
        ok {config[:db_user]} == "user1"
        ok {config[:db_pass]} == "pass1"
      end

    end


    topic '#get_all()' do

      spec "[!85z23] gathers configs which name starts with specified prefix." do
        config = TestConfig.new()
        ok {config.get_all(:db_)} == {:name=>"db1", :user=>"user1", :pass=>"pass1"}
      end

      spec "[!b72fr] if prefix is a string, then keys returend will also be string." do
        config = TestConfig.new()
        ok {config.get_all("db_")} == {"name"=>"db1", "user"=>"user1", "pass"=>"pass1"}
      end

    end


    topic '#defined?()' do

      spec "[!y1fsh] returns true if config key defined." do
        conf = TestConfig.new()
        ok {conf.defined?(:db_pass)} == true
      end

      spec "[!k1b5q] returns false if config key not defined." do
        conf = TestConfig.new()
        ok {conf.defined?(:db_password)} == false
      end

    end


    topic '#each()' do

      spec "[!f4ljv] returns Enumerator object if block not given." do
        conf = TestConfig.new
        ok {conf.each}.is_a?(Enumerator)
      end

      spec "[!4wqpu] yields each key and val with hiding secret values." do
        conf = TestConfig.new
        d = {}
        conf.each {|k, v| d[k] = v }
        ok {d} == {:db_name=>"db1", :db_user=>"user1", :db_pass=>"pass1",
                   :session_secret=>"(secret)"}  # !!!
      end

      spec "[!a9glw] sorts keys if 'true' specified as the first argument." do
        conf = TestConfig.new
        keys1 = []
        conf.each {|k, v| keys1 << k }
        keys2 = []
        conf.each(true) {|k, v| keys2 << k }
        ok {keys1} == [:db_name, :db_user, :db_pass, :session_secret]
        ok {keys2} == [:db_name, :db_pass, :db_user, :session_secret]
      end

      spec "[!wggik] returns self if block given." do
        conf = TestConfig.new
        ok {conf.each {|k, v| nil }}.same?(conf)
      end

    end


    topic '#each!()' do

      spec "[!zd9lk] returns Enumerator object if block not given." do
        conf = TestConfig.new
        ok {conf.each!}.is_a?(Enumerator)
      end

      spec "[!7i5p2] yields each key and val without hiding secret values." do
        conf = TestConfig.new
        d = {}
        conf.each! {|k, v| d[k] = v }
        ok {d} == {:db_name=>"db1", :db_user=>"user1", :db_pass=>"pass1",
                   :session_secret=>"abc123"}  # !!!
      end

      spec "[!aib7c] sorts keys if 'true' specified as the first argument." do
        conf = TestConfig.new
        keys1 = []
        conf.each! {|k, v| keys1 << k }
        keys2 = []
        conf.each(true) {|k, v| keys2 << k }
        ok {keys1} == [:db_name, :db_user, :db_pass, :session_secret]
        ok {keys2} == [:db_name, :db_pass, :db_user, :session_secret]
      end

      spec "[!2abgb] returns self if block given." do
        conf = TestConfig.new
        ok {conf.each! {|k, v| nil }}.same?(conf)
      end

    end


    topic '#_each()' do

      spec "[!6yvgd] sorts keys if 'sort' is true." do
        keys1 = []
        keys2 = []
        TestConfig.new.instance_eval do
          _each(false, false) {|k, v| keys1 << k }
          _each(true, false)  {|k, v| keys2 << k }
        end
        ok {keys1} == [:db_name, :db_user, :db_pass, :session_secret]
        ok {keys2} == [:db_name, :db_pass, :db_user, :session_secret]
      end

      spec "[!5ledb] hides value if 'hide_secret' is true and value is Secretvalue object." do
        d1 = {}
        d2 = {}
        TestConfig.new.instance_eval do
          _each(false, true ) {|k, v| d1[k] = v }
          _each(false, false) {|k, v| d2[k] = v }
        end
        ok {d1[:session_secret]} == "(secret)"
        ok {d2[:session_secret]} == "abc123"
      end

    end


  end


end
