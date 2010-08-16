module Braintree
  module Digest # :nodoc:
    def self.hexdigest(private_key, string)
      _hmac_sha1(private_key, string)
    end

    def self._hmac_sha1(key, message)
      key_digest = ::Digest::SHA1.digest(key)
      sha1 = OpenSSL::Digest::Digest.new("sha1")
      OpenSSL::HMAC.hexdigest(sha1, key_digest, message.to_s)
    end
  end
end

