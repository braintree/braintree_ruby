# Portions of this code were copied and modified from Ruby on Rails, released
# under the MIT license, copyright (c) 2005-2009 David Heinemeier Hansson
module Braintree
  module Xml
    module Nokogiri
      NOKOGIRI_XML_LIMIT = 30000000

      def self.parse(xml_string)
        require "nokogiri" unless defined?(::Nokogiri)
        doc = ::Nokogiri::XML(xml_string.strip)
        _node_to_hash(doc.root)
      end

      def self._node_to_hash(node, hash = {})
        sub_hash = node.text? ? hash : _build_sub_hash(hash, node.name)

        if node.text? || (node.children.size == 1 && node.children.first.text?)
          content = node.text? ? node.content : node.children.first.content
          raise "Content too large" if content.length >= NOKOGIRI_XML_LIMIT
          sub_hash[CONTENT_ROOT] = content
          _attributes_to_hash(node, sub_hash) unless node.text?
        else
          _attributes_to_hash(node, sub_hash)
          if _array?(node)
            _children_array_to_hash(node, sub_hash)
          else
            _children_to_hash(node, sub_hash)
          end
        end
        hash
      end

      def self._build_sub_hash(hash, name)
        sub_hash = {}
        if hash[name]
          if !hash[name].kind_of? Array
            hash[name] = [hash[name]]
          end
          hash[name] << sub_hash
        else
          hash[name] = sub_hash
        end
        sub_hash
      end

      def self._children_to_hash(node, hash={})
        node.children.each { |child| _node_to_hash(child, hash) unless child.text? && child.content.strip.empty? }
        _attributes_to_hash(node, hash)
        hash
      end

      def self._attributes_to_hash(node, hash={})
        node.attributes.each { |name, attr| hash[name] = attr.value }
        hash
      end

      def self._children_array_to_hash(node, hash={})
        first_child = node.children.find { |child| !child.text? }
        hash[first_child.name] = node.children.select { |child| !child.text? }.map do |child|
          _children_to_hash(child, {})
        end
        hash
      end

      def self._array?(node)
        non_text_children = node.children.select { |child| !child.text? }
        non_text_children.size > 1 && non_text_children.first.name == non_text_children[1].name
      end
    end
  end
end
