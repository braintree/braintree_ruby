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

    class TextNode < SearchNode
      operators :is, :is_not, :ends_with, :starts_with, :contains
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
        greater_than(min)
        less_than(max)
      end

      def greater_than(min)
        @parent.add_criteria(@node_name, :min => min)
      end

      def less_than(max)
        @parent.add_criteria(@node_name, :max => max)
      end
    end

    def self.search_fields(*fields)
      fields.each do |field|
        define_method(field) do
          TextNode.new(field, self)
        end
      end
    end

    def self.multiple_value_field(field, options={})
      define_method(field) do
        MultipleValueNode.new(field, self, options)
      end
    end

    def self.key_value_fields(*fields)
      fields.each do |field|
        define_method(field) do
          KeyValueNode.new(field, self)
        end
      end
    end

    def self.range_fields(*fields)
      fields.each do |field|
        define_method(field) do
          RangeNode.new(field, self)
        end
      end
    end

    def self.date_range_fields(*fields)
      fields.each do |field|
        define_method(field) do
          DateRangeNode.new(field, self)
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
