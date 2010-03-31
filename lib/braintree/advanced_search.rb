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

    class MultipleValueNode < SearchNode
      def includes(*values)
        values.flatten!

        unless allowed_values.nil?
          bad_values = values - allowed_values
          raise ArgumentError.new("Invalid argument(s) for #{@node_name}: #{bad_values.join(", ")}") if bad_values.any?
        end

        @parent.add_criteria(@node_name, values)
      end

      def initialize(name, parent, options)
        super(name, parent)
        @options = options
      end

      def allowed_values
        @options[:allows]
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
