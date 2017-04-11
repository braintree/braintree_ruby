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

def generate_valid_us_bank_account_nonce()
  raw_client_token = Braintree::ClientToken.generate
  client_token = decode_client_token(raw_client_token)

  url = client_token["braintree_api"]["url"] + "/tokens"
  token = client_token["braintree_api"]["access_token"]
  payload = {
    :type => "us_bank_account",
    :billing_address => {
      :street_address => "123 Ave",
      :region => "CA",
      :locality => "San Francisco",
      :postal_code => "94112"
    },
    :account_type => "checking",
    :routing_number => "021000021",
    :account_number => "567891234",
    :account_holder_name => "Dan Schulman",
    :ach_mandate => {
      :text => "cl mandate text"
    }
  }

  json = _cosmos_post(token, url, payload)
  json["data"]["id"]
end

def generate_valid_ideal_payment_nonce(amount = Braintree::Test::TransactionAmounts::Authorize)
  raw_client_token = Braintree::ClientToken.generate(:merchant_account_id => "ideal_merchant_account")
  client_token = decode_client_token(raw_client_token)
  client = ClientApiHttp.new(
    Braintree::Configuration.instantiate,
    :authorization_fingerprint => client_token["authorizationFingerprint"],
  )
  config = JSON.parse(client.get_configuration.body)

  token = client_token["braintree_api"]["access_token"]
  url = client_token["braintree_api"]["url"] + "/ideal-payments"
  payload = {
    :issuer => "RABONL2U",
    :order_id => SpecHelper::DefaultOrderId,
    :amount => amount,
    :currency => "EUR",
    :redirect_url => "https://braintree-api.com",
    :route_id => config["ideal"]["routeId"]
  }

  json = _cosmos_post(token, url, payload)
  json["data"]["id"]
end

def sample(arr)
  6.times.map { arr[rand(arr.length)] }.join
end

def generate_invalid_us_bank_account_nonce
  nonce_characters = "bcdfghjkmnpqrstvwxyz23456789".chars.to_a
  nonce = "tokenusbankacct_"
  nonce += 4.times.map { sample(nonce_characters) }.join("_")
  nonce += "_xxx"
end

def _cosmos_post(token, url, payload)
  uri = URI::parse(url)
  connection = Net::HTTP.new(uri.host, uri.port)
  connection.use_ssl = true
  connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
  resp = connection.start do |http|
    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["Braintree-Version"] = "2015-11-01"
    request["Authorization"] = "Bearer #{token}"
    request.body = payload.to_json
    http.request(request)
  end

  JSON.parse(resp.body)
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

  def _verify_ssl_certificate(preverify_ok, ssl_context)
    if preverify_ok != true || ssl_context.error != 0
      err_msg = "SSL Verification failed -- Preverify: #{preverify_ok}, Error: #{ssl_context.error_string} (#{ssl_context.error})"
      @config.logger.error err_msg
      false
    else
      true
    end
  end

  def get_configuration
    encoded_fingerprint = Braintree::Util.url_encode(@options[:authorization_fingerprint])
    url = "/merchants/#{@config.merchant_id}/client_api/v1/configuration"
    url += "?authorizationFingerprint=#{encoded_fingerprint}"
    url += "&configVersion=3"

    get(url)
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

  def create_europe_bank_account_nonce(params)
    foo = {
      :authorization_fingerprint => @options[:authorization_fingerprint],
      :shared_customer_identifier => "fake_identifier",
      :shared_customer_identifier_type => "testing",

      :sepa_mandate => params
    }

    response = post("/merchants/#{config.merchant_id}/client_api/v1/sepa_mandates", foo)

    mrn = JSON.parse(response.body)['europeBankAccounts'][0]['sepaMandates'][0]['mandateReferenceNumber']
    JSON.parse(response.body)['europeBankAccounts'][0]['nonce']
  end
end
