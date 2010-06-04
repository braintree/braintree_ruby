module Braintree
  module SSLExpirationCheck # :nodoc:
    class << self
      attr_reader :ssl_expiration_dates_checked
    end

    def self.check_dates # :nodoc:
      {
        "Sandbox" => sandbox_expiration_date,
        "Production" => production_expiration_date
      }.each do |host, expiration_date|
        if Date.today + (3 * 30) > expiration_date
          Configuration.logger.warn "[Braintree] The SSL Certificate for the #{host} environment will expire on #{expiration_date}. Please check for an updated client library."
        end
      end
      @ssl_expiration_dates_checked = true
    end

    def self.production_expiration_date # :nodoc:
      Date.civil(2012, 1, 8)
    end

    def self.sandbox_expiration_date # :nodoc:
      Date.civil(2010, 12, 1)
    end
  end
end
