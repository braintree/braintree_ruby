require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Http do
  describe "self._format_and_sanitize_body_for_log" do
    it "adds [Braintree] before each line" do
      input_xml = <<-END
<customer>
  <first-name>Joe</first-name>
  <last-name>Doe</last-name>
</customer>
END
      expected_xml = <<-END
[Braintree] <customer>
[Braintree]   <first-name>Joe</first-name>
[Braintree]   <last-name>Doe</last-name>
[Braintree] </customer>
END
      Braintree::Http.new(:config)._format_and_sanitize_body_for_log(input_xml).should == expected_xml
    end

    it "sanitizes credit card number and cvv" do
      input_xml = <<-END
<customer>
  <first-name>Joe</first-name>
  <last-name>Doe</last-name>
  <number>1234560000001234</number>
  <cvv>123</cvv>
</customer>
      END

      expected_xml = <<-END
[Braintree] <customer>
[Braintree]   <first-name>Joe</first-name>
[Braintree]   <last-name>Doe</last-name>
[Braintree]   <number>123456******1234</number>
[Braintree]   <cvv>***</cvv>
[Braintree] </customer>
END
      Braintree::Http.new(:config)._format_and_sanitize_body_for_log(input_xml).should == expected_xml
    end
  end
end
