require "active_support/core_ext/hash/indifferent_access"
require "ice_nine"
require "secret_keys"
require "secret_keys_rails/errors"
require "secret_keys_rails/version"

module SecretKeysRails
  @secrets = nil
  @require_encryption_key = false
  @secrets_path = nil
  @key_path = nil
  class << self
    attr_accessor :require_encryption_key
    attr_writer :secrets_path
    attr_writer :key_path

    def secrets_path(env = nil)
      if @secrets_path
        Pathname.new(@secrets_path)
      elsif env
        Pathname.new("config/secret_keys/#{env}.yml")
      else
        Pathname.new("config/secret_keys.yml")
      end
    end

    def key_path(env = nil)
      if @key_path
        Pathname.new(@key_path)
      elsif env
        Pathname.new("config/secret_keys/#{env}.yml.key")
      else
        Pathname.new("config/secret_keys.yml.key")
      end
    end

    def key(env = nil)
      key = nil

      if ENV["SECRET_KEYS_ENCRYPTION_KEY"]
        key = ENV["SECRET_KEYS_ENCRYPTION_KEY"]
      else
        path = self.key_path(env)
        if File.exist?(path)
          key = File.read(path).strip
        end
      end

      if !key && self.require_encryption_key
        raise MissingKeyError.new("Missing encryption key to decrypt file with. Ask your team for your master key and write it to #{self.key_path(env)} or put it in the ENV['SECRET_KEYS_ENCRYPTION_KEY'].")
      end

      key
    end

    def secrets
      unless @secrets
        raise NotLoadedError.new("Secrets have not been loaded. Rails should automatically load the secrets on startup.")
      end

      @secrets
    end

    def load
      # Determine whether we should try to load the environment-specific secret
      # keys file (eg, config/secret_keys/ENV.yml), or whether we should use the
      # default file (config/secret_keys.yml).
      secrets_path = nil
      key = nil
      if Pathname.new("config/secret_keys/#{::Rails.env}.yml").exist?
        secrets_path = self.secrets_path(::Rails.env)
        key = self.key(::Rails.env)
      else
        secrets_path = self.secrets_path
        key = self.key
      end

      # Decrypt the file with the SecretKeys library.
      if secrets_path.exist? && key
        secrets = SecretKeys.new(secrets_path, key).to_h
      else
        secrets = {}
      end

      # Use a HashWithIndifferentAccess for easier key access, and also deep
      # freeze the object to prevent unintended modifications of the secrets at
      # runtime.
      @secrets = IceNine.deep_freeze(secrets.with_indifferent_access)

      # If there is a `secret_key_base` secret present, then use that for the
      # default Rails secret_key_base definition (depending on Rails version,
      # this can be read out of a few different places).
      if @secrets.key?(:secret_key_base)
        if ::Rails.application.respond_to?(:credentials)
          Rails.application.credentials.secret_key_base = @secrets.fetch(:secret_key_base)
        end
        if ::Rails.application.respond_to?(:secrets)
          Rails.application.secrets.secret_key_base = @secrets.fetch(:secret_key_base)
        end
        if ::Rails.application.config.respond_to?(:secret_key_base=)
          Rails.application.config.secret_key_base = @secrets.fetch(:secret_key_base)
        end
      end
    end

    def read(env = nil)
      secrets_path = self.secrets_path(env)
      unless secrets_path.exist?
        raise MissingSecretsError.new("File '#{secrets_path}' does not exist. Use `rake secret_keys:edit` to create it.")
      end

      SecretKeys.new(secrets_path, self.key(env))
    end
  end
end

if defined?(::Rails)
  require "secret_keys_rails/railtie"
end
