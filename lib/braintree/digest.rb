module Braintree
  module Digest # :nodoc:
    def self.hexdigest(private_key, string)
      _hmac_sha1(private_key, string)
    end

    def self.secure_compare(left, right)
      return false unless left.bytesize == right.bytesize

      left_bytes = left.unpack "C#{left.bytesize}"

      result = 0
      right.each_byte { |byte| result |= byte ^ left_bytes.shift }
      result == 0
    end

    def self._hmac_sha1(key, message)
      key_digest = ::Digest::SHA1.digest(key)
      sha1 = OpenSSL::Digest::Digest.new("sha1")
      OpenSSL::HMAC.hexdigest(sha1, key_digest, message.to_s)
    end
  end
end
