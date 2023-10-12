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
        @idx_path = []   # ex: [] -> ['teams'] -> ['teams', 0] -> ['teams', 0, 'members']
      end

      attr_reader :classmap

      def visit_Psych_Nodes_Mapping(o)
        tag = Psych.load_tags[o.tag]
        return revive(resolve_class(tag), o) if tag
        return revive_hash(register(o, empty_mapping(o)), o) unless o.tag
        return super
      end

      def visit_Psych_Nodes_Alias(o)
        @st.fetch(o.anchor) {
          lazy_alias = LazyAlias.new(o.anchor, @idx_path.dup)
          (@lazy_aliases ||= []) << lazy_alias
          lazy_alias
        }
      end

      def visit_Psych_Nodes_Document(o)
        ydoc = super
        @lazy_aliases.each do |a|
          val = @st.fetch(a.name) { raise Psych::BadAlias, "Unknown alias: #{a.name}" }
          a.replace_self(ydoc, val)
        end if @lazy_aliases
        ydoc
      end

      private

      def accept_key(kobj)
        key = accept(kobj)
        @key_path.push(key)
        @idx_path.push(key)
        return key
      end

      def accept_value(vobj)
        val = accept(vobj)
        @key_path.pop()
        @idx_path.pop()
        return val
      end

      def register_empty(o)
        list = register(o, [])
        path = @idx_path
        path.push(nil)          # push dummy
        o.children.each_with_index do |c, i|
          path[-1] = i          # push index
          list << accept(c)
        end
        path.pop()              # pop index
        return list
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


    class LazyAlias    # :nodoc:

      def initialize(name, key_path)
        @name     = name
        @key_path = key_path
      end

      attr_reader :name, :key_path

      def replace_self(root, value)
        d = root
        @key_path[0..-2].each {|k| d = d[k] }
        d[@key_path[-1]] = value
      end

      def each   # called from Visitor#merge_mapping()
        raise Psych::BadAlias, "Anchor '&#{@name}' should appear before '<<: *#{@name}'"
      end

    end


  end


end
