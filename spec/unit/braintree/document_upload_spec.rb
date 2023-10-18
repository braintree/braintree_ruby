require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::DocumentUpload do
  describe "initialize" do
    it "sets attributes" do
      response = {:size => 555, :kind => "evidence_document", :name => "up_file.pdf", :content_type => "application/pdf", :id => "my_id"}
      document_upload = Braintree::DocumentUpload._new(response)
      expect(document_upload.id).to eq("my_id")
      expect(document_upload.size).to eq(555)
      expect(document_upload.name).to eq("up_file.pdf")
      expect(document_upload.content_type).to eq("application/pdf")
      expect(document_upload.kind).to eq(Braintree::DocumentUpload::Kind::EvidenceDocument)
    end
  end

  describe "kind" do
    it "sets identity document" do
      response = {:size => 555, :kind => "identity_document", :name => "up_file.pdf", :content_type => "application/pdf", :id => "my_id"}
      document_upload = Braintree::DocumentUpload._new(response)
      expect(document_upload.kind).to eq(Braintree::DocumentUpload::Kind::IdentityDocument)
    end

    it "sets evidence document" do
      response = {:size => 555, :kind => "evidence_document", :name => "up_file.pdf", :content_type => "application/pdf", :id => "my_id"}
      document_upload = Braintree::DocumentUpload._new(response)
      expect(document_upload.kind).to eq(Braintree::DocumentUpload::Kind::EvidenceDocument)
    end

    it "sets payout invoice document" do
      response = {:size => 555, :kind => "payout_invoice_document", :name => "up_file.pdf", :content_type => "application/pdf", :id => "my_id"}
      document_upload = Braintree::DocumentUpload._new(response)
      expect(document_upload.kind).to eq(Braintree::DocumentUpload::Kind::PayoutInvoiceDocument)
    end
  end
end
