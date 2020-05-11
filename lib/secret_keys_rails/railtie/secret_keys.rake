namespace :secret_keys do
  task :show do
    SecretKeysRails.require_encryption_key = true
    secrets_path = SecretKeysRails.secrets_path
    key = SecretKeysRails.key
    secrets = SecretKeys.new(secrets_path, key)
    STDOUT.write(YAML.dump(secrets.to_h))
  end

  task :edit do
    SecretKeysRails.require_encryption_key = true
    secrets_path = SecretKeysRails.secrets_path
    key = SecretKeysRails.key
    secrets = SecretKeys.new(secrets_path, key)

    tmp_file = "#{Process.pid}.#{secrets_path.basename.to_s}"
    tmp_path = Pathname.new(File.join(Dir.tmpdir, tmp_file))
    tmp_path.binwrite(YAML.dump(secrets.to_h))

    system("#{ENV["EDITOR"]} #{tmp_path}")

    updated_contents = tmp_path.binread
    secrets.keys.each do |key|
      secrets.encrypt!(key)
    end
    secrets.replace( YAML.safe_load(updated_contents))
    secrets.keys.each do |key|
      secrets.encrypt!(key)
    end
    secrets.save(secrets_path.to_s)
  end
end
