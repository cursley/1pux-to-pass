require "spec_helper"

describe Field do
  shared_examples "a blank field" do
    it "is blank" do
      expect(field).to be_blank
    end

    it "has nil value" do
      expect(field.value).to be_nil
    end
  end

  shared_examples "a non-blank field" do
    it "is not blank" do
      expect(field).to_not be_blank
    end

    it "has a value" do
      expect(field.value).to eq "value"
    end
  end

  context "nil value" do
    subject(:field) { Field.new("title", {}) }

    it_behaves_like "a blank field"
  end

  context "empty string value" do
    subject(:field) { Field.new("title", {"string" => ""}) }

    it_behaves_like "a blank field"
  end

  context "string value" do
    subject(:field) { Field.new("title", {string: "value"}) }

    it_behaves_like "a non-blank field"

    it "is of string type" do
      expect(field.type).to eq :string
    end
  end

  context "email value" do
    subject(:field) { Field.new("title", {"email" => {"email_address" => "value"}}) }

    it_behaves_like "a non-blank field"

    it "is of email type" do
      expect(field.type).to eq :email
    end
  end

  context "otp value" do
    subject(:field) { Field.new("title", {"totp" => "value"}) }

    it_behaves_like "a non-blank field"

    it "is of otp type" do
      expect(field.type).to eq :otp
    end
  end

  it "capitalises field titles" do
    field = Field.new("title", {})

    expect(field.title).to eq "Title"
  end

  it "preserves upper-case field titles" do
    field = Field.new("PIN", {})

    expect(field.title).to eq "PIN"
  end
end
