require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Dispute do
  let(:attributes) do
    {
      :id => "open_dispute",
      :amount_disputed => "500.00",
      :amount_won => "0.00",
      :created_at => Time.utc(2009, 3, 9, 10, 50, 39),
      :original_dispute_id => "original_dispute_id",
      :received_date => "2009-03-09",
      :reply_by_date => nil,
      :updated_at => Time.utc(2009, 3, 9, 10, 50, 39),
      :evidence => [
        {
          comment: nil,
          created_at: Time.utc(2009, 3, 10, 12, 5, 20),
          id: "evidence1",
          sent_to_processor_at: nil,
          url: "url_of_file_evidence",
        },
        {
          comment: "text evidence",
          created_at: Time.utc(2009, 3, 10, 12, 5, 21),
          id: "evidence2",
          sent_to_processor_at: "2009-03-13",
          url: nil,
        }
      ],
      :status_history => [
        {
          :effective_date => "2009-03-09",
          :status => "open",
          :timestamp => Time.utc(2009, 3, 9, 10, 50, 39),
        }
      ],
      :transaction => {
        :amount => "31.00",
        :id => "open_disputed_transaction",
        :created_at => Time.utc(2009, 2, 9, 12, 59, 59),
        :order_id => nil,
        :purchase_order_number => "po",
        :payment_instrument_subtype => "Visa",
      }
    }
  end

  describe "self.find" do
    it "raises an exception if the id is blank" do
      expect do
        Braintree::Dispute.find("  ")
      end.to raise_error(ArgumentError)
    end

    it "raises an exception if the id is nil" do
      expect do
        Braintree::Dispute.find(nil)
      end.to raise_error(ArgumentError)
    end

    it "does not raise an exception if the id is a fixnum" do
      Braintree::Http.stub(:new).and_return double.as_null_object
      Braintree::Dispute.stub(:_new).and_return nil
      expect do
        Braintree::Dispute.find(8675309)
      end.to_not raise_error
    end
  end

  describe "initialize" do
    it "converts string amount_dispute and amount_won" do
      dispute = Braintree::Dispute._new(attributes)

      dispute.amount_disputed.should == 500.0
      dispute.amount_won.should == 0.0
    end

    it "handles nil reply_by_date" do
      dispute = Braintree::Dispute._new(attributes)

      dispute.reply_by_date.should == nil
    end

    it "converts reply_by_date, received_date from String to Date" do
      dispute = Braintree::Dispute._new(attributes.merge(:reply_by_date => "2009-03-14"))

      dispute.received_date.should == Date.new(2009, 3, 9)
      dispute.reply_by_date.should == Date.new(2009, 3, 14)
    end

    it "converts transaction hash into a Dispute::Transaction object" do
      dispute = Braintree::Dispute._new(attributes)

      dispute.transaction.amount.should == 31.00
      dispute.transaction.id.should == "open_disputed_transaction"
      dispute.transaction.order_id.should == nil
      dispute.transaction.purchase_order_number.should == "po"
      dispute.transaction.payment_instrument_subtype.should == "Visa"
    end

    it "converts status_history hash into an array of Dispute::HistoryEvent objects" do
      dispute = Braintree::Dispute._new(attributes)

      dispute.status_history.length.should == 1
      status_history_1 = dispute.status_history.first
      status_history_1.status.should == Braintree::Dispute::Status::Open
      status_history_1.timestamp.should == Time.utc(2009, 3, 9, 10, 50, 39)
    end

    it "converts evidence hash into an array of Dispute::Evidence objects" do
      dispute = Braintree::Dispute._new(attributes)

      dispute.evidence.length.should ==2
      evidence1 = dispute.evidence.first
      evidence1.comment.should == nil
      evidence1.created_at.should == Time.utc(2009, 3, 10, 12, 5, 20)
      evidence1.id.should == "evidence1"
      evidence1.sent_to_processor_at.should == nil
      evidence1.url.should == "url_of_file_evidence"

      evidence2 = dispute.evidence.last
      evidence2.comment.should == "text evidence"
      evidence2.created_at.should == Time.utc(2009, 3, 10, 12, 5, 21)
      evidence2.id.should == "evidence2"
      evidence2.sent_to_processor_at.should == Date.new(2009, 3, 13)
      evidence2.url.should == nil
    end

    it "handles nil evidence" do
      attributes.delete(:evidence)

      dispute = Braintree::Dispute._new(attributes)

      dispute.evidence.should == nil
    end
  end

  describe "==" do
    it "returns true when given a dispute with the same id" do
      first = Braintree::Dispute._new(attributes)
      second = Braintree::Dispute._new(attributes)

      first.should == second
      second.should == first
    end

    it "returns false when given a dispute with a different id" do
      first = Braintree::Dispute._new(attributes)
      second = Braintree::Dispute._new(attributes.merge(:id => "1234"))

      first.should_not == second
      second.should_not == first
    end

    it "returns false when not given a dispute" do
      dispute = Braintree::Dispute._new(attributes)
      dispute.should_not == "not a dispute"
    end
  end

  describe "new" do
    it "is protected" do
      expect do
        Braintree::Dispute.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end
end
