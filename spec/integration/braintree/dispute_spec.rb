# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Dispute do
  let(:document_upload) do
    file = File.new("#{File.dirname(__FILE__)}/../../fixtures/files/bt_logo.png", "r")
    response = Braintree::DocumentUpload.create({:kind => Braintree::DocumentUpload::Kind::EvidenceDocument, :file => file})
    response.document_upload
  end

  let(:transaction) do
    result = Braintree::Transaction.sale(
      :amount => "10.00",
      :credit_card => {
        :expiration_date => "01/2020",
        :number => Braintree::Test::CreditCardNumbers::Disputes::Chargeback
      },
      :options => {
        :submit_for_settlement => true
      },
    )

    result.transaction
  end

  let(:dispute) { transaction.disputes.first }

  describe "self.accept" do
    it "changes the dispute status to accepted" do
      result = Braintree::Dispute.accept(dispute.id)

      expect(result.success?).to eq(true)

      updated_dispute = Braintree::Dispute.find(dispute.id)
      expect(updated_dispute.status).to eq(Braintree::Dispute::Status::Accepted)

      dispute_from_transaction = Braintree::Transaction.find(dispute.transaction.id).disputes[0]
      expect(dispute_from_transaction.status).to eq(Braintree::Dispute::Status::Accepted)
    end

    it "returns an error response if the dispute is not in open status" do
      result = Braintree::Dispute.accept("wells_dispute")

      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::CanOnlyAcceptOpenDispute)
      expect(result.errors.for(:dispute)[0].message).to eq("Disputes can only be accepted when they are in an Open state")
    end

    it "raises a NotFound exception if the dispute cannot be found" do
      expect do
        Braintree::Dispute.accept("invalid-id")
      end.to raise_error(Braintree::NotFoundError, "dispute with id invalid-id not found")
    end
  end

  describe "self.add_file_evidence" do
    it "creates file evidence for the dispute" do
      result = Braintree::Dispute.add_file_evidence(dispute.id, document_upload.id)

      expect(result.success?).to eq(true)
      expect(result.evidence.category).to be_nil
      expect(result.evidence.comment).to be_nil
      expect(result.evidence.created_at.between?(Time.now - 10, Time.now)).to eq(true)
      expect(result.evidence.id).to match(/^\w{16,}$/)
      expect(result.evidence.sent_to_processor_at).to eq(nil)
      expect(result.evidence.url).to include("bt_logo.png")
    end

    it "returns a NotFoundError if the dispute doesn't exist" do
      expect do
        Braintree::Dispute.add_file_evidence("unknown_dispute_id", "b51927a6-4ed7-4a32-8404-df8ef892e1a3")
      end.to raise_error(Braintree::NotFoundError)
    end

    it "returns an error response if the dispute is not in open status" do
      Braintree::Dispute.accept(dispute.id)

      result = Braintree::Dispute.add_file_evidence(dispute.id, document_upload.id)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::CanOnlyAddEvidenceToOpenDispute)
      expect(result.errors.for(:dispute)[0].message).to eq("Evidence can only be attached to disputes that are in an Open state")
    end

    it "returns the new evidence record in subsequent dispute finds" do
      result = Braintree::Dispute.add_file_evidence(dispute.id, document_upload.id)
      refreshed_dispute = Braintree::Dispute.find(dispute.id)

      expected_evidence = refreshed_dispute.evidence.find { |e| e.id == result.evidence.id }
      expect(expected_evidence).not_to eq(nil)
      expect(expected_evidence.comment).to be_nil
      expect(expected_evidence.url).to include("bt_logo.png")
    end

    it "creates file evidence with a category when provided" do
      result = Braintree::Dispute.add_file_evidence(dispute.id, {category: "GENERAL", document_id: document_upload.id})

      expect(result.success?).to eq(true)
      expect(result.evidence.category).to eq("GENERAL")
      expect(result.evidence.url).to include("bt_logo.png")
    end

    it "reflects the updated remaining_file_evidence_storage" do
      initial_storage = dispute.remaining_file_evidence_storage
      expect(initial_storage).not_to be_nil

      Braintree::Dispute.add_file_evidence(dispute.id, document_upload.id)

      refreshed_dispute = Braintree::Dispute.find(dispute.id)
      updated_storage = refreshed_dispute.remaining_file_evidence_storage
      expect(updated_storage).to be < initial_storage
    end
  end

  describe "self.add_text_evidence" do
    it "creates text evidence for the dispute" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, "text evidence")

      expect(result.success?).to eq(true)
      expect(result.evidence.category).to eq(nil)
      expect(result.evidence.comment).to eq("text evidence")
      expect(result.evidence.created_at.between?(Time.now - 10, Time.now)).to eq(true)
      expect(result.evidence.id).to match(/^\w{16,}$/)
      expect(result.evidence.sent_to_processor_at).to eq(nil)
      expect(result.evidence.url).to eq(nil)
      expect(result.evidence.tag).to eq(nil)
      expect(result.evidence.sequence_number).to eq(nil)
    end

    it "returns a NotFoundError if the dispute doesn't exist" do
      expect do
        Braintree::Dispute.add_text_evidence("unknown_dispute_id", "text evidence")
      end.to raise_error(Braintree::NotFoundError)
    end

    it "returns an error response if the dispute is not in open status" do
      Braintree::Dispute.accept(dispute.id)

      result = Braintree::Dispute.add_text_evidence(dispute.id, "text evidence")
      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::CanOnlyAddEvidenceToOpenDispute)
      expect(result.errors.for(:dispute)[0].message).to eq("Evidence can only be attached to disputes that are in an Open state")
    end

    it "returns the new evidence record in subsequent dispute finds" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, "text evidence")
      refreshed_dispute = Braintree::Dispute.find(dispute.id)

      expected_evidence = refreshed_dispute.evidence.find { |e| e.id == result.evidence.id }
      expect(expected_evidence).not_to eq(nil)
      expect(expected_evidence.comment).to eq("text evidence")
    end

    it "creates text evidence for the dispute with optional parameters" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, {content: "123456789", category: "REFUND_ID", sequence_number: 7})

      expect(result.success?).to eq(true)
      expect(result.evidence.category).to eq("REFUND_ID")
      expect(result.evidence.comment).to eq("123456789")
      expect(result.evidence.created_at.between?(Time.now - 10, Time.now)).to eq(true)
      expect(result.evidence.id).to match(/^\w{16,}$/)
      expect(result.evidence.sent_to_processor_at).to eq(nil)
      expect(result.evidence.sequence_number).to eq(7)
    end

    it "creates text evidence for the dispute with CARRIER_NAME shipping tracking" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, {content: "UPS", category: "CARRIER_NAME", sequence_number: 0})

      expect(result.success?).to eq(true)
      expect(result.evidence.category).to eq("CARRIER_NAME")
      expect(result.evidence.comment).to eq("UPS")
      expect(result.evidence.sequence_number).to eq(0)
    end

    it "creates text evidence for the dispute with TRACKING_NUMBER shipping tracking" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, {content: "3", category: "TRACKING_NUMBER", sequence_number: 0})

      expect(result.success?).to eq(true)
      expect(result.evidence.category).to eq("TRACKING_NUMBER")
      expect(result.evidence.comment).to eq("3")
      expect(result.evidence.sequence_number).to eq(0)
    end

    it "creates text evidence for the dispute with TRACKING_URL shipping tracking" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, {content: "https://example.com/tracking-number/abc12345", category: "TRACKING_URL", sequence_number: 1})

      expect(result.success?).to eq(true)
      expect(result.evidence.category).to eq("TRACKING_URL")
      expect(result.evidence.comment).to eq("https://example.com/tracking-number/abc12345")
      expect(result.evidence.sequence_number).to eq(1)
    end
  end

  describe "self.finalize" do
    it "changes the dispute status to disputed" do
      result = Braintree::Dispute.finalize(dispute.id)

      expect(result.success?).to eq(true)

      refreshed_dispute = Braintree::Dispute.find(dispute.id)
      expect(refreshed_dispute.status).to eq(Braintree::Dispute::Status::Disputed)
    end

    it "returns an error response if the dispute is not in open status" do
      result = Braintree::Dispute.finalize("wells_dispute")

      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::CanOnlyFinalizeOpenDispute)
      expect(result.errors.for(:dispute)[0].message).to eq("Disputes can only be finalized when they are in an Open state")
    end

    it "raises a NotFound exception if the dispute cannot be found" do
      expect do
        Braintree::Dispute.finalize("invalid-id")
      end.to raise_error(Braintree::NotFoundError, "dispute with id invalid-id not found")
    end
  end

  describe "self.find" do
    it "finds the dispute with the given id" do
      dispute = Braintree::Dispute.find("open_dispute")

      expect(dispute.amount_disputed).to eq(31.0)
      expect(dispute.amount_won).to eq(0.0)
      expect(dispute.id).to eq("open_dispute")
      expect(dispute.graphql_id).not_to be_nil
      expect(dispute.status).to eq(Braintree::Dispute::Status::Open)
      expect(dispute.transaction.amount).to eq(31.0)
      expect(dispute.transaction.id).to eq("open_disputed_transaction")
    end

    it "raises an ArgumentError if dispute_id is not a string" do
      expect do
        Braintree::Dispute.find(Object.new)
      end.to raise_error(ArgumentError, "dispute_id contains invalid characters")
    end

    it "raises an ArgumentError if dispute_id is blank" do
      expect do
        Braintree::Dispute.find("")
      end.to raise_error(ArgumentError, "dispute_id contains invalid characters")
    end

    it "raises a NotFoundError exception if the dispute cannot be found" do
      expect do
        Braintree::Dispute.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, "dispute with id invalid-id not found")
    end
  end

  describe "self.remove_evidence" do
    let(:evidence) { Braintree::Dispute.add_text_evidence(dispute.id, "text evidence").evidence }

    it "removes evidence from the dispute" do
      result = Braintree::Dispute.remove_evidence(dispute.id, evidence.id)

      expect(result.success?).to eq(true)
    end

    it "returns a NotFoundError if the dispute doesn't exist" do
      expect do
        Braintree::Dispute.remove_evidence("unknown_dispute_id", evidence.id)
      end.to raise_error(Braintree::NotFoundError, "evidence with id #{evidence.id} for dispute with id unknown_dispute_id not found")
    end

    it "returns a NotFoundError if the dispute doesn't exist" do
      expect do
        Braintree::Dispute.remove_evidence(dispute.id, "unknown_evidence_id")
      end.to raise_error(Braintree::NotFoundError, "evidence with id unknown_evidence_id for dispute with id #{dispute.id} not found")
    end

    it "returns an error response if the dispute is not in open status" do
      evidence = Braintree::Dispute.add_text_evidence(dispute.id, "text evidence").evidence
      Braintree::Dispute.accept(dispute.id)

      result = Braintree::Dispute.remove_evidence(dispute.id, evidence.id)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::CanOnlyRemoveEvidenceFromOpenDispute)
      expect(result.errors.for(:dispute)[0].message).to eq("Evidence can only be removed from disputes that are in an Open state")
    end
  end

  context "categorized evidence" do
    it "fails to create file evidence for an unsupported category" do
      result = Braintree::Dispute.add_file_evidence(dispute.id, {category: "NOTREALCATEGORY", document_id: document_upload.id})

      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::CanOnlyCreateEvidenceWithValidCategory)
    end

    it "fails to create text evidence for an unsupported category" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, {category: "NOTREALCATEGORY", content: "evidence"})

      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::CanOnlyCreateEvidenceWithValidCategory)
    end

    it "fails to create text evidence for a file only category MERCHANT_WEBSITE_OR_APP_ACCESS" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, {category: "MERCHANT_WEBSITE_OR_APP_ACCESS", content: "evidence"})

      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::EvidenceCategoryDocumentOnly)
    end

    it "fails to create file evidence for a text only category DEVICE_ID" do
      result = Braintree::Dispute.add_file_evidence(dispute.id, {category: "DEVICE_ID", document_id: document_upload.id})

      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::EvidenceCategoryTextOnly)
    end

    it "fails to create evidence with an invalid date time format" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, {category: "DOWNLOAD_DATE_TIME", content: "baddate"})

      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::EvidenceContentDateInvalid)
    end

    it "successfully creates text evidence with an valid date time format" do
      result = Braintree::Dispute.add_text_evidence(dispute.id, {category: "DOWNLOAD_DATE_TIME", content: "2018-10-20T18:00:00-0500"})

      expect(result.success?).to eq(true)
    end

    it "fails to finalize a dispute with digital goods missing" do
      Braintree::Dispute.add_text_evidence(dispute.id, {category: "DEVICE_ID", content: "iphone_id"})
      result = Braintree::Dispute.finalize(dispute.id)

      expect(result.success?).to eq(false)
      error_codes = result.errors.for(:dispute).map(&:code)

      expect(error_codes).to include(Braintree::ErrorCodes::Dispute::DigitalGoodsMissingDownloadDate)
      expect(error_codes).to include(Braintree::ErrorCodes::Dispute::DigitalGoodsMissingEvidence)
    end

    it "fails to finalize a dispute with partial non-disputed transaction information provided" do
      Braintree::Dispute.add_text_evidence(dispute.id, {category: "PRIOR_NON_DISPUTED_TRANSACTION_ARN", content: "123"})
      result = Braintree::Dispute.finalize(dispute.id)

      expect(result.success?).to eq(false)
      expect(result.errors.for(:dispute)[0].code).to eq(Braintree::ErrorCodes::Dispute::NonDisputedPriorTransactionEvidenceMissingDate)
    end
  end
end
