module Braintree
  class PagedCollection
    include BaseModule
    include Enumerable
    
    attr_reader :current_page_number, :items, :next_page_number, :page_size, :previous_page_number, :total_items
    
    def initialize(attributes, &block) # :nodoc:
      set_instance_variables_from_hash attributes
      @paging_block = block
    end

    # Returns the item from the current page at the given +index+.
    def [](index)
      @items[index]
    end
   
    # Yields each item on the current page. 
    def each(&block)
      @items.each(&block)
    end  

    # Returns the first item from the current page.
    def first
      @items.first
    end

    # Returns true if the page is the last page. False otherwise.
    def last_page?
      current_page_number == total_pages
    end
   
    # Retrieves the next page of records. 
    def next_page
      if last_page?
        return nil
      end
      @paging_block.call(next_page_number)
    end
   
    # The next page number. Returns +nil+ if on the last page. 
    def next_page_number
      last_page? ? nil : current_page_number + 1
    end
   
    # Returns the total number of pages. 
    def total_pages
      total = total_items / page_size 
      if total_items % page_size != 0
        total += 1
      end  
      total
    end  
  end
end
