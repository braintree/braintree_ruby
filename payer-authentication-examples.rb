require "rubygems"
require "braintree"

Braintree::Configuration.environment = :sandbox
Braintree::Configuration.merchant_id = "your_merchant_id"
Braintree::Configuration.public_key = "your_public_key"
Braintree::Configuration.private_key = "your_private_key"

result = Braintree::Transaction.sale(
  :amount => "1000.00",
  :credit_card => {
    :number => "6304000000000042",
    :expiration_date => "05/12"
  }
)

if result.success?
  puts "Transaction ID: #{result.transaction.id}"
  # status will be authorized or submitted_for_settlement
  puts "Transaction Status: #{result.transaction.status}"
else
  puts "Message: #{result.message}"
  if result.transaction.nil?
    
    # validation errors prevented transaction from being created
    p result.errors
  else
    puts "Transaction ID: #{result.transaction.id}"
    # status will be processor_declined, gateway_rejected, or failed
    puts "Transaction Status: #{result.transaction.status}"
  end
end
