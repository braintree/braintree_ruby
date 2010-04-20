require File.dirname(__FILE__) + "/../spec_helper"

describe "Braintree::PagedCollection" do
  it "includes enumerable" do
    collection = Braintree::PagedCollection.new(:items => ["a"])
    collection.detect { |item| item == "a" }.should == "a"
  end

  describe "each" do
    it "iterates over the contents" do
      expected = ["apples", "bananas", "cherries"]
      collection = Braintree::PagedCollection.new(
        :current_page_number => 1,
        :items => expected,
        :page_size => 5,
        :total_items => expected.size
      )
      actual = []
      collection.each do |item|
        actual << item
      end
      actual.should == expected
    end
  end

  describe "empty?" do
    it "returns true if there are no items" do
      collection = Braintree::PagedCollection.new(
        :current_page_number => 1,
        :items => [],
        :page_size => 5,
        :total_items => 0
      )
      collection.should be_empty
    end

    it "returns false if there are items" do
      collection = Braintree::PagedCollection.new(
        :current_page_number => 1,
        :items => ["one"],
        :page_size => 5,
        :total_items => 1
      )
      collection.should_not be_empty
    end
  end

  describe "first" do
    it "returns the first element" do
      collection = Braintree::PagedCollection.new(
        :items => ["apples", "bananas", "cherries"]
      )
      collection.first.should == "apples"
    end
  end

  describe "_last_page?" do
    it "returns true if the page is the last page" do
      collection = Braintree::PagedCollection.new(:current_page_number => 3, :page_size => 50, :total_items => 150)
      collection._last_page?.should == true
    end

    it "returns false if the page is not the last page" do
      collection = Braintree::PagedCollection.new(:current_page_number => 3, :page_size => 50, :total_items => 151)
      collection._last_page?.should == false
    end
  end
end
