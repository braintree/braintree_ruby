module Braintree
  class AdvancedSearch
    class SearchNode
      def self.operators(*operator_names)
        operator_names.each do |operator|
          define_method(operator) do |value|
            @parent.add_criteria(@node_name, operator => value.to_s)
          end
        end
      end

      def initialize(name, parent)
        @node_name, @parent = name, parent
      end
    end

    class EqualityNode < SearchNode
      operators :is, :is_not
    end

    class PartialMatchNode < EqualityNode
      operators :ends_with, :starts_with
    end

    class TextNode < PartialMatchNode
      operators :contains
    end

    class KeyValueNode < SearchNode
      def is(value)
        @parent.add_criteria(@node_name, value)
      end
    end

    class MultipleValueNode < SearchNode
      def in(*values)
        values.flatten!

        unless allowed_values.nil?
          bad_values = values - allowed_values
          raise ArgumentError.new("Invalid argument(s) for #{@node_name}: #{bad_values.join(", ")}") if bad_values.any?
        end

        @parent.add_criteria(@node_name, values)
      end

      def is(value)
        self.in(value)
      end

      def initialize(name, parent, options)
        super(name, parent)
        @options = options
      end

      def allowed_values
        @options[:allows]
      end
    end

    class RangeNode < SearchNode
      def between(min, max)
        self >= min
        self <= max
      end

      def >=(min)
        @parent.add_criteria(@node_name, :min => min)
      end

      def <=(max)
        @parent.add_criteria(@node_name, :max => max)
      end
    end

    def self.search_fields(*fields)
      _create_field_accessors(fields, TextNode)
    end

    def self.equality_fields(*fields)
      _create_field_accessors(fields, EqualityNode)
    end

    def self.partial_match_fields(*fields)
      _create_field_accessors(fields, PartialMatchNode)
    end

    def self.multiple_value_field(field, options={})
      define_method(field) do
        MultipleValueNode.new(field, self, options)
      end
    end

    def self.key_value_fields(*fields)
      _create_field_accessors(fields, KeyValueNode)
    end

    def self.range_fields(*fields)
      _create_field_accessors(fields, RangeNode)
    end

    def self.date_range_fields(*fields)
      _create_field_accessors(fields, DateRangeNode)
    end

    def self._create_field_accessors(fields, node_class)
      fields.each do |field|
        define_method(field) do |*args|
          raise "An operator is required" unless args.empty?
          node_class.new(field, self)
        end
      end
    end

    def initialize
      @criteria = {}
    end

    def add_criteria(key, value)
      if @criteria[key].is_a?(Hash)
        @criteria[key].merge!(value)
      else
        @criteria[key] = value
      end
    end

    def to_hash
      @criteria
    end
  end
end
