module Braintree
  class ResourceCollection
    include BaseModule
    include Enumerable

    def initialize(attributes, &block) # :nodoc:
      set_instance_variables_from_hash attributes
      @paging_block = block
    end

    # Yields each item on the current page.
    def each(&block)
      @items.each(&block)

      _next_page.each(&block) unless _last_page?
    end

    def empty?
      @items.empty?
    end

    # Returns the first item from the current page.
    def first
      @items.first
    end

    # Returns true if the page is the last page. False otherwise.
    def _last_page?
      @current_page_number == _total_pages
    end

    # Retrieves the next page of records.
    def _next_page
      if _last_page?
        return nil
      end
      @paging_block.call(@current_page_number + 1)
    end

    # The size of a resource collection is only approximate due to race conditions when pulling back results.  This method
    # should be avoided.
    def _approximate_size
      @total_items
    end

    # Returns the total number of pages.
    def _total_pages
      total = @total_items / @page_size
      if @total_items % @page_size != 0
        total += 1
      end
      total
    end
  end
end
