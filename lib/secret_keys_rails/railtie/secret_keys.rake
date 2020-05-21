namespace :secret_keys do
  desc "Show the secret keys"
  task :show do
    require "secret_keys_rails/commands/secret_keys_command"
    SecretKeysRails::Commands::SecretKeysCommand.start(SecretKeysRails::Commands::SecretKeysCommand.rake_args)
  end

  desc "Edit the secret keys"
  task :edit do
    require "secret_keys_rails/commands/secret_keys_command"
    SecretKeysRails::Commands::SecretKeysCommand.start(SecretKeysRails::Commands::SecretKeysCommand.rake_args)
  end
end
