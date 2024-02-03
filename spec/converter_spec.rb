require "spec_helper"

describe Converter do
  let(:options) { Options.new }
  let(:items) { [] }

  subject(:converter) { Converter.new(options, items) }

  it "converts a minimal item into a password store entry" do
    items << item(title: "Example", password: "secret")

    entry = subject.entries[0]

    expect(entry.name).to eq "Example"
    expect(entry.content).to eq "secret\n"
  end

  it "assigns unique entry names when multiple items have the same title but different usernames" do
    items << item(title: "Example", username: "alice")
    items << item(title: "Example", username: "bob")

    alice, bob = subject.entries

    expect(alice.name).to eq "alice@Example"
    expect(bob.name).to eq "bob@Example"
  end

  it "assigns unique entry names when multiple items have the same title and username" do
    items << item(title: "Example", username: "alice")
    items << item(title: "Example", username: "alice")
    items << item(title: "Example", username: "alice")

    one, two, three = subject.entries

    expect(one.name).to eq "alice@Example (1)"
    expect(two.name).to eq "alice@Example (2)"
    expect(three.name).to eq "alice@Example (3)"
  end

  it "assigns unique entry names when multiple items have the same title and some have the same username" do
    items << item(title: "Example", username: "alice")
    items << item(title: "Example", username: "eve")
    items << item(title: "Example", username: "eve")

    alice, eve_1, eve_2 = subject.entries

    expect(alice.name).to eq "alice@Example"
    expect(eve_1.name).to eq "eve@Example (1)"
    expect(eve_2.name).to eq "eve@Example (2)"
  end

  it "creates entries in directories when items are from multiple vaults" do
    items << item(vault_name: "Vault 1", title: "Example")
    items << item(vault_name: "Vault 2", title: "Example")

    one, two = subject.entries

    expect(one.name).to eq "Vault 1/Example"
    expect(two.name).to eq "Vault 2/Example"
  end

  context "with flat option set" do
    before do
      options.flat = true
    end

    it "creates entries in the store root" do
      items << item(vault_name: "Vault 1", title: "Example")
      items << item(vault_name: "Vault 2", title: "Example")

      one, two = subject.entries

      expect(one.name).to eq "Example (1)"
      expect(two.name).to eq "Example (2)"
    end
  end

  it "converts a complete item into a password store entry" do
    fields = [
      instance_double("Field", type: :string, title: "Field", value: "Value"),
      instance_double("Field", type: :otp, title: "One-time password", value: "")
    ]

    items << item(
      password: "secret",
      otp: "otpauth://totp/Example/username?secret=foo",
      url: "example.com",
      username: "user",
      fields: fields,
      notes: "This is a test item",
      vault_name: "Vault",
      title: "Example"
    )

    entry = subject.entries[0]

    expect(entry.name).to eq "Example"
    expect(entry.content).to eq <<~TEXT
      secret
      otpauth://totp/Example/username?secret=foo
      URL: example.com
      Username: user
      Field: Value

      This is a test item
    TEXT
  end
end
