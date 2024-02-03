require "rspec/collection_matchers"
require_relative "../1pux-to-pass"

def item(**attributes)
  instance_double(
    "Item",
    password: nil,
    otp: nil,
    url: nil,
    username: nil,
    fields: [],
    notes: nil,
    vault_name: "Vault",
    title: nil,
    archived?: false,
    **attributes
  )
end
