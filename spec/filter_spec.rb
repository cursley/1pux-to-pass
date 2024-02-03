require "spec_helper"

describe ItemFilter do
  let(:options) { Options.new }
  subject(:filter) { ItemFilter.new(options) }

  let(:vault_1_item) { item(vault_name: "Vault 1") }
  let(:vault_2_item) { item(vault_name: "Vault 2") }
  let(:archived_item) { item(archived?: true) }

  context "with default options" do
    it "omits archived items" do
      expect(subject.filter([archived_item])).to be_empty
    end

    it "includes items from all vaults" do
      expect(subject.filter([vault_1_item, vault_2_item])).to eq [vault_1_item, vault_2_item]
    end
  end

  context "with archived option set" do
    before do
      options.archived = true
    end

    it "includes archived items" do
      expect(subject.filter([archived_item])).to eq [archived_item]
    end
  end

  context "with vault option set" do
    before do
      options.vault = "Vault 1"
    end

    it "only includes items from the specified vault" do
      expect(subject.filter([vault_1_item, vault_2_item])).to eq [vault_1_item]
    end
  end

  context "with item title option set" do
    before do
      options.item_title_like = "Foo"
    end

    it "only includes items with matching titles" do
      foo_item = item(title: "Foo")
      bar_item = item(title: "Bar")

      expect(subject.filter([foo_item, bar_item])).to eq [foo_item]
    end
  end
end
