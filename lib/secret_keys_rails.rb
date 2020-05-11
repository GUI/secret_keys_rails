require "active_support/hash_with_indifferent_access"
require "secret_keys_rails/version"
require "secret_keys_rails/railtie"

module SecretKeysRails
  class MissingKeyError < RuntimeError; end

  @const_name = "SECRET_KEYS"
  @require_encryption_key = false
  class << self
    attr_accessor :const_name
    attr_accessor :require_encryption_key
  end

  def self.secrets_path(env = nil)
    if env
      ::Rails.root.join("config", "secret_keys", "#{env}.yml")
    else
      ::Rails.root.join("config", "secret_keys.yml")
    end
  end

  def self.key_path(env = nil)
    if env
      ::Rails.root.join("config", "secret_keys", "#{env}.yml.key")
    else
      ::Rails.root.join("config", "secret_keys.yml.key")
    end
  end

  def self.key(env = nil)
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
      raise MissingKeyError.new("Missing encryption key to decrypt file with. Ask your team for your master key and write it to #{key_path} or put it in the ENV['SECRET_KEYS_ENCRYPTION_KEY'].")
    end

    key
  end

  def self.load
    env_secrets_path = self.secrets_path(::Rails.env)
    default_secrets_path = self.secrets_path

    secrets_path = nil
    key = nil
    if File.exist?(env_secrets_path)
      secrets_path = env_secrets_path
      key = self.key(::Rails.env)
    elsif File.exist?(default_secrets_path)
      secrets_path = default_secrets_path
      key = self.key
    end

    if secrets_path && key
      secrets = ::ActiveSupport::HashWithIndifferentAccess.new(SecretKeys.new(secrets_path, key).to_h)
    else
      secrets = {}
    end

    Object.send(:remove_const, self.const_name) if Object.const_defined?(self.const_name)
    Object.const_set(self.const_name, secrets)

    if secrets.key?(:secret_key_base)
      if ::Rails.application.respond_to?(:credentials)
        Rails.application.credentials.secret_key_base = secrets.fetch(:secret_key_base)
      end
      if ::Rails.application.respond_to?(:secrets)
        Rails.application.secrets.secret_key_base = secrets.fetch(:secret_key_base)
      end
      if ::Rails.application.config.respond_to?(:secret_key_base=)
        Rails.application.config.secret_key_base = secrets.fetch(:secret_key_base)
      end
    end
  end
end
