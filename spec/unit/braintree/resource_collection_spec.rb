require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "Braintree::ResourceCollection" do
  describe "enumeration" do
    it "iterates over the elements, yielding to the block in pages" do
      values = %w(a b c d e)
      collection = Braintree::ResourceCollection.new(:search_results => {:ids => [0,1,2,3,4], :page_size => 2}) do |ids|
        ids.map { |id| values[id] }
      end

      count = 0
      collection.each_with_index do |item, index|
        expect(item).to eq(values[index])
        count += 1
      end

      expect(count).to eq(5)
    end
  end

  describe "#first" do
    it "returns nil with no results" do
      values = %w(a b c d e)
      collection = Braintree::ResourceCollection.new(:search_results => {:ids => [], :page_size => 2}) do |ids|
        ids.map { |id| values[id] }
      end

      expect(collection.first).to eq(nil)
    end

    context "with results" do
      let(:collection) do
        values = %w(a b c d e)

        Braintree::ResourceCollection.new(:search_results => {:ids => [0,1,2,3,4], :page_size => 2}) do |ids|
          ids.map { |id| values[id] }
        end
      end

      it "returns the first occourence" do
        expect(collection.first).to eq("a")
      end

      it "returns the first N occourences" do
        expect(collection.first(4)).to eq(["a","b","c","d"])
      end
    end
  end

  describe "#ids" do
    it "returns a list of the resource collection ids" do
      collection = Braintree::ResourceCollection.new(:search_results => {:ids => [0,1,2,3,4], :page_size => 2})
      expect(collection.ids).to eq([0,1,2,3,4])
    end
  end

  it "returns an empty array when the collection is empty" do
    collection = Braintree::ResourceCollection.new(:search_results => {:page_size => 2})
    expect(collection.ids).to eq([])
  end
end
