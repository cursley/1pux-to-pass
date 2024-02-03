require "spec_helper"

describe Item do
  subject(:item) { Item.new }
  let(:username_field) { instance_double("LoginField", username?: true, value: "username") }
  let(:password_field) { instance_double("LoginField", password?: true, value: "password") }

  it "gets a nil username" do
    expect(item.username).to be_nil
  end

  it "gets a nil password" do
    expect(item.password).to be_nil
  end

  it "gets a username from a login field" do
    item.login_fields = [username_field]

    expect(item.username).to eq "username"
  end

  it "gets a password from a login field" do
    item.login_fields = [password_field]

    expect(item.password).to eq "password"
  end

  it "gets a password from item" do
    item.password = "secret"

    expect(item.password).to eq "secret"
  end

  it "gets a nil URL" do
    expect(item.url).to be_nil
  end

  it "normalises a URL" do
    item.url = "https://www.example.com/login"

    expect(item.url).to eq "www.example.com"
  end

  it "returns the original URL if not valid" do
    item.url = "invalid URL"

    expect(item.url).to eq "invalid URL"
  end

  it "gets a nil OTP" do
    expect(item.otp).to be_nil
  end

  it "gets the OTP URL" do
    item.sections = [
      instance_double("Section", fields: [
        instance_double("Field", type: :otp, value: "otpauth://totp/Example")
      ])
    ]

    expect(item.otp).to eq "otpauth://totp/Example"
  end

  it "constructs an OTP URL from a secret" do
    item.title = "Example"
    item.login_fields = [username_field]
    item.sections = [
      instance_double("Section", fields: [
        instance_double("Field", type: :otp, value: "secret")
      ])
    ]

    expect(item.otp).to eq "otpauth://totp/Example/username?secret=SECRET"
  end

  context "active state" do
    before do
      item.state = "active"
    end

    it "is not archived" do
      expect(item).to_not be_archived
    end
  end

  context "archived state" do
    before do
      item.state = "archived"
    end

    it "is archived" do
      expect(item).to be_archived
    end
  end
end
