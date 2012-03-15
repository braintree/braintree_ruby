module Braintree
  module Digest # :nodoc:
    def self.hexdigest(private_key, string)
      _hmac_sha1(private_key, string)
    end

    def self.secure_compare(left, right)
      return false unless _bytesize(left) == _bytesize(right)

      result = 0
      left.bytes.zip(right.bytes).each do |left_byte, right_byte|
        result |= left_byte ^ right_byte
      end
      result == 0
    end

    def self._hmac_sha1(key, message)
      key_digest = ::Digest::SHA1.digest(key)
      sha1 = OpenSSL::Digest::Digest.new("sha1")
      OpenSSL::HMAC.hexdigest(sha1, key_digest, message.to_s)
    end

    def self._bytesize(string)
      string.bytes.to_a.size
    end
  end
end
