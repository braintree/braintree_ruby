# Portions of this code were copied and modified from Ruby on Rails, released
# under the MIT license, copyright (c) 2005-2009 David Heinemeier Hansson
module Braintree
  module Xml # :nodoc:
    CONTENT_ROOT = "__content__"

    module Parser # :nodoc:
      XML_PARSING = {
        "datetime" => Proc.new { |time| ::Time.parse(time).utc },
        "integer"  => Proc.new { |integer| integer.to_i },
        "boolean"  => Proc.new { |boolean| %w(1 true).include?(boolean.strip) },
      }

      def self.hash_from_xml(xml, parser = _determine_parser)
        standardized_hash_structure = parser.parse(xml)
        transformed_xml = _transform_xml(standardized_hash_structure)
        Util.symbolize_keys(transformed_xml)
      end

      def self._determine_parser
        # If LibXML is not available, we fall back to REXML
        # This allows us to be compatible with JRuby, which LibXML does not support
        if defined?(::LibXML::XML) && ::LibXML::XML.respond_to?(:default_keep_blanks=)
          ::Braintree::Xml::Libxml
        else
          ::Braintree::Xml::Rexml
        end
      end

      # Transform into standard Ruby types and convert all keys to snake_case instead of dash-case
      def self._transform_xml(value)
        case value.class.to_s
          when "Hash"
            if value["type"] == "array"
              child_key, entries = value.detect { |k,v| k != "type" }   # child_key is throwaway
              if entries.nil? || ((c = value[CONTENT_ROOT]) && c.strip.empty?)
                []
              else
                case entries.class.to_s   # something weird with classes not matching here.  maybe singleton methods breaking is_a?
                when "Array"
                  entries.collect { |v| _transform_xml(v) }
                when "Hash"
                  [_transform_xml(entries)]
                else
                  raise "can't typecast #{entries.inspect}"
                end
              end
            elsif value.has_key?(CONTENT_ROOT)
              content = value[CONTENT_ROOT]
              if (parser = XML_PARSING[value["type"]])
                XML_PARSING[value["type"]].call(content)
              else
                content
              end
            elsif value["type"] == "string" && value["nil"] != "true"
              ""
            elsif value == {}
              ""
            elsif value.nil? || value["nil"] == "true"
              nil
            # If the type is the only element which makes it then
            # this still makes the value nil, except if type is
            # a XML node(where type['value'] is a Hash)
            elsif value["type"] && value.size == 1 && !value["type"].is_a?(::Hash)
              raise "is this needed?"
              nil
            else
              xml_value = value.inject({}) do |h,(k,v)|
                h[k.to_s.tr("-", "_")] = _transform_xml(v) # convert dashes to underscores in keys
                h
              end
              xml_value
            end
          when "Array"
            value.map! { |i| _transform_xml(i) }
            case value.length
              when 0 then nil
              when 1 then value.first
              else value
            end
          when "String"
            value
          else
            raise "can't transform #{value.class.name} - #{value.inspect}"
        end
      end
    end
  end
end
