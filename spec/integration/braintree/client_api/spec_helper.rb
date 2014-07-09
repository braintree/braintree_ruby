require 'json'

def decode_client_token(raw_client_token)
  decoded_client_token_string = Base64.decode64(raw_client_token)
  JSON.parse(decoded_client_token_string)
end

def nonce_for_new_payment_method(options)
  client = _initialize_client(options)
  response = client.add_payment_method(options)

  _nonce_from_response(response)
end

def _initialize_client(options)
  client_token_options = options.delete(:client_token_options) || {}
  raw_client_token = Braintree::ClientToken.generate(client_token_options)
  client_token = decode_client_token(raw_client_token)

  ClientApiHttp.new(Braintree::Configuration.instantiate,
    :authorization_fingerprint => client_token["authorizationFingerprint"],
    :shared_customer_identifier => "fake_identifier",
    :shared_customer_identifier_type => "testing"
  )
end

def _nonce_from_response(response)
  body = JSON.parse(response.body)

  if body["errors"] != nil
    raise body["errors"].inspect
  end

  if body.has_key?("paypalAccounts")
    body["paypalAccounts"][0]["nonce"]
  else
    body["creditCards"][0]["nonce"]
  end
end

def nonce_for_paypal_account(paypal_account_details)
  raw_client_token = Braintree::ClientToken.generate
  client_token = decode_client_token(raw_client_token)
  client = ClientApiHttp.new(Braintree::Configuration.instantiate,
    :authorization_fingerprint => client_token["authorizationFingerprint"]
  )

  response = client.create_paypal_account(paypal_account_details)
  body = JSON.parse(response.body)

  if body["errors"] != nil
    raise body["errors"].inspect
  end

  body["paypalAccounts"][0]["nonce"]
end

class ClientApiHttp
  attr_reader :config, :options

  def initialize(config, options)
    @config = config
    @options = options
  end

  def get(path)
    _http_do(Net::HTTP::Get, path)
  end

  def post(path, params)
    _http_do(Net::HTTP::Post, path, params.to_json)
  end

  def put(path, params)
    _http_do(Net::HTTP::Put, path, params.to_json)
  end

  def fingerprint=(fingerprint)
    @options[:authorization_fingerprint] = fingerprint
  end

  def _http_do(http_verb, path, body = nil)
    connection = Net::HTTP.new(@config.server, @config.port)
    connection.read_timeout = 60
    if @config.ssl?
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
      connection.ca_file = @config.ca_file
      connection.verify_callback = proc { |preverify_ok, ssl_context| _verify_ssl_certificate(preverify_ok, ssl_context) }
    end
    connection.start do |http|
      request = http_verb.new(path)
      request["X-ApiVersion"] = @config.api_version
      request["Content-Type"] = "application/json"
      request.body = body if body
      http.request(request)
    end
  rescue OpenSSL::SSL::SSLError
    raise Braintree::SSLCertificateError
  end

  def get_payment_methods
    encoded_fingerprint = Braintree::Util.url_encode(@options[:authorization_fingerprint])
    url = "/merchants/#{@config.merchant_id}/client_api/v1/payment_methods?"
    url += "authorizationFingerprint=#{encoded_fingerprint}"
    url += "&sharedCustomerIdentifier=#{@options[:shared_customer_identifier]}"
    url += "&sharedCustomerIdentifierType=#{@options[:shared_customer_identifier_type]}"

    get(url)
  end

  def add_payment_method(params)
    fingerprint = @options[:authorization_fingerprint]
    params[:authorizationFingerprint] = fingerprint
    params[:sharedCustomerIdentifier] = @options[:shared_customer_identifier]
    params[:sharedCustomerIdentifierType] = @options[:shared_customer_identifier_type]

    payment_method_type = nil
    if params.has_key?(:paypal_account)
      payment_method_type = "paypal_accounts"
    else
      payment_method_type = "credit_cards"
    end

    post("/merchants/#{@config.merchant_id}/client_api/v1/payment_methods/#{payment_method_type}", params)
  end

  def create_credit_card(params)
    params = {:credit_card => params}
    params.merge!(
      :authorization_fingerprint => @options[:authorization_fingerprint],
      :shared_customer_identifier => "fake_identifier",
      :shared_customer_identifier_type => "testing"
    )

    post("/merchants/#{config.merchant_id}/client_api/v1/payment_methods/credit_cards", params)
  end

  def create_paypal_account(params)
    params = {:paypal_account => params}
    params.merge!(
      :authorization_fingerprint => @options[:authorization_fingerprint]
    )

    post("/merchants/#{config.merchant_id}/client_api/v1/payment_methods/paypal_accounts", params)
  end

  def create_sepa_bank_account_nonce(params)
    foo = {
      :authorization_fingerprint => @options[:authorization_fingerprint],
      :shared_customer_identifier => "fake_identifier",
      :shared_customer_identifier_type => "testing",

      :sepa_mandate => params
    }

    response = post("/merchants/#{config.merchant_id}/client_api/v1/sepa_mandates", foo)

    mrn = JSON.parse(response.body)['sepaMandates'][0]['mandateReferenceNumber']
    accept_response = put("/merchants/#{config.merchant_id}/client_api/v1/sepa_mandates/#{mrn}/accept.json",foo)
    JSON.parse(accept_response.body)['sepaBankAccounts'][0]['nonce']
  end
end
