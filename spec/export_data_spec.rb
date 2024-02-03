require "spec_helper"

describe ExportData do
  it "raises an error if the file does not exist" do
    expect {
      ExportData.read("spec/test_data/non-existent.1pux")
    }.to raise_error("1PUX file not found")
  end

  it "raises an error if the file is not a ZIP archive" do
    expect {
      ExportData.read("spec/test_data/not-zip.1pux")
    }.to raise_error("1PUX file is in an invalid format")
  end

  it "raises an error if the file does not contain an export.data file" do
    expect {
      ExportData.read("spec/test_data/missing-export-data.1pux")
    }.to raise_error("1PUX file is in an invalid format")
  end

  it "raises an error if the export.data file is not valid JSON" do
    expect {
      ExportData.read("spec/test_data/invalid-json.1pux")
    }.to raise_error("1PUX file is in an invalid format")
  end

  it "raises an error if the export.data file is not in the expected format" do
    expect {
      ExportData.read("spec/test_data/unexpected-shape.1pux")
    }.to raise_error("1PUX data is not in the expected format")
  end

  it "creates a list of accounts from a 1PUX file" do
    data = ExportData.read("spec/test_data/example.1pux")
    expect(data).to have(1).accounts

    account = data.accounts[0]
    expect(account.name).to eq "Wendy Appleseed"
    expect(account).to have(1).items

    item = account.items[0]
    expect(item.title).to eq "Dropbox"
    expect(item.password).to eq "most-secure-password-ever!"
    expect(item.fields[0].value).to eq "12345"
  end
end
