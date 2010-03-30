module Braintree
  class AdvancedSearch
    class SearchNode
      def self.operators(*names)
        names.each do |name|
          define_method(name) do |value|
            @parent.add_criteria(@name, name => value)
          end
        end
      end

      operators :is, :is_not, :ends_with, :starts_with, :contains

      def initialize(name, parent)
        @name, @parent = name, parent
      end
    end

    def self.search_fields(*fields)
      fields.each do |field|
        define_method(field) do
          SearchNode.new(field, self)
        end
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
