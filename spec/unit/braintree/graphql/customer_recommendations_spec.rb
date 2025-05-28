require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::CustomerRecommendations do
  let(:recommendation_data) do
    [
      {
        paymentOption: "PAYPAL",
        recommendedPriority: 1
      },
      {
        paymentOption: "VENMO",
        recommendedPriority: 2
      }
    ]
  end

  describe "#initialize" do
    it "creates payment_recommendations correctly" do
      recs = Braintree::CustomerRecommendations.new(payment_recommendations: recommendation_data)
      expect(recs.payment_recommendations.size).to eq(2)
      expect(recs.payment_recommendations.first).to be_a(Braintree::PaymentRecommendations)
      expect(recs.payment_recommendations.first.payment_option).to eq("PAYPAL")
      expect(recs.payment_recommendations.last.payment_option).to eq("VENMO")
    end

    it "creates payment_options from payment_recommendations" do
      recs = Braintree::CustomerRecommendations.new(payment_recommendations: recommendation_data)
      expect(recs.payment_options.size).to eq(2)
      expect(recs.payment_options.first).to be_a(Braintree::PaymentOptions)
      expect(recs.payment_options.first.payment_option).to eq("PAYPAL")
      expect(recs.payment_options.last.payment_option).to eq("VENMO")
    end

    it "is null safe if no recommendations are passed in" do
      recs = Braintree::CustomerRecommendations.new
      expect(recs.payment_recommendations).to eq([])
      expect(recs.payment_options).to eq([])
    end
  end
end