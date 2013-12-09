require 'json'

def nonce_for_new_credit_card(options)
  client = ClientApiHttp.new(Braintree::Configuration.instantiate,
    :authorization_fingerprint => Braintree::AuthorizationFingerprint.generate,
    :session_identifier => "fake_identifier",
    :session_identifier_type => "testing"
  )

  response = client.add_card(options)
  body = JSON.parse(response.body)

  if body["errors"] != nil
    raise body["errors"].inspect
  end

  body["nonce"]
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

  def get_cards
    encoded_fingerprint = Braintree::Util.url_encode(@options[:authorization_fingerprint])
    url = "/client_api/credit_cards.json?"
    url += "authorizationFingerprint=#{encoded_fingerprint}"
    url += "&sessionIdentifier=#{@options[:session_identifier]}"
    url += "&sessionIdentifierType=#{@options[:session_identifier_type]}"

    get(url)
  end

  def add_card(params)
    fingerprint = @options[:authorization_fingerprint]
    params[:authorizationFingerprint] = fingerprint
    params[:sessionIdentifier] = @options[:session_identifier]
    params[:sessionIdentifierType] = @options[:session_identifier_type]

    post("/client_api/credit_cards.json", params)
  end
end
