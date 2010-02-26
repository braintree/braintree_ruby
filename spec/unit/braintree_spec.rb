require File.dirname(__FILE__) + "/spec_helper"

describe Braintree do
  it "doesn't produce warnings if loading braintree.rb twice" do
    lib_dir = File.dirname(__FILE__) + "/../../lib"
    braintree_file = "#{lib_dir}/braintree.rb"
    File.exist?(braintree_file).should == true
    output = `ruby -r rubygems -I #{lib_dir} -e 'load #{braintree_file.inspect}; load #{braintree_file.inspect}' 2>&1`
    output.should == ""
  end
end
