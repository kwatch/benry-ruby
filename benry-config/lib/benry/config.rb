# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


module Benry


  class ConfigError < StandardError
  end


  ##
  ## Configuration class.
  ##
  ## ex:
  ##
  ##     #----- config/common.rb -----
  ##     require 'benry/config'
  ##     class CommonConfig < Benry::BaseConfig
  ##       add :db_user            , "user1"
  ##       add :db_pass            , ABSTRACT
  ##       add :session_cooie      , "SESS"
  ##       add :session_secret     , SECRET
  ##       add :env                , ABSTRACT['RACK_ENV']
  ##     end
  ##
  ##     #----- config/development.rb -----
  ##     require 'config/common'
  ##     class Config < CommonConfig
  ##       set :db_pass            , "pass1"
  ##     end
  ##
  ##     #----- config/development.private -----
  ##     class Config
  ##       set :session_secret     , "YRjCIAiPlCBvwLUq5mnZ"
  ##     end
  ##
  ##     #----- main.rb -----
  ##     rack_env = ENV['RACK_ENV']  or raise "$RACK_ENV required."
  ##     require "./config/#{rack_env}.rb"
  ##     load    "./config/#{rack_env}.private"
  ##     #
  ##     $config = Config.new.freeze
  ##     #
  ##     p $config.db_user             #=> "user1"
  ##     p $config.db_pass             #=> "pass1"
  ##     p $config.session_cookie      #=> "SESS"
  ##     p $config.session_secret      #=> "abc123"
  ##     p $config.env                 #=> "development" or "production" or "staging"
  ##     #
  ##     p $config.get_all(:db_)       #=> {:user=>"user1", :pass=>"pass1"}
  ##     p $config.get_all(:session_)  #=> {:cookie=>"SESS", :secret=>"YRjCIAiPlCBvwLUq5mnZ"}
  ##
  class BaseConfig

    class AbstractValue

      def initialize(envvar=nil)
        #; [!6hcf9] accepts environment variable name.
        @envvar = envvar
      end

      attr_reader :envvar

      def [](envvar)
        #; [!p0acp] returns new object with environment variable name.
        return self.class.new(envvar)
      end

    end

    class SecretValue < AbstractValue
    end

    ABSTRACT = AbstractValue.new  # represents 'should be set in subclass'
    SECRET   = SecretValue.new    # represents 'should be set in private config file'

    def initialize
      #; [!7rdq4] traverses parent class and gathers config values.
      _traverse(self.class) {|k, v| instance_variable_set("@#{k}", v) }
      instance_variables().each do |ivar|
        val = instance_variable_get(ivar)
        next unless val.is_a?(AbstractValue)
        #; [!v9f3k] when envvar name not specified...
        if val.envvar == nil
          #; [!z9mno] raises ConfigError if ABSTRACT or SECRET is not overriden.
          raise ConfigError.new("config ':#{ivar.to_s[1..-1]}' should be set, but not.")
        #; [!ida3r] when envvar name specified...
        else
          #; [!txl88] raises ConfigError when envvar not set.
          envvar = val.envvar
          begin
            val = ENV.fetch(envvar.to_s)
          rescue KeyError
            raise ConfigError.new("environment variable '$#{envvar}' should be set for config item ':#{ivar.to_s[1..-1]}'.")
          end
          #; [!y47ul] sets envvar value as config value if envvar provided.
          instance_variable_set(ivar, val)
        end
      end
    end

    def _traverse(cls, &b)
      _traverse(cls.superclass, &b) if cls.superclass && cls.superclass < BaseConfig
      dict = cls.instance_variable_get(:@__dict)
      dict.each(&b) if dict
    end
    private :_traverse

    ## Add new config. Raises ConfigError when already defined.
    def self.add(key, value, desc=nil)
      #; [!m7w96] raises ConfigError when already added.
      ! self.method_defined?(key)  or
        raise ConfigError.new("add #{key.inspect} : already defined (use set() instead).")
      #; [!s620t] adds new key and value.
      (@__dict ||= {})[key] = value
      #; [!o0ts4] defines getter method.
      attr_reader key
      value
    end

    ## Set existing config. Raises ConfigError when key not defined.
    def self.set(key, value, desc=nil)
      #; [!fxc4h] raises ConfigError when not defined yet.
      self.method_defined?(key)  or
        raise ConfigError.new("set #{key.inspect} : not defined (use add() instead).")
      #; [!cv8iz] overrides existing value.
      (@__dict ||= {})[key] = value
      value
    end

    ## Add or set config. Raises nothing whether defined or not.
    def self.put(key, value, desc=nil)
      #; [!abd3f] raises nothing whener defined or not.
      #; [!gu2f0] sets key and value.
      (@__dict ||= {})[key] = value
      #; [!84kbr] defines getter method.
      attr_reader key
      value
    end

    ## Return config value.
    def [](key)
      #; [!z9r30] returns config value.
      return self.__send__(key)
    end

    ## Gathers related configs starting with prefix specified.
    def get_all(prefix_key)
      #; [!85z23] gathers configs which name starts with specified prefix.
      prefix = "@#{prefix_key}"
      symbol_p = prefix_key.is_a?(Symbol)
      range = prefix.length..-1
      d = {}
      self.instance_variables.each do |ivar|
        if ivar.to_s.start_with?(prefix)
          val = self.instance_variable_get(ivar)
          key = ivar[range]
          #; [!b72fr] if prefix is a string, then keys returend will also be string.
          key = key.intern if symbol_p
          d[key] = val
        end
      end
      return d
    end

  end


end
