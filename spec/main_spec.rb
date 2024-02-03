require "spec_helper"

describe Main do
  let(:password_store) { instance_double("PasswordStore") }
  subject(:main) { Main.new(password_store: password_store) }

  it "returns 0 with called with --help" do
    expect(main.call("--help")).to eq 0
  end

  it "returns 1 when called with no arguments" do
    expect(main.call).to eq 1
  end

  it "returns 1 on error" do
    expect(main.call("spec/test_data/invalid-json.1pux")).to eq 1
  end

  it "sets a custom pass executable with --pass option" do
    expect(password_store).to receive(:executable=).with("/path/to/pass")
    allow(password_store).to receive(:insert)

    expect(main.call("--pass", "/path/to/pass", "spec/test_data/example.1pux"))
  end

  it "inserts into the password store and returns 0" do
    expect(password_store).to receive(:insert) do |entry|
      expect(entry.name).to eq "Dropbox"
      expect(entry.content).to eq <<~TEXT
        most-secure-password-ever!
        URL: www.dropbox.com
        PIN: 12345

        This is a note. *bold*! _italic_!
      TEXT
    end

    expect(main.call("spec/test_data/example.1pux")).to eq 0
  end
end
