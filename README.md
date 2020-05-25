# SecretKeysRails

[![CI](https://github.com/GUI/secret_keys_rails/workflows/CI/badge.svg)](https://github.com/GUI/secret_keys_rails/actions?workflow=CI)

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

## Usage

### Creating or Editing Secrets

To open an interactive editor to create or edit the default encrypted `config/secret_keys.yml` file:

```
rake secret_keys:edit
```

All string values you enter will be encrypted after saving and closing this editing session.

If editing the file for the first time, an encryption key will be generated for you and saved to `config/secret_keys.yml.key`. This encryption key should be kept private and only shared to users that need to decrypt the encrypted values.

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

### Encryption Key

In order to decrypt the secrets, the encryption key must be set. The encryption key may either be stored in the `config/secret_keys.yml.key` file or set in the `SECRET_KEYS_ENCRYPTION_KEY` environment variable.

By default, if the encryption key is not set, then `SecretKeysRails.secrets` will return an empty hash. If you want to require the encryption key be set, then you can change the [`SecretKeysRails.require_encryption_key`](#secretkeysrailsrequire_encryption_key) setting to raise an error if the encryption key is not set.

### Environment Specific Secrets

The commands support passing an `--environment` option to create an environment specific override. That override will take precedence over the global `config/secret_keys.yml` file when running in that environment. So:

```
rake secret_keys:edit -- --environment development
```

will create `config/secret_keys/development.yml` with the corresponding encryption key in `config/secret_keys/development.yml.key` if the credentials file doesn't exist.

The encryption key can also be put in `ENV["SECRET_KEYS_ENCRYPTION_KEY"]`, which takes precedence over the file encryption key.

In addition to that, the default credentials lookup paths can be overridden through the [`SecretKeysRails.secrets_path`](#secretkeysrailssecrets_path) and [`SecretKeysRails.key_path`](#secretkeysrailskey_path) settings.

## Configuration

You may adjust RailsSecretKeys configuration by adding a `config/initializers/secret_keys_rails.rb` file with setting changes. Note that the initializer must exist at this path to be properly loaded (this ensures that RailsSecretKeys is available early on in the Rails load process, so other parts of Rails and other gems can integrate with it).

#### `SecretKeysRails.require_encryption_key`

Raise an error if the encryption key isn't set.

```ruby
SecretKeysRails.require_encryption_key = true # Defaults to `false`
```

#### `SecretKeysRails.secrets_path`

Set a custom path to the secret keys encrypted file.

```ruby
SecretKeysRails.secret_path = "config/my_keys.yml" # Defaults to `config/secret_keys/<ENV>.yml` or `config/secret_keys.yml`
```

#### `SecretKeysRails.key_path`

Set a custom path to the encryption key path.

```ruby
SecretKeysRails.key_path = "config/my_keys.yml.key" # Defaults to `config/secret_keys/<ENV>.yml.key` or `config/secret_keys.yml.key`
```

## Design

The underlying [SecretKeys](https://github.com/bdurand/secret_keys) library is more flexible in a few ways. This gem is slightly more opinionated for integration with Rails, and we attempt to more closely match the behavior of the default Rails encrypted credentials experience. The primary differences are:

- The secret keys files are always stored as YAML.
- The secret keys files exist at specific paths (`config/secret_keys.yml` or `config/secrets_keys/<ENV>.yml`).
- The encryption key can be read from a specific path (`config/secret_keys.yml.key` or `config/secrets_keys/<ENV>.yml.key`).
- All values in the file will be encrypted.
- An interactive edit command is supplied for editing the decrypted file.
- Keys are returned as a deeply frozen `ActiveSupport::HashWithIndifferentAccess`.

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
