require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Http do
  describe "self._handle_response" do
    it "raises an AuthenticationError if authentication fails" do
      begin
        original_key = Braintree::Configuration.public_key
        Braintree::Configuration.public_key = "invalid_public_key"
        expect do
          config = Braintree::Configuration.instantiate
          config.http.get("#{config.base_merchant_path}/customers")
        end.to raise_error(Braintree::AuthenticationError)
      ensure
        Braintree::Configuration.public_key = original_key
      end
    end

    it "raises an AuthorizationError if authorization fails" do
      expect do
        config = Braintree::Configuration.instantiate
        config.http.get("#{config.base_merchant_path}/home")
      end.to raise_error(Braintree::AuthorizationError)
    end
  end

  describe "self._http_do" do
    it "logs one line of info to the logger" do
      begin
        old_logger = Braintree::Configuration.logger
        now_in_utc = Time.utc(2009, 10, 10, 13, 55, 36)
        SpecHelper.stub_time_dot_now(now_in_utc) do
          output = StringIO.new
          Braintree::Configuration.logger = Logger.new(output)
          Braintree::Configuration.logger.level = Logger::INFO
          Braintree::Customer.all
          utc_or_gmt = Time.now.utc.strftime("%Z")
          expect(output.string).to include("[Braintree] [10/Oct/2009 13:55:36 #{utc_or_gmt}] POST /merchants/integration_merchant_id/customers/advanced_search_ids 200")
        end
      ensure
        Braintree::Configuration.logger = old_logger
      end
    end

    it "logs full request and response for debug logger" do
      customer = Braintree::Customer.create.customer
      begin
        old_logger = Braintree::Configuration.logger
        now_in_utc = Time.utc(2009, 10, 10, 13, 55, 36)
        SpecHelper.stub_time_dot_now(now_in_utc) do
          output = StringIO.new
          Braintree::Configuration.logger = Logger.new(output)
          Braintree::Configuration.logger.level = Logger::DEBUG
          result = Braintree::CreditCard.create(
            :customer_id => customer.id,
            :cardholder_name => "Sam Jones",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009",
          )
          expect(result.success?).to eq(true)
          utc_or_gmt = Time.now.utc.strftime("%Z")
          expect(output.string).to include("[Braintree] [10/Oct/2009 13:55:36 #{utc_or_gmt}] POST /merchants/integration_merchant_id/payment_methods")
          expect(output.string).to include("[Braintree]   <cardholder-name>Sam Jones</cardholder-name>")
          expect(output.string).to include("[Braintree]   <number>401288******1881</number>")
          expect(output.string).to include("[Braintree] [10/Oct/2009 13:55:36 #{utc_or_gmt}] 201 Created")
          expect(output.string).to match(/\[Braintree\]   <token>\w+<\/token>/)
        end
      ensure
        Braintree::Configuration.logger = old_logger
      end
    end

    it "posts multipart for file uploads" do
      config = Braintree::Configuration.instantiate
      file = File.new("#{File.dirname(__FILE__)}/../../fixtures/files/bt_logo.png", "r")
      response = config.http.post("#{config.base_merchant_path}/document_uploads", {"document_upload[kind]" => "evidence_document"}, file)
      expect(response[:document_upload][:content_type]).to eq("image/png")
      expect(response[:document_upload][:id]).not_to be_nil
    end

    describe "user_agent" do
      after do
        Braintree::Configuration.custom_user_agent = nil
      end

      it "sets the User-Agent header using the default user agent" do
        config = Braintree::Configuration.instantiate
        response = config.http.get("#{config.base_merchant_path}/test/headers")
        expect(response[:headers][:HTTP_USER_AGENT]).to eq("Braintree Ruby Gem #{Braintree::Version::String}")
      end

      it "sets the User-Agent header using a customer user agent" do
        Braintree::Configuration.custom_user_agent = "ActiveMerchant 1.2.3"
        config = Braintree::Configuration.instantiate
        response = config.http.get("#{config.base_merchant_path}/test/headers")
        expect(response[:headers][:HTTP_USER_AGENT]).to eq("Braintree Ruby Gem #{Braintree::Version::String} (ActiveMerchant 1.2.3)")
      end
    end

    describe "ssl_version" do
      xit "causes failed requests to sandbox with incompatible SSL version" do
        begin
          original_env = Braintree::Configuration.environment
          Braintree::Configuration.environment = :sandbox
          Braintree::Configuration.ssl_version = :TLSv1
          allow(Braintree::Configuration).to receive(:base_merchant_path).and_return("/")

          expect do
            Braintree::Configuration.instantiate.http._http_do(Net::HTTP::Get, "/login")
          end.to raise_error(Braintree::SSLCertificateError)
        ensure
          Braintree::Configuration.environment = original_env
          Braintree::Configuration.ssl_version = nil
        end
      end

      it "results in successful requests to sandbox with up-to-date SSL version" do
        begin
          original_env = Braintree::Configuration.environment
          Braintree::Configuration.environment = :sandbox
          Braintree::Configuration.ssl_version = :TLSv1_2
          allow(Braintree::Configuration).to receive(:base_merchant_path).and_return("/")

          expect do
            Braintree::Configuration.instantiate.http._http_do(Net::HTTP::Get, "/login")
          end.to_not raise_error
        ensure
          Braintree::Configuration.environment = original_env
          Braintree::Configuration.ssl_version = nil
        end
      end
    end

    describe "ssl verification" do
      it "rejects when the certificate isn't verified by our certificate authority (self-signed)" do
        begin
          original_env = Braintree::Configuration.environment
          Braintree::Configuration.environment = :development
          config = Braintree::Configuration.instantiate
          allow(config).to receive(:ssl?).and_return(true)
          allow(config).to receive(:port).and_return(SSL_TEST_PORT)

          start_ssl_server do
            expect do
              config.http._http_do(Net::HTTP::Get, "/login")
            end.to raise_error(Braintree::SSLCertificateError)
          end
        ensure
          Braintree::Configuration.environment = original_env
        end
      end

      it "rejects when the certificate is signed by a different (but valid) root CA" do
        begin
          original_env = Braintree::Configuration.environment
          Braintree::Configuration.environment = :development
          # Random CA root file from a different certificate authority
          config = Braintree::Configuration.instantiate
          allow(config).to receive(:ca_file).and_return(
            File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "ssl", "geotrust_global.crt")),
          )
          allow(config).to receive(:ssl?).and_return(true)
          allow(config).to receive(:port).and_return(SSL_TEST_PORT)

          start_ssl_server do
            expect do
              config.http._http_do(Net::HTTP::Get, "/login")
            end.to raise_error(Braintree::SSLCertificateError)
          end
        ensure
          Braintree::Configuration.environment = original_env
        end
      end

      it "accepts the certificate on the qa server" do
        begin
          original_env = Braintree::Configuration.environment
          Braintree::Configuration.environment = :qa
          allow(Braintree::Configuration).to receive(:base_merchant_path).and_return("/")

          expect do
            Braintree::Configuration.instantiate.http._http_do(Net::HTTP::Get, "/login")
          end.to_not raise_error
        ensure
          Braintree::Configuration.environment = original_env
        end
      end

      it "accepts the certificate on the sandbox server" do
        begin
          original_env = Braintree::Configuration.environment
          Braintree::Configuration.environment = :sandbox
          allow(Braintree::Configuration).to receive(:base_merchant_path).and_return("/")

          expect do
            Braintree::Configuration.instantiate.http._http_do(Net::HTTP::Get, "/login")
          end.to_not raise_error
        ensure
          Braintree::Configuration.environment = original_env
        end
      end

      it "accepts the certificate on the production server" do
        begin
          original_env = Braintree::Configuration.environment
          Braintree::Configuration.environment = :production
          allow(Braintree::Configuration).to receive(:base_merchant_path).and_return("/")

          expect do
            Braintree::Configuration.instantiate.http._http_do(Net::HTTP::Get, "/login")
          end.to_not raise_error
        ensure
          Braintree::Configuration.environment = original_env
        end
      end

      it "raises an appropriate error if certificate fails validation" do
        begin
          original_env = Braintree::Configuration.environment
          Braintree::Configuration.environment = :sandbox
          config = Braintree::Configuration.instantiate
          allow(config).to receive(:base_merchant_path).and_return("/")
          allow(config).to receive(:ca_file).and_return("does_not_exist")

          expect do
            config.http._http_do(Net::HTTP::Get, "/login")
          end.to raise_error(Braintree::SSLCertificateError)
        ensure
          Braintree::Configuration.environment = original_env
        end
      end
    end
  end

  describe "self._verify_ssl_certificate" do
    it "is false if preverify is false" do
      context = OpenSSL::X509::StoreContext.new(OpenSSL::X509::Store.new)
      expect(Braintree::Configuration.instantiate.http._verify_ssl_certificate(false, context)).to eq(false)
    end

    it "returns false if ssl_context doesn't have an error code of 0" do
      context = OpenSSL::X509::StoreContext.new(OpenSSL::X509::Store.new)
      context.error = 19 # ca_file incorrect, self-signed
      expect(Braintree::Configuration.instantiate.http._verify_ssl_certificate(true, context)).to eq(false)
    end

    it "doesn't raise if there is no error" do
      context = OpenSSL::X509::StoreContext.new(OpenSSL::X509::Store.new)
      expect do
        Braintree::Configuration.instantiate.http._verify_ssl_certificate(true, context)
      end.to_not raise_error
    end

    it "logs when there is an error" do
      begin
        old_logger = Braintree::Configuration.logger
        output = StringIO.new
        Braintree::Configuration.logger = Logger.new(output)
        context = OpenSSL::X509::StoreContext.new(OpenSSL::X509::Store.new)
        context.error = 19
        expect(Braintree::Configuration.instantiate.http._verify_ssl_certificate(false, context)).to eq(false)
        expect(output.string).to include("SSL Verification failed -- Preverify: false, Error: self signed certificate in certificate chain (19)")
      ensure
        Braintree::Configuration.logger = old_logger
      end
    end

    it "doesn't log when there is not an error" do
      begin
        old_logger = Braintree::Configuration.logger
        output = StringIO.new
        Braintree::Configuration.logger = Logger.new(output)
        context = OpenSSL::X509::StoreContext.new(OpenSSL::X509::Store.new)
        expect do
          Braintree::Configuration.instantiate.http._verify_ssl_certificate(true, context)
        end.to_not raise_error
        expect(output.string).to eq("")
      ensure
        Braintree::Configuration.logger = old_logger
      end
    end
  end
end
