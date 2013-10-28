class ClientApiHttp
  attr_reader :config, :options

  def initialize(config, options)
    @config = config
    @options = options
  end

  def get(path)
    _http_do(Net::HTTP::Get, path)
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
      http.request(request)
    end
  rescue OpenSSL::SSL::SSLError
    raise Braintree::SSLCertificateError
  end

  def get_cards
    encoded_fingerprint = Braintree::Util.url_encode(options[:fingerprint])
    url = "/client_api/credit_cards.json?"
    url += "authorizationFingerprint=#{encoded_fingerprint}"
    url += "&sessionIdentifier=#{options[:session_identifier]}"
    url += "&sessionIdentifierType=#{options[:session_identifier_type]}"
    url += "&publicKey=#{config.public_key}"
    url += "&merchantId=#{config.merchant_id}"

    get(url)
  end
end
