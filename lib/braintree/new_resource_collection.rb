module Braintree
  class NewResourceCollection
    include Enumerable

    def initialize(response, &block) # :nodoc:
      @ids = Util.extract_attribute_as_array(response[:search_results], :ids)
      @page_size = response[:search_results][:page_size]
      @paging_block = block
    end

    # Yields each item
    def each(&block)
      @ids.each_slice(@page_size) do |page_of_ids|
        resources = @paging_block.call(page_of_ids)
        resources.each(&block)
      end
    end

    def empty?
      @ids.empty?
    end

    # Returns the first item from the current page.
    def first
      @paging_block.call([@ids.first]).first
    end

    # The size of a resource collection is only approximate due to race conditions when pulling back results.  This method
    # should be avoided.
    def _approximate_size
      @ids.size
    end
  end
end
