module Braintree
  class Http # :nodoc:

    def initialize(config)
      @config = config
    end

    def delete(path)
      response = _http_do Net::HTTP::Delete, path
      if response.code.to_i == 200
        true
      else
        Util.raise_exception_for_status_code(response.code)
      end
    end

    def get(path)
      response = _http_do Net::HTTP::Get, path
      if response.code.to_i == 200
        Xml.hash_from_xml(_body(response))
      else
        Util.raise_exception_for_status_code(response.code)
      end
    end

    def post(path, params = nil)
      response = _http_do Net::HTTP::Post, path, _build_xml(params)
      if response.code.to_i == 200 || response.code.to_i == 201 || response.code.to_i == 422
        Xml.hash_from_xml(_body(response))
      else
        Util.raise_exception_for_status_code(response.code)
      end
    end

    def put(path, params = nil)
      response = _http_do Net::HTTP::Put, path, _build_xml(params)
      if response.code.to_i == 200 || response.code.to_i == 201 || response.code.to_i == 422
        Xml.hash_from_xml(_body(response))
      else
        Util.raise_exception_for_status_code(response.code)
      end
    end

    def _build_xml(params)
      return nil if params.nil?
      Braintree::Xml.hash_to_xml params
    end

    def _http_do(http_verb, path, body = nil)
      connection = Net::HTTP.new(@config.server, @config.port)
      if @config.ssl?
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
        connection.ca_file = @config.ca_file
        connection.verify_callback = proc { |preverify_ok, ssl_context| _verify_ssl_certificate(preverify_ok, ssl_context) }
      end
      connection.start do |http|
        request = http_verb.new("#{@config.base_merchant_path}#{path}")
        request["Accept"] = "application/xml"
        request["User-Agent"] = @config.user_agent
        request["Accept-Encoding"] = "gzip"
        request["X-ApiVersion"] = @config.api_version
        request.basic_auth @config.public_key, @config.private_key
        @config.logger.debug "[Braintree] [#{_current_time}] #{request.method} #{path}"
        if body
          request["Content-Type"] = "application/xml"
          request.body = body
          @config.logger.debug _format_and_sanitize_body_for_log(body)
        end
        response = http.request(request)
        @config.logger.info "[Braintree] [#{_current_time}] #{request.method} #{path} #{response.code}"
        @config.logger.debug "[Braintree] [#{_current_time}] #{response.code} #{response.message}"
        if @config.logger.level == Logger::DEBUG
          @config.logger.debug _format_and_sanitize_body_for_log(_body(response))
        end
        response
      end
    end

    def _body(response)
      if response.header["Content-Encoding"] == "gzip"
        Zlib::GzipReader.new(StringIO.new(response.body)).read
      else
        raise UnexpectedError, "expected a gzipped response"
      end
    end

    def _current_time
      Time.now.utc.strftime("%d/%b/%Y %H:%M:%S %Z")
    end

    def _format_and_sanitize_body_for_log(input_xml)
      formatted_xml = input_xml.gsub(/^/, "[Braintree] ")
      formatted_xml = formatted_xml.gsub(/<number>(.{6}).+?(.{4})<\/number>/, '<number>\1******\2</number>')
      formatted_xml = formatted_xml.gsub(/<cvv>.+?<\/cvv>/, '<cvv>***</cvv>')
      formatted_xml
    end

    def _verify_ssl_certificate(preverify_ok, ssl_context)
      if preverify_ok != true || ssl_context.error != 0
        err_msg = "SSL Verification failed -- Preverify: #{preverify_ok}, Error: #{ssl_context.error_string} (#{ssl_context.error})"
        @config.logger.error err_msg
        raise SSLCertificateError.new(err_msg)
      end
      true
    end
  end
end

