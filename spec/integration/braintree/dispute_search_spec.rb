require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Dispute, "search" do
  context "advanced" do
    it "correctly returns a result with no matches" do
      collection = Braintree::Dispute.search do |search|
        search.id.is "non_existent_dispute"
      end

      expect(collection.disputes.count).to eq(0)
    end

    it "correctly returns a single dispute by id" do
      collection = Braintree::Dispute.search do |search|
        search.id.is "open_dispute"
      end

      expect(collection.disputes.count).to eq(1)
      dispute = collection.disputes.first

      expect(dispute.id).to eq("open_dispute")
      expect(dispute.status).to eq(Braintree::Dispute::Status::Open)
    end

    it "correctly returns disputes by multiple reasons" do
      collection = Braintree::Dispute.search do |search|
        search.reason.in [
          Braintree::Dispute::Reason::ProductUnsatisfactory,
          Braintree::Dispute::Reason::Retrieval
        ]
      end

      expect(collection.disputes.count).to eq(2)
      dispute = collection.disputes.first
    end

    it "correctly returns disputes by received_date range" do
      collection = Braintree::Dispute.search do |search|
        search.received_date.between("03/03/2014", "03/05/2014")
      end

      expect(collection.disputes.count).to eq(1)
      dispute = collection.disputes.first

      expect(dispute.received_date).to eq(Date.new(2014, 3, 4))
    end
  end
end
