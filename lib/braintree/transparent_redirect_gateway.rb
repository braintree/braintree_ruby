module Braintree
  class TransparentRedirectGateway # :nodoc
    def initialize(config)
      @config = config
    end

    def confirm(query_string)
      params = TransparentRedirect.parse_and_validate_query_string query_string
      confirmation_gateway = {
        TransparentRedirect::Kind::CreateCustomer => :customer,
        TransparentRedirect::Kind::UpdateCustomer => :customer,
        TransparentRedirect::Kind::CreatePaymentMethod => :credit_card,
        TransparentRedirect::Kind::UpdatePaymentMethod => :credit_card,
        TransparentRedirect::Kind::CreateTransaction => :transaction
      }[params[:kind]]

      gateway = Gateway.new(@config)
      gateway.send(confirmation_gateway)._do_create("/transparent_redirect_requests/#{params[:id]}/confirm")
    end

    def url
      "#{@config.base_merchant_url}/transparent_redirect_requests"
    end
  end
end

