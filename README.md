# SecretKeysRails

An alternative to Rails encrypted credentials that uses the [SecretKeys](https://github.com/bdurand/secret_keys) library. The primary difference this offers versus the default Rails encrypted credentials strategy is that this uses an encrypted file format that only encrypts the values of the file (the hash keys are unencrypted). This allows for easier git diffs/merges while still keeping the secret values encrypted (but the overall structure of the file will not be encrypted). This gem provides some convenience wrappers on top of the SecretKeys library for integration with Rails applications.

As an example, the encrypted version of:

```yml
foo: bar
baz: qux
```

Might be encrypted as:

```yml
".encrypted":
  ".salt": 82acce8beeeb422f
  ".key": "$AES$:AJedc/6fDmjRHyh8Ln3K5y/WDzmbQVAsPWkDOFMLpaERVpKPS4I"
  foo: "$AES$:d3mPCOkdfcWAD6BJGjvZT00BtKqAtLVKNvrlE191qg"
  baz: "$AES$:t05Yel2BwiacEnsIXnnVoqTyXLsXU6oWZbSG7kOIDQ"
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "secret_keys_rails"
```

And then execute:

```
bundle install
```

To add an initializer and setup your gitignore file then run:

```
rails generate secret_keys_rails:install
```

## Usage

### Editing Secrets

To open an interactive editor to edit the default encrypted `config/secret_keys.yml` file:

```
rake secret_keys:edit
```

All string values you enter will be encrypted after saving and closing this editing session.

### Showing Secrets

To view all the encrypted secrets in unencrypted form for the default `config/secret_keys.yml` file:

```
rake secret_keys:show
```

### Using Secrets

Unencrypted secrets are available in your application via the `SecretKeysRails.secrets` hash. This hash is an instance of [`ActiveSupport::HashWithIndifferentAccess`](https://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html), so keys can be accessed as either symbols or strings.

```ruby
# Symbol or strings can be used for accessing keys.
SecretKeysRails.secrets[:some_api_key]
SecretKeysRails.secrets["some_api_key"]

# Use fetch to raise an error if the key isn't present.
SecretKeysRails.secrets.fetch(:some_api_key)

# Other standard Hash methods can be used for access, lig dig.
SecretKeysRails.secrets.dig(:some_api_key)
```

### Environment Specific Secrets

## Configuration

## Design

The underlying [SecretKeys](https://github.com/bdurand/secret_keys) library is more flexible in a few ways. This gem is slightly more opinionated for integration with Rails, and we attempt to more closely match the behavior of the default Rails encrypted credentials experience. The primary differences are:

- The secret keys files are always stored as YAML.
- The secret keys files exist at specific paths (`config/secret_keys.yml` or `config/secrets_keys/<ENV>.yml`).
- All values in the file will be encrypted.
- An interactive edit command is supplied for editing the decrypted file.

## Known Limitations

- Only string values will be encrypted. Numbers, booleans, and null values will not be encrypted.
- Comments in the YAML file will be stripped.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/GUI/secret_keys_rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
