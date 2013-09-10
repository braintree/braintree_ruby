module Braintree
  class SignatureService
    def initialize(key, digest=Braintree::Digest)
      @key = key
      @digest = digest
    end

    def sign(data)
      url_encoded_data = Util.hash_to_query_string(data)
      "#{hash(url_encoded_data)}|#{url_encoded_data}"
    end

    def hash(data)
      @digest.hexdigest(@key, data)
    end
  end
end
