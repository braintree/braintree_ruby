module Braintree
  module PaymentInstrumentType
    PayPalAccount = 'paypal_account'
    EuropeBankAccount = 'europe_bank_account'
    CreditCard = 'credit_card'
    CoinbaseAccount = 'coinbase_account'
    ApplePayCard = 'apple_pay_card'

    All = constants.map { |c| const_get(c) }
  end
end
