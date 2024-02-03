require "spec_helper"

describe PasswordStore do
  subject(:store) { PasswordStore.new }
  let(:entry) { instance_double("PasswordStoreEntry", name: "Name", content: "Content") }

  before do
    allow(Open3).to receive(:capture2e).and_return ["", double(success?: true)]
  end

  it "invokes pass insert with the entry name and content" do
    store.insert(entry)

    expect(Open3).to have_received(:capture2e) do |*args|
      expect(args).to start_with "pass", "insert"
      expect(args).to include "Name"
      expect(args).to include stdin_data: "Content"
    end
  end

  it "raises an error if the pass executable is not found" do
    allow(Open3).to receive(:capture2e).and_raise(Errno::ENOENT)

    expect {
      store.insert(entry)
    }.to raise_error(PasswordStore::Error, "pass executable not found")
  end

  it "raises an error on unsuccessful exit" do
    allow(Open3).to receive(:capture2e).and_return(["Error message", double(success?: false, exitstatus: 1)])

    expect {
      store.insert(entry)
    }.to raise_error(PasswordStore::Error, "pass exited with status 1")
  end

  context "with custom executable" do
    subject(:store) { PasswordStore.new("/path/to/pass") }

    it "invokes pass using the custom executable path" do
      store.insert(entry)

      expect(Open3).to have_received(:capture2e).with("/path/to/pass", any_args)
    end
  end
end
