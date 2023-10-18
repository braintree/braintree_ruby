require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::DocumentUploadGateway do
  describe "create" do
    it "returns successful with valid request" do
      file = File.new("#{File.dirname(__FILE__)}/../../fixtures/files/bt_logo.png", "r")
      response = Braintree::DocumentUpload.create({:kind => Braintree::DocumentUpload::Kind::EvidenceDocument, :file => file})
      document_upload = response.document_upload

      expect(response.success?).to eq(true)
      expect(document_upload.id).not_to be_nil
      expect(document_upload.content_type).to eq("image/png")
      expect(document_upload.kind).to eq(Braintree::DocumentUpload::Kind::EvidenceDocument)
      expect(document_upload.name).to eq("bt_logo.png")
      expect(document_upload.size).to eq(2443)
    end

    it "returns file type error with unsupported file type" do
      file = File.new("#{File.dirname(__FILE__)}/../../fixtures/files/gif_extension_bt_logo.gif", "r")
      response = Braintree::DocumentUpload.create({:kind => Braintree::DocumentUpload::Kind::EvidenceDocument, :file => file})
      expect(response.errors.for(:document_upload).first.code).to eq(Braintree::ErrorCodes::DocumentUpload::FileTypeIsInvalid)
    end

    it "returns malformed error with malformed file" do
      file = File.new("#{File.dirname(__FILE__)}/../../fixtures/files/malformed_pdf.pdf", "r")
      response = Braintree::DocumentUpload.create({:kind => Braintree::DocumentUpload::Kind::EvidenceDocument, :file => file})
      expect(response.errors.for(:document_upload).first.code).to eq(Braintree::ErrorCodes::DocumentUpload::FileIsMalformedOrEncrypted)
    end

    it "returns invalid kind error with invalid kind" do
      file = File.new("#{File.dirname(__FILE__)}/../../fixtures/files/bt_logo.png", "r")
      response = Braintree::DocumentUpload.create({:kind => "invalid_kind", :file => file})
      expect(response.errors.for(:document_upload).first.code).to eq(Braintree::ErrorCodes::DocumentUpload::KindIsInvalid)
    end

    it "returns file too large error with file over 4mb" do
      filename = "#{File.dirname(__FILE__)}/../../fixtures/files/large_file.png"
      begin
        write_times = 1048577 * 4
        File.open(filename, "w+") { |f| write_times.times { f.write "a" } }
        file = File.new(filename, "r")
        response = Braintree::DocumentUpload.create({:kind => Braintree::DocumentUpload::Kind::EvidenceDocument, :file => file})
        expect(response.errors.for(:document_upload).first.code).to eq(Braintree::ErrorCodes::DocumentUpload::FileIsTooLarge)
      ensure
        File.delete(filename)
      end
    end

    it "returns file is empty error with empty file" do
      filename = "#{File.dirname(__FILE__)}/../../fixtures/files/empty_file.png"
      begin
        File.open(filename, "w+") {}
        file = File.new(filename, "r")
        response = Braintree::DocumentUpload.create({:kind => Braintree::DocumentUpload::Kind::EvidenceDocument, :file => file})
        expect(response.errors.for(:document_upload).first.code).to eq(Braintree::ErrorCodes::DocumentUpload::FileIsEmpty)
      ensure
        File.delete(filename)
      end
    end

    it "returns file too long error with file over 50 pages" do
      filename = "#{File.dirname(__FILE__)}/../../fixtures/files/too_long.pdf"
      file = File.new(filename, "r")
      response = Braintree::DocumentUpload.create({:kind => Braintree::DocumentUpload::Kind::EvidenceDocument, :file => file})
      expect(response.errors.for(:document_upload).first.code).to eq(Braintree::ErrorCodes::DocumentUpload::FileIsTooLong)
    end

    it "returns invalid keys error if signature is invalid" do
      expect do
        response = Braintree::DocumentUpload.create({:invalid_key => "do not add", :kind => Braintree::DocumentUpload::Kind::EvidenceDocument})
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "create!" do
    it "returns successful with valid request" do
      file = File.new("#{File.dirname(__FILE__)}/../../fixtures/files/bt_logo.png", "r")
      document_upload = Braintree::DocumentUpload.create!({:kind => Braintree::DocumentUpload::Kind::EvidenceDocument, :file => file})

      expect(document_upload.id).not_to be_nil
      expect(document_upload.content_type).to eq("image/png")
      expect(document_upload.kind).to eq(Braintree::DocumentUpload::Kind::EvidenceDocument)
      expect(document_upload.name).to eq("bt_logo.png")
      expect(document_upload.size).to eq(2443)
    end
  end
end
