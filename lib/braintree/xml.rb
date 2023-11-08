module Braintree
  module Xml
    def self.hash_from_xml(xml)
      Parser.hash_from_xml(xml)
    end

    def self.hash_to_xml(hash)
      Generator.hash_to_xml(hash)
    end
  end
end
