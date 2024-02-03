require "cgi"
require "json"
require "open3"
require "optparse"
require "uri"
require "zip"

class Account
  attr_reader :name, :vaults

  def initialize(name)
    @name = name
    @vaults = []
  end

  def items
    vaults.flat_map(&:items)
  end
end

class Vault
  attr_reader :name, :items

  def initialize(account, name)
    @account = account
    @name = name
    @items = []
  end
end

class Item < Struct.new(:vault, :title, :url, :state, :notes, :login_fields, :sections, :password, keyword_init: true)
  def vault_name
    vault&.name
  end

  def username
    login_fields&.find(&:username?)&.value
  end

  def password
    login_fields&.find(&:password?)&.value || self[:password]
  end

  def url
    if self[:url]
      URI.parse(self[:url]).host
    end
  rescue URI::InvalidURIError
    self[:url]
  end

  def otp
    value = fields.find { |f| f.type == :otp }&.value
    if value&.start_with? "otpauth://"
      value
    elsif value
      secret = value.tr(" ", "").upcase
      "otpauth://totp/#{CGI.escape(title || "")}/#{CGI.escape(username || "")}?secret=#{secret}"
    end
  end

  def archived?
    state == "archived"
  end

  def fields
    sections&.flat_map(&:fields) || []
  end
end

class LoginField < Struct.new(:type, :designation, :name, :value, keyword_init: true)
  def username?
    designation == "username"
  end

  def password?
    designation == "password"
  end
end

Section = Struct.new(:title, :fields, keyword_init: true)

class Field
  def initialize(title, value)
    @title = title
    @value = value
  end

  def value
    case type
    when :email
      @value["email"]["email_address"]
    else
      string = @value.values[0]
      if string&.to_s&.strip&.empty?
        nil
      else
        string
      end
    end
  end

  def blank?
    value.nil? || value == ""
  end

  def title
    if @title == @title.upcase
      @title
    else
      @title.capitalize
    end
  end

  def type
    if @value.has_key? "totp"
      :otp
    elsif @value.has_key? "email"
      :email
    else
      :string
    end
  end
end

class ExportData
  attr_reader :accounts

  def self.read(filename)
    unless File.exist?(filename)
      raise StandardError.new("1PUX file not found")
    end

    json_data = Zip::File.open(filename) do |zip_file|
      zip_file.read("export.data")
    end

    new(JSON.parse(json_data))
  rescue Zip::Error, Errno::ENOENT, JSON::ParserError
    raise StandardError.new("1PUX file is in an invalid format")
  end

  def initialize(data)
    @accounts = []

    data["accounts"].each do |account_data|
      account = Account.new(account_data["attrs"]["name"])
      @accounts << account

      account_data["vaults"].each do |vault_data|
        vault = Vault.new(account, vault_data["attrs"]["name"])
        account.vaults << vault

        vault_data["items"].each do |item_data|
          item = Item.new(
            vault: vault,
            title: item_data["overview"]["title"],
            url: item_data["overview"]["url"],
            state: item_data["state"],
            notes: item_data["details"]["notesPlain"],
            password: item_data["details"]["password"],
            login_fields: build_login_fields(item_data["details"]["loginFields"]),
            sections: build_sections(item_data["details"]["sections"])
          )
          vault.items << item
        end
      end
    end
  rescue
    raise StandardError.new("1PUX data is not in the expected format")
  end

  private

  def build_login_fields(data)
    data.map { |field_data|
      LoginField.new(
        type: field_data["type"],
        designation: field_data["designation"],
        name: field_data["name"],
        value: field_data["value"]
      )
    }
  end

  def build_sections(data)
    data.map { |section_data|
      Section.new(
        title: section_data["title"],
        fields: section_data["fields"].map { |field_data|
                  Field.new(field_data["title"], field_data["value"])
                }
      )
    }
  end
end

class ItemFilter
  def initialize(options)
    @options = options
  end

  def filter(items)
    result = items
    if @options.vault
      result = result.filter { |item| item.vault_name == @options.vault }
    end
    result = result.reject(&:archived?) unless @options.archived
    if @options.item_title_like
      result = result.filter { |item| item.title.include? @options.item_title_like }
    end
    result
  end
end

PasswordStoreEntry = Struct.new(:name, :content)

class Converter
  attr_reader :items

  def initialize(options, items)
    @options = options
    @items = items
    @entry_names = items.flat_map { |item| entry_name_candidates(item) }
  end

  def entries
    items.map { |item|
      PasswordStoreEntry.new(entry_name(item), entry_content(item))
    }
  end

  private

  def entry_name(item)
    name_candidates = entry_name_candidates(item)

    # Try to find a unique name among the possible names for this entry
    unique_name = name_candidates.find { |name| @entry_names.count(name) == 1 }

    # If a unique name exists, use it
    return unique_name if unique_name

    # Otherwise, create a unique name by appending a sequence number
    conflicting_items = items.filter { |other|
      entry_name_candidates(other) == name_candidates
    }
    number = conflicting_items.index(item) + 1

    "#{name_candidates.last} (#{number})"
  end

  def entry_name_candidates(item)
    base_names = [
      item.title,
      item.username && "#{item.username}@#{item.title}"
    ].compact

    if @options.flat || single_vault?
      base_names
    else
      base_names.map { |name| File.join(item.vault_name, name) }
    end
  end

  def single_vault?
    items.map(&:vault_name).uniq.one?
  end

  def entry_content(item)
    included_fields = item.fields.reject { |f| f.type == :otp }

    [
      item.password,
      item.otp,
      item.url && "URL: #{item.url}",
      item.username && "Username: #{item.username}",
      *included_fields.map { |f| "#{f.title}: #{f.value}" },
      item.notes && "",
      item.notes,
      ""
    ].compact.join($/)
  end
end

class PasswordStore
  attr_accessor :executable

  def initialize(executable = "pass")
    @executable = executable
  end

  def insert(entry)
    output, status = Open3.capture2e(executable, "insert", "--multiline", entry.name, stdin_data: entry.content)
    unless status.success?
      raise PasswordStore::Error.new("pass exited with status #{status.exitstatus}", output)
    end
  rescue Errno::ENOENT
    raise PasswordStore::Error.new("pass executable not found")
  end

  class Error < StandardError
    attr_reader :output

    def initialize(message, output = nil)
      super(message)
      @output = output
    end
  end
end

Options = Struct.new(:vault, :archived, :flat, :item_title_like, :executable, :help)

class Parser
  def initialize
    @options = Options.new
    @parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename(__FILE__)} [options] [path to 1PUX file]"

      opts.on("-a", "--archived", "Include archived items") do
        @options.archived = true
      end

      opts.on("-t", "--title=TITLE", "Only include items with matching title") do |title|
        @options.item_title_like = title
      end

      opts.on("-v", "--vault=VAULT", "Only include items from named vault") do |vault|
        @options.vault = vault
      end

      opts.on("-f", "--flat", "Do not create a directory per vault") do
        @options.flat = true
      end

      opts.on("--pass=EXECUTABLE", "Path to pass executable") do |executable|
        @options.executable = executable
      end

      opts.on("-h", "--help", "Display this help") do
        @options.help = true
      end
    end
  end

  def parse!(args)
    @parser.parse!(args)
    @options
  end

  def help
    @parser.to_s
  end
end

class Main
  def initialize(password_store: PasswordStore.new)
    @password_store = password_store
  end

  def call(*args)
    parser = Parser.new
    options = parser.parse!(args)

    if options.help || args.empty?
      puts parser.help
      return options.help ? 0 : 1
    end

    export_data = ExportData.read(args.first)
    items = ItemFilter.new(options).filter(export_data.accounts.flat_map(&:items))
    entries = Converter.new(options, items).entries

    if options.executable
      @password_store.executable = options.executable
    end

    begin
      entries.each do |entry|
        @password_store.insert(entry)
        puts entry.name
      end
      0
    rescue PasswordStore::Error => e
      puts e.message
      puts e.output if e.output
      1
    end
  rescue => e
    puts e.message
    1
  end
end

if __FILE__ == $0
  exit Main.new.call(*ARGV)
end
