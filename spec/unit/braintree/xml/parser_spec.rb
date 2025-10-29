require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Xml::Parser do
  describe "self.hash_from_xml" do
    it "typecasts integers" do
      xml = "<root><foo type=\"integer\">123</foo></root>"
      expect(xml).to parse_to(:root => {:foo => 123})
    end

    it "works with dashes or underscores" do
      xml = <<-END
        <root>
          <dash-es />
          <under_scores />
        </root>
      END
      expect(xml).to parse_to(:root=>{:dash_es=>"", :under_scores=>""})
    end

    it "uses nil if nil=true, otherwise uses empty string" do
      xml = <<-END
        <root>
          <a_nil_value nil="true"></a_nil_value>
          <an_empty_string></an_empty_string>
        </root>
      END
      expect(xml).to parse_to(:root => {:a_nil_value => nil, :an_empty_string => ""})
    end

    it "typecasts datetimes" do
      xml = <<-END
        <root>
          <created-at type="datetime">2009-10-28T10:19:49Z</created-at>
        </root>
      END
      expect(xml).to parse_to(:root => {:created_at => Time.utc(2009, 10, 28, 10, 19, 49)})
    end

    it "doesn't typecast dates" do
      xml = <<-END
        <root>
          <created-at type="date">2009-10-28</created-at>
        </root>
      END
      expect(xml).to parse_to(:root => {:created_at => "2009-10-28"})
    end

    it "builds an array if type=array" do
      xml = <<-END
        <root>
          <customers type="array">
            <customer><name>Adam</name></customer>
            <customer><name>Ben</name></customer>
          </customers>
        </root>
      END
      expect(xml).to parse_to(:root => {:customers => [{:name => "Adam"}, {:name => "Ben"}]})
    end

    it "parses an array" do
      xml = <<-END
        <root>
          <customers type="array">
            <customer><name>Adam</name><customer-id>1</customer-id></customer>
            <customer><name>Ben</name><customer-id>2</customer-id></customer>
          </customers>
        </root>
      END
      expect(xml).to parse_to(:root => {:customers => [{:name => "Adam", :customer_id => "1"}, {:name => "Ben", :customer_id => "2"}]})
    end

    it "parses nested objects" do
      xml = <<-END
        <root>
          <paypal-details>
            <deets type="array"><super-secrets><secret-code>1234</secret-code></super-secrets></deets>
            <payer-email>abc@test.com</payer-email>
            <payment-id>1234567890</payment-id>
          </paypal-details>
        </root>
      END
      expect(xml).to parse_to(:root => {:paypal_details => {:deets => [{:secret_code => "1234"}], :payer_email => "abc@test.com", :payment_id => "1234567890"}})
    end

    it "does not collapse nested structures with single-child elements" do
      xml = "<api-error-response><message>Test</message><errors><errors type=\"array\"></errors></errors></api-error-response>"
      expect(xml).to parse_to({:api_error_response=>{:message=>"Test", :errors=>{:errors=>[]}}})
    end

    it "preserves hash structure when one key has array value" do
      xml = <<-END
        <root>
          <message>Error message</message>
          <items type="array">
            <item>Value1</item>
          </items>
        </root>
      END
      expect(xml).to parse_to({:root => {:message => "Error message", :items => ["Value1"]}})
    end

    it "handles error response with nested errors correctly" do
      xml = <<-END
        <api-error-response>
          <message>Validation failed</message>
          <errors>
            <errors type="array">
              <error>
                <code>81234</code>
                <message>Field is required</message>
              </error>
            </errors>
          </errors>
        </api-error-response>
      END
      expect(xml).to parse_to({
        :api_error_response => {
          :message => "Validation failed",
          :errors => {
            :errors => [{:code => "81234", :message => "Field is required"}]
          }
        }
      })
    end

    it "handles client token error response structure" do
      xml = <<-END
        <api-error-response>
          <message>Invalid request</message>
          <errors>
            <errors type="array"></errors>
          </errors>
        </api-error-response>
      END
      result = Braintree::Xml::Parser.hash_from_xml(xml)
      expect(result[:api_error_response]).to be_a(Hash)
      expect(result[:api_error_response][:message]).to eq("Invalid request")
      expect(result[:api_error_response][:errors]).to be_a(Hash)
      expect(result[:api_error_response][:errors][:errors]).to eq([])
    end
  end
end
