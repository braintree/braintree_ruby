module Braintree
  class DocumentUpload
    include BaseModule

    module Kind
      IdentityDocument          = "identity_document"
      EvidenceDocument          = "evidence_document"
      PayoutInvoiceDocument     = "payout_invoice_document"
    end

    attr_reader :content_type
    attr_reader :id
    attr_reader :kind
    attr_reader :name
    attr_reader :size

    def self.create(attributes)
      Configuration.gateway.document_upload.create(attributes)
    end

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end

    # True if <tt>other</tt> has the same id.
    def ==(other)
      return false unless other.is_a?(DocumentUpload)
      id == other.id
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end
  end
end
