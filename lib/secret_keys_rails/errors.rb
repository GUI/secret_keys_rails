module SecretKeysRails
  class Error < StandardError; end
  class MissingKeyError < Error; end
  class MissingSecretsError < Error; end
  class NotLoadedError < Error; end
end
