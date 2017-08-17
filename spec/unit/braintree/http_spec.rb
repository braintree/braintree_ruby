require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

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

    it "sanitizes credit card number and cvv with newlines" do
      input_xml = <<-END
<customer>
  <first-name>Joe</first-name>
  <last-name>Doe</last-name>
  <number>123456000\n0001234</number>
  <cvv>1\n23</cvv>
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

    it "connects when proxy address is specified" do
      config = Braintree::Configuration.new(
        :proxy_address => "localhost",
        :proxy_port => 8080,
        :proxy_user => "user",
        :proxy_pass => "test"
      )

      http = Braintree::Http.new(config)
      net_http_instance = instance_double(
        "Net::HTTP",
        :open_timeout= => nil,
        :read_timeout= => nil,
        :start => nil
      )

      Net::HTTP.should_receive(:new).with(nil, nil, "localhost", 8080, "user", "test").and_return(net_http_instance)

      http._http_do("GET", "/plans")
    end

    it "accepts a partially specified proxy" do
      config = Braintree::Configuration.new(
        :proxy_address => "localhost",
        :proxy_port => 8080
      )

      http = Braintree::Http.new(config)
      net_http_instance = instance_double(
        "Net::HTTP",
        :open_timeout= => nil,
        :read_timeout= => nil,
        :start => nil
      )

      Net::HTTP.should_receive(:new).with(nil, nil, "localhost", 8080, nil, nil).and_return(net_http_instance)

      http._http_do("GET", "/plans")
    end

    it "does not specify a proxy if proxy_address is not set" do
      config = Braintree::Configuration.new
      http = Braintree::Http.new(config)
      net_http_instance = instance_double(
        "Net::HTTP",
        :open_timeout= => nil,
        :read_timeout= => nil,
        :start => nil
      )

      Net::HTTP.should_receive(:new).with(nil, nil).and_return(net_http_instance)

      http._http_do("GET", "/plans")
    end
  end

  describe "_build_query_string" do
    it "returns an empty string for empty query params" do
      Braintree::Http.new(:config)._build_query_string({}).should == ""
    end

    it "returns a proper query string for non-nested hashes" do
      query_params = {:one => 1, :two => 2}

      Braintree::Http.new(:config)._build_query_string(query_params).should =~ /^\?(one=1&two=2|two=2&one=1)$/
    end

    it "raises ArgumentError for nested hashes" do
      query_params = {:one => 1, :two => {:a => 2.1, :b => 2.2}}
      expect {
        Braintree::Http.new(:config)._build_query_string(query_params)
      }.to raise_error(ArgumentError, /nested hash/i)
    end
  end
end
