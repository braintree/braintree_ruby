module Braintree
  class AdvancedSearch
    class SearchNode
      def self.operators(*operator_names)
        operator_names.each do |operator|
          define_method(operator) do |*values|
            @parent.add_criteria(@node_name, value_handler(operator, values))
          end
        end
      end

      def initialize(name, parent)
        @node_name, @parent = name, parent
      end
    end

    class TextNode < SearchNode
      operators :is, :is_not, :ends_with, :starts_with, :contains

      def value_handler(operator, values)
        {operator => values.first}
      end
    end

    class MultipleValueNode < SearchNode
      operators :includes

      def value_handler(operator, values)
        [*values].flatten
      end
    end

    def self.search_fields(*fields)
      fields.each do |field|
        define_method(field) do
          TextNode.new(field, self)
        end
      end
    end

    def self.multiple_value_field(field)
      define_method(field) do
        MultipleValueNode.new(field, self)
      end
    end

    def initialize
      @criteria = {}
    end

    def add_criteria(key, value)
      @criteria[key] = value
    end

    def to_hash
      @criteria
    end
  end
end
