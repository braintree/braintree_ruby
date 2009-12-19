module Braintree
  module Digest # :nodoc:
    def self.hexdigest(string)
      _hmac_sha1(Configuration.private_key, string)
    end

    def self._hmac_sha1(key, message)
      key_digest = ::Digest::SHA1.digest(key)
      inner_padding = "\x36" * 64
      outer_padding = "\x5c" * 64
      0.upto(19) do |i|
        inner_padding[i] ^= key_digest[i]
        outer_padding[i] ^= key_digest[i]
      end
      inner_hash = ::Digest::SHA1.digest(inner_padding + message.to_s)
      ::Digest::SHA1.hexdigest(outer_padding + inner_hash)
    end
  end
end

