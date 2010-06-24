require File.dirname(__FILE__) + "/../spec_helper"

# Helper method to confirm we have the right values
def fetch_expiration_date(host, port=443)
  cmd = "echo | openssl s_client -connect #{host}:#{port} 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -noout -subject -dates | grep notAfter"
  date = `#{cmd}`.sub(/^.*=/, '')

  Date.parse(date)
end

describe Braintree::SSLExpirationCheck do
  SANDBOX = "sandbox.braintreegateway.com"
  PRODUCTION = "www.braintreegateway.com"

  describe "check_dates" do
    it "is done when the client library is loaded" do
      Braintree::SSLExpirationCheck.ssl_expiration_dates_checked.should == true
    end

    describe "Sandbox Cert" do
      it "logs when the cert is expired" do
        Braintree::SSLExpirationCheck.stub(:sandbox_expiration_date).and_return(Date.today - 1)

        output = StringIO.new
        Braintree::Configuration.logger = Logger.new(output)
        Braintree::Configuration.logger.level = Logger::WARN

        Braintree::SSLExpirationCheck.check_dates

        output.string.should match(/\[Braintree\] The SSL Certificate for the Sandbox environment will expire on \d{4}-\d{2}-\d{2}\. Please check for an updated client library\./)
      end

      it "logs when the cert is close to expiring" do
        Braintree::SSLExpirationCheck.stub(:sandbox_expiration_date).and_return(Date.today)
        output = StringIO.new
        Braintree::Configuration.logger = Logger.new(output)
        Braintree::Configuration.logger.level = Logger::WARN

        Braintree::SSLExpirationCheck.check_dates

        output.string.should match(/\[Braintree\] The SSL Certificate for the Sandbox environment will expire on \d{4}-\d{2}-\d{2}\. Please check for an updated client library\./)
      end

      it "doesn't log when the cert is not expired" do
        Braintree::SSLExpirationCheck.stub(:sandbox_expiration_date).and_return(Date.today + 365)
        output = StringIO.new
        Braintree::Configuration.logger = Logger.new(output)
        Braintree::Configuration.logger.level = Logger::WARN

        Braintree::SSLExpirationCheck.check_dates

        output.string.should == ""
      end
    end

    # We assume that testing logging for one is good enough for all, so we won't duplicate those tests from above
    it "checks the sandbox cert" do
      Braintree::SSLExpirationCheck.stub(:sandbox_expiration_date).and_return(Date.today)
      output = StringIO.new
      Braintree::Configuration.logger = Logger.new(output)
      Braintree::Configuration.logger.level = Logger::WARN

      Braintree::SSLExpirationCheck.check_dates

      output.string.should match(/\[Braintree\] The SSL Certificate for the Sandbox environment will expire on \d{4}-\d{2}-\d{2}\. Please check for an updated client library\./)
    end

    it "checks the production server cert" do
      Braintree::SSLExpirationCheck.stub(:production_expiration_date).and_return(Date.today)
      output = StringIO.new
      Braintree::Configuration.logger = Logger.new(output)
      Braintree::Configuration.logger.level = Logger::WARN

      Braintree::SSLExpirationCheck.check_dates

      output.string.should match(/\[Braintree\] The SSL Certificate for the Production environment will expire on \d{4}-\d{2}-\d{2}\. Please check for an updated client library\./)
    end
  end

  describe "production_expiration_date" do
    it "is the date the production cert expires" do
      Braintree::SSLExpirationCheck.production_expiration_date.should be_a(Date)
      Braintree::SSLExpirationCheck.production_expiration_date.should == fetch_expiration_date(PRODUCTION)
    end
  end

  describe "sandbox_expiration_date" do
    it "is the date the Sandbox cert expires" do
      Braintree::SSLExpirationCheck.sandbox_expiration_date.should be_a(Date)
      Braintree::SSLExpirationCheck.sandbox_expiration_date.should == fetch_expiration_date(SANDBOX)
    end
  end
end
