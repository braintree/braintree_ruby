require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Util do
  describe "self.symbolize_keys" do
    it "does not modify the hash" do
      original = {"a" => "b", "c" => "d"}
      new = Braintree::Util.symbolize_keys(original)

      expect(original["a"]).to eq("b")
      expect(new[:a]).to eq("b")
    end

    it "symbolizes nested keys" do
      hash = {"a" => {"b" => {"c" => "d"}}}
      expect(Braintree::Util.symbolize_keys(hash)).to eq({:a => {:b => {:c => "d"}}})
    end

    it "symbolizes nested keys in arrays" do
      hash = {"a" => ["b" => {"c" => "d"}]}
      expect(Braintree::Util.symbolize_keys(hash)).to eq({:a => [:b => {:c => "d"}]})
    end
  end

  describe "self.verify_keys" do
    it "raises an exception if the hash contains an invalid key" do
      expect do
        Braintree::Util.verify_keys([:allowed], :allowed => "ok", :disallowed => "bad")
      end.to raise_error(ArgumentError, "invalid keys: disallowed")
    end

    it "raises an exception with all keys listed if the hash contains invalid keys" do
      expect do
        Braintree::Util.verify_keys([:allowed], :allowed => "ok", :disallowed => "bad", "also_invalid" => true)
      end.to raise_error(ArgumentError, "invalid keys: also_invalid, disallowed")
    end

    it "raises an exception if a nested hash contains an invalid key" do
      expect do
        Braintree::Util.verify_keys(
          [:allowed, {:nested => [:nested_allowed, :nested_allowed2]}],
          :allowed => "ok",
          :top_level_invalid => "bad",
          :nested => {
            :nested_allowed => "ok",
            :nested_allowed2 => "also ok",
            :nested_invalid => "bad"
          },
        )
      end.to raise_error(ArgumentError, "invalid keys: nested[nested_invalid], top_level_invalid")
    end

    it "does not raise an exception for wildcards" do
      expect do
        Braintree::Util.verify_keys(
          [:allowed, {:custom_fields => :_any_key_}],
          :allowed => "ok",
          :custom_fields => {
            :custom_allowed => "ok",
            :custom_allowed2 => "also ok",
          },
        )
      end.to_not raise_error
    end

    it "raise an exception for wildcards at different nesting" do
      expect do
        Braintree::Util.verify_keys(
          [:allowed, {:custom_fields => :_any_key_}],
          :allowed => {
            :custom_fields => {
              :bad_nesting => "very bad"
            }
          },
        )
      end.to raise_error(ArgumentError, "invalid keys: allowed[custom_fields][bad_nesting]")
    end

    it "raises an exception if a deeply nested hash contains an invalid key" do
      expect do
        Braintree::Util.verify_keys(
          [:allowed, {:nested => [:nested_allowed, :nested_allowed2, {:deeply_allowed => [:super_deep_allowed]}]}],
          :allowed => "ok",
          :top_level_invalid => "bad",
          :nested => {
            :nested_allowed => "ok",
            :nested_allowed2 => "also ok",
            :nested_invalid => "bad",
            :deeply_allowed => {
              :super_deep_allowed => "yep",
              :real_deep_invalid => "nope"
            }
          },
        )
      end.to raise_error(ArgumentError, "invalid keys: nested[deeply_allowed][real_deep_invalid], nested[nested_invalid], top_level_invalid")
    end

    it "does not raise an error for array values" do
      expect do
        Braintree::Util.verify_keys(
          [{:add_ons => [{:update => [:amount]}, {:add => [:amount]}]}],
          :add_ons => {
            :update => [{:amount => 10}],
            :add => [{:amount => 5}]
          },
        )
      end.to_not raise_error
    end

    it "raises an error for invalid key inside of array" do
      expect do
        Braintree::Util.verify_keys(
          [{:add_ons => [{:update => [:amount]}, {:add => [:amount]}]}],
          :add_ons => {
            :update => [{:foo => 10}],
            :add => [{:bar => 5}]
          },
        )
      end.to raise_error(ArgumentError, /invalid keys: add_ons\[add\]\[bar\], add_ons\[update\]\[foo\]/)
    end
  end

  describe "self.keys_valid?" do
    it "returns true for wildcard matches" do
      response = Braintree::Util.keys_valid?(
        [:allowed, {:custom_fields => :_any_key_}],
        :allowed => "ok",
        :custom_fields => {
          :custom_allowed => "ok",
          :custom_allowed2 => "also ok",
        },
      )
      expect(response).to eq(true)
    end
    it "raises an exception if the hash contains an invalid key" do
      response = Braintree::Util.keys_valid?([:allowed], :allowed => "ok", :disallowed => "bad")
      expect(response).to eq(false)
    end

    it "raises an exception with all keys listed if the hash contains invalid keys" do
      response = Braintree::Util.keys_valid?([:allowed], :allowed => "ok", :disallowed => "bad", "also_invalid" => true)
      expect(response).to eq(false)
    end

    it "returns false for invalid key inside of array" do
      response = Braintree::Util.keys_valid?(
        [{:add_ons => [{:update => [:amount]}, {:add => [:amount]}]}],
        :add_ons => {
          :update => [{:foo => 10}],
          :add => [{:bar => 5}]
        },
      )
      expect(response).to eq(false)
    end

    it "returns false if a deeply nested hash contains an invalid key" do
      response = Braintree::Util.keys_valid?(
        [:allowed, {:nested => [:nested_allowed, :nested_allowed2, {:deeply_allowed => [:super_deep_allowed]}]}],
        :allowed => "ok",
        :top_level_invalid => "bad",
        :nested => {
          :nested_allowed => "ok",
          :nested_allowed2 => "also ok",
          :nested_invalid => "bad",
          :deeply_allowed => {
            :super_deep_allowed => "yep",
            :real_deep_invalid => "nope"
          }
        },
      )
      expect(response).to eq(false)
    end
  end

  describe "self.replace_key" do
    it "replaces the target key with the replacement key" do
      expect(Braintree::Util.replace_key(
        {:a => {:b => "some value"}},
        :b,
        :c)).to eq({:a => {:c => "some value"}})
    end

    it "returns hash with all of the original keys if the target key does not exist" do
      expect(Braintree::Util.replace_key(
        {:some_key => "some value"},
        :not_found,
        :new_key)).to eq({:some_key => "some value"})
    end
  end

  describe "self._flatten_hash_keys" do
    it "flattens hash keys" do
      expect(Braintree::Util._flatten_hash_keys(:nested => {
        :nested_allowed => "ok",
        :nested_allowed2 => "also ok",
        :nested_invalid => "bad"
      })).to eq(["nested[nested_allowed2]", "nested[nested_allowed]", "nested[nested_invalid]"])
    end
  end

  describe "self._flatten_valid_keys" do
    it "flattens hash keys" do
      expect(Braintree::Util._flatten_valid_keys(
        [:top_level, {:nested => [:nested_allowed, :nested_allowed2]}],
      )).to eq(["nested[nested_allowed2]", "nested[nested_allowed]", "top_level"])
    end

    it "allows wildcards with the :_any_key_ symbol" do
      expect(Braintree::Util._flatten_valid_keys(
        [:top_level, {:nested => :_any_key_}],
      )).to eq(["nested[_any_key_]", "top_level"])
    end
  end

  describe "self.extract_attribute_as_array" do
    it "deletes the attribute from the hash" do
      hash = {:foo => ["x"], :bar => :baz}
      Braintree::Util.extract_attribute_as_array(hash, :foo)
      expect(hash).to eq({:bar => :baz})
    end

    it "puts the attribute in an array if it's not an array" do
      hash = {:foo => "x", :bar => :baz}
      result = Braintree::Util.extract_attribute_as_array(hash, :foo)
      expect(result).to eq(["x"])
    end

    it "returns the value if it's already an array" do
      hash = {:foo => ["one", "two"], :bar => :baz}
      result = Braintree::Util.extract_attribute_as_array(hash, :foo)
      expect(result).to eq(["one", "two"])
    end

    it "returns empty array if the attribute is not in the hash" do
      hash = {:foo => ["one", "two"], :bar => :baz}
      result = Braintree::Util.extract_attribute_as_array(hash, :quz)
      expect(result).to eq([])
    end

    it "raises an UnexpectedError if nil data is provided" do
      expect do
        Braintree::Util.extract_attribute_as_array(nil, :abc)
      end.to raise_error(Braintree::UnexpectedError, /Unprocessable entity due to an invalid request/)
    end
  end

  describe "self.hash_to_query_string" do
    it "generates a query string from the hash" do
      hash = {:foo => {:key_one => "value_one", :key_two => "value_two"}}
      expect(Braintree::Util.hash_to_query_string(hash)).to eq("foo%5Bkey_one%5D=value_one&foo%5Bkey_two%5D=value_two")
    end

    it "works for nesting 2 levels deep" do
      hash = {:foo => {:nested => {:key_one => "value_one", :key_two => "value_two"}}}
      expect(Braintree::Util.hash_to_query_string(hash)).to eq("foo%5Bnested%5D%5Bkey_one%5D=value_one&foo%5Bnested%5D%5Bkey_two%5D=value_two")
    end
  end

  describe "self.parse_query_string" do
    it "parses the query string" do
      query_string = "foo=bar%20baz&hash=a1b2c3"
      expect(Braintree::Util.parse_query_string(query_string)).to eq({:foo => "bar baz", :hash => "a1b2c3"})
    end

    it "parses the query string when a key has an empty value" do
      query_string = "foo=bar%20baz&hash=a1b2c3&vat_number="
      expect(Braintree::Util.parse_query_string(query_string)).to eq({:foo => "bar baz", :hash => "a1b2c3", :vat_number => ""})
    end
  end

  describe "self.raise_exception_for_graphql_error" do
    errors = {
      "AUTHENTICATION" => Braintree::AuthenticationError,
      "AUTHORIZATION" => Braintree::AuthorizationError,
      "NOT_FOUND" => Braintree::NotFoundError,
      "UNSUPPORTED_CLIENT" => Braintree::UpgradeRequiredError,
      "RESOURCE_LIMIT" => Braintree::TooManyRequestsError,
      "INTERNAL" => Braintree::ServerError,
      "SERVICE_AVAILABILITY" => Braintree::ServiceUnavailableError,
    }

    errors.each do |graphQLError, exception|
      it "raises an #{exception} when GraphQL returns an #{graphQLError} error" do
        response = {
          errors: [{
            extensions: {
              errorClass: graphQLError
            }
          }]
        }
        expect do
          Braintree::Util.raise_exception_for_graphql_error(response)
        end.to raise_error(exception)
      end
    end

    it "does not raise an exception when GraphQL returns a validation error" do
      response = {
        errors: [{
          extensions: {
            errorClass: "VALIDATION"
          }
        }]
      }
      expect do
        Braintree::Util.raise_exception_for_graphql_error(response)
      end.to_not raise_error()
    end

    it "raises any non-validation errorClass response" do
      response = {
        errors: [{
          extensions: {
            errorClass: "VALIDATION"
          }
        }, {
          extensions: {
            errorClass: "NOT_FOUND"
          }
        }]
      }
      expect do
        Braintree::Util.raise_exception_for_graphql_error(response)
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.raise_exception_for_status_code" do
    it "raises an AuthenticationError if authentication fails" do
      expect do
        Braintree::Util.raise_exception_for_status_code(401)
      end.to raise_error(Braintree::AuthenticationError)
    end

    it "raises an AuthorizationError if authorization fails" do
      expect do
        Braintree::Util.raise_exception_for_status_code(403)
      end.to raise_error(Braintree::AuthorizationError)
    end

    it "raises a NotFoundError if resource is not found" do
      expect do
        Braintree::Util.raise_exception_for_status_code(404)
      end.to raise_error(Braintree::NotFoundError)
    end

    it "raises a RequestTimeoutError if the request times out" do
      expect do
        Braintree::Util.raise_exception_for_status_code(408)
      end.to raise_error(Braintree::RequestTimeoutError)
    end

    it "raises an UpgradeRequired if the client library is EOL'd" do
      expect do
        Braintree::Util.raise_exception_for_status_code(426)
      end.to raise_error(Braintree::UpgradeRequiredError, "Please upgrade your client library.")
    end

    it "raises a TooManyRequestsError if the rate limit threshold is exceeded" do
      expect do
        Braintree::Util.raise_exception_for_status_code(429)
      end.to raise_error(Braintree::TooManyRequestsError)
    end

    it "raises a ServerError if the server 500's" do
      expect do
        Braintree::Util.raise_exception_for_status_code(500)
      end.to raise_error(Braintree::ServerError)
    end

    it "raises a ServiceUnavailableError if the server is unavailable" do
      expect do
        Braintree::Util.raise_exception_for_status_code(503)
      end.to raise_error(Braintree::ServiceUnavailableError)
    end

    it "raises a GatewayTimeoutError if the gateway times out" do
      expect do
        Braintree::Util.raise_exception_for_status_code(504)
      end.to raise_error(Braintree::GatewayTimeoutError)
    end

    it "raises an UnexpectedError if some other code is returned" do
      expect do
        Braintree::Util.raise_exception_for_status_code(600)
      end.to raise_error(Braintree::UnexpectedError, "Unexpected HTTP_RESPONSE 600")
    end
  end

  describe "self.to_big_decimal" do
    it "returns the BigDecimal when given a BigDecimal" do
      expect(Braintree::Util.to_big_decimal(BigDecimal("12.34"))).to eq(BigDecimal("12.34"))
    end

    it "returns a BigDecimal when given a string" do
      expect(Braintree::Util.to_big_decimal("12.34")).to eq(BigDecimal("12.34"))
    end

    it "returns nil when given nil" do
      expect(Braintree::Util.to_big_decimal(nil)).to be_nil
    end

    it "blows up when not given a String or BigDecimal" do
      expect {
        Braintree::Util.to_big_decimal(12.34)
      }.to raise_error(/Argument must be a String or BigDecimal/)
    end
  end

  describe "self.url_encode" do
    it "url encodes the given text" do
      expect(Braintree::Util.url_encode("foo?bar")).to eq("foo%3Fbar")
    end
  end

  describe "self.url_decode" do
    it "url decodes the given text" do
      expect(Braintree::Util.url_decode("foo%3Fbar")).to eq("foo?bar")
    end
  end
end
