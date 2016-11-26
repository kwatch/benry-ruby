# -*- coding: utf-8 -*-

require 'psych'
require 'psych/visitors/to_ruby'


module Benry


  module YAMLUtil


    def self.load(yaml_string, classmap={})
      visitor = CustomClassVisitor.create(classmap)
      tree = Psych.parse(yaml_string)
      ydoc = visitor.accept(tree)
      return ydoc
    end


    class CustomClassVisitor < Psych::Visitors::ToRuby

      def self.create(classmap={})
        visitor = super()
        visitor.instance_variable_set('@classmap', classmap)
        return visitor
      end

      def initialize(*args)
        super
        @key_path = []   # ex: [] -> ['teams'] -> ['teams', 'members']
      end

      attr_reader :classmap

      def visit_Psych_Nodes_Mapping(o)
        tag = Psych.load_tags[o.tag]
        return revive(resolve_class(tag), o) if tag
        return revive_hash(register(o, empty_mapping(o)), o) unless o.tag
        return super
      end

      private

      def accept_key(kobj)
        key = accept(kobj)
        @key_path.push(key)
        return key
      end

      def accept_value(vobj)
        val = accept(vobj)
        @key_path.pop()
        return val
      end

      def empty_mapping(o)
        klass = @classmap[@key_path[-1]] || @classmap['*']
        return klass ? klass.new : {}
      end

      def revive_hash(hash, o)
        shovel = '<<'
        strtag = 'tag:yaml.org,2002:str'
        o.children.each_slice(2) do |kobj, vobj|
          k = accept_key(kobj)
          v = accept_value(vobj)
          if k == shovel && kobj.tag != strtag
            begin
              merge_mappings(hash, k, v, vobj)
            rescue TypeError
              hash[k] = v
            end
          else
            hash[k] = v
          end
        end
        return hash
      end

      def merge_mappings(hash, k, v, node)
        case node
        when Psych::Nodes::Alias, Psych::Nodes::Mapping
          merge_mapping(hash, v)
        when Psych::Nodes::Sequence
          h = {}
          v.reverse_each {|x| merge_mapping(h, x) }
          merge_mapping(hash, h)
        else
          hash[k] = v
        end
      end

      def merge_mapping(hash, other)
        if hash.is_a?(Hash) && other.is_a?(Hash)
          hash.merge!(other)
        else
          other.each {|k, v| hash[k] = v }
        end
      end

    end


  end


end
