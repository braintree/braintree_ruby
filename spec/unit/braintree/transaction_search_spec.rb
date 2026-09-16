require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::TransactionSearch do
  it "overrides previous 'is' with new 'is' for the same field" do
    search = Braintree::TransactionSearch.new
    search.billing_company.is "one"
    search.billing_company.is "two"
    expect(search.to_hash).to eq({:billing_company => {:is => "two"}})
  end

  it "overrides previous 'in' with new 'in' for the same field" do
    search = Braintree::TransactionSearch.new
    search.status.in Braintree::Transaction::Status::Authorized
    search.status.in Braintree::Transaction::Status::SubmittedForSettlement
    expect(search.to_hash).to eq({:status => [Braintree::Transaction::Status::SubmittedForSettlement]})
  end

  it "raises if the operator 'is' is left off" do
    search = Braintree::TransactionSearch.new
    expect do
      search.billing_company "one"
    end.to raise_error(RuntimeError, "An operator is required")
  end

  it "builds a hash for ach_type with a single value (same_day)" do
    search = Braintree::TransactionSearch.new
    search.ach_type.is Braintree::Transaction::AchType::SameDay
    expect(search.to_hash).to eq({:ach_type => [Braintree::Transaction::AchType::SameDay]})
  end

  it "builds a hash for ach_type with a single value (standard)" do
    search = Braintree::TransactionSearch.new
    search.ach_type.is Braintree::Transaction::AchType::Standard
    expect(search.to_hash).to eq({:ach_type => [Braintree::Transaction::AchType::Standard]})
  end

  it "builds a hash for ach_type with both values" do
    search = Braintree::TransactionSearch.new
    search.ach_type.in Braintree::Transaction::AchType::SameDay, Braintree::Transaction::AchType::Standard
    expect(search.to_hash).to eq({:ach_type => [Braintree::Transaction::AchType::SameDay, Braintree::Transaction::AchType::Standard]})
  end

  it "raises if ach_type is given a value outside the allow-list" do
    search = Braintree::TransactionSearch.new
    expect do
      search.ach_type.is "invalid_ach_type"
    end.to raise_error(ArgumentError, /Invalid argument\(s\) for ach_type: invalid_ach_type/)
  end
end
