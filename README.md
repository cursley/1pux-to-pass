# 1pux-to-pass 🔑

[![Tests](https://github.com/cursley/1pux-to-pass/actions/workflows/main.yml/badge.svg)](https://github.com/cursley/1pux-to-pass/actions/workflows/main.yml)

`1pux-to-pass` is a tool to import data from 1Password's [1PUX](https://support.1password.com/1pux-format/) file format into [pass](https://www.passwordstore.org/).

- Imports most data from 1Password vaults, including custom fields.
- Converts one-time password secrets into [Key URI format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format) for use with the [pass-otp](https://github.com/tadfisher/pass-otp) extension.
- Creates unique file names for items with the same title.

## Usage

### Pre-requisites

- Ruby 2.6.0 or later. macOS Sonoma includes Ruby 2.6.0 by default.
- An initialised password store (`pass init`). The store does not need to be empty.
- A 1PUX file (see [instructions](https://support.1password.com/export/)).

Download [1pux-to-pass.rb](https://github.com/cursley/1pux-to-pass/blob/main/1pux-to-pass.rb). As 1PUX files contain sensitive data, inspecting the script before running it is a good idea.

Install the [rubyzip](https://github.com/rubyzip/rubyzip) dependency:

```
$ sudo gem install rubyzip -v 2.3.2
```

Include `sudo` unless you have a custom Ruby installation.

### Running

Run `1pux-to-pass.rb`:

```
$ cd ~/Downloads
$ ruby 1pux-to-pass.rb *.1pux
```

The script outputs the name of each imported item.

Once the import is complete, use `pass ls` and `pass show` to check the imported data.

## Options

```
Usage: 1pux-to-pass.rb [options] [path to 1PUX file]
    -a, --archived                   Include archived items
    -t, --title=TITLE                Only include items with matching title
    -v, --vault=VAULT                Only include items from named vault
    -f, --flat                       Do not create a directory per vault
        --pass=EXECUTABLE            Path to pass executable
    -h, --help                       Display this help
```

### Flat

When importing a file that contains multiple vaults, the default behaviour is to create a directory for each vault. For instance, importing data containing a Personal and a Work vault produces this:

```
$ pass ls
├── Personal
│   ├── Personal Account
├── Work
│   ├── Work Account
```

Turn off this behaviour with the `--flat` option:

```
$ pass ls
├── Personal Account
├── Work Account
```

### Filters

- To import items from a single vault, use `--vault=[vault name]`.
- To import only items whose titles contain a string, use `--title=[substring]`.
- Archived items are excluded from the import by default. To include them, use `--archived`.

### Pass executable

If `pass` is not in your `PATH`, use `--pass=/path/to/pass` to specify its location.

## Limitations

- File attachments are not imported.
