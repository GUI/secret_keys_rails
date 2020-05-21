require "secret_keys_rails"
require "thor"
require "securerandom"
require "yaml"

module SecretKeysRails
  module Commands
    class SecretKeysCommand < Thor
      include Thor::Actions

      class_option :environment, :aliases => "-e", :type => :string, :desc => "Specifies the environment to run the command under (test/development/production)."

      def self.exit_on_failure?
        true
      end

      def self.rake_args
        args = ARGV.dup
        if args[0]
          args[0] = args[0].sub(/\Asecret_keys:/, "")
        end
        if args[1] == "--"
          args.delete_at(1)
        end
        args
      end

      desc "show", "Decrypt and show the unencrypted secret keys"
      def show
        SecretKeysRails.require_encryption_key = true
        secrets = SecretKeysRails.read(options["environment"])
        STDOUT.write(yaml_dump(secrets.to_h))
      rescue SecretKeysRails::Error => e
        STDERR.puts e.message
        exit 1
      end

      desc "edit", "Opens a temporary file in `$EDITOR` with the decrypted contents to edit the encrypted credentials."
      def edit
        key = ensure_key(options["environment"])
        ensure_secrets(key, options["environment"])
        edit_secrets(options["environment"])

      rescue SecretKeysRails::Error => e
        STDERR.puts e.message
        exit 1
      end

      private

      def ensure_key(env = nil)
        key = SecretKeysRails.key(env)
        unless key
          key_path = SecretKeysRails.key_path(env)
          unless key_path.exist?
            key = SecureRandom.hex(32)

            puts "Adding #{key_path} to store the encryption key: #{key}"
            puts ""
            puts "Save this in a password manager your team can access."
            puts ""
            puts "If you lose the key, no one, including you, can access anything encrypted with it."

            puts ""
            create_file key_path, key
            chmod key_path, 0600
            puts ""

            ignore = "\n/#{key_path}\n"
            if File.exist?(".gitignore")
              unless File.read(".gitignore").include?(ignore)
                puts "Ignoring #{key_path} so it won't end up in Git history:"
                puts ""
                append_to_file ".gitignore", ignore
                puts ""
              end
            else
              puts "IMPORTANT: Don't commit #{key_path}. Add this to your ignore file:"
              puts set_color(ignore, :green, :bold)
            end
          end
        end

        key
      end

      def ensure_secrets(key, env = nil)
        secrets_path = SecretKeysRails.secrets_path(env)
        unless secrets_path.exist?
          secrets = SecretKeys.new({
            "secret_key_base" => SecureRandom.hex(64),
          }, key)
          secrets.save(secrets_path.to_s)
        end
      end

      def edit_secrets(env = nil)
        secrets = SecretKeysRails.read(env)

        secrets_path = SecretKeysRails.secrets_path(env)
        tmp_file = "#{Process.pid}.#{secrets_path.basename.to_s}"
        tmp_path = Pathname.new(File.join(Dir.tmpdir, tmp_file))
        tmp_path.binwrite(yaml_dump(secrets.to_h))

        system("#{ENV["EDITOR"]} #{tmp_path}")

        updated_contents = tmp_path.binread
        secrets.keys.each do |key|
          secrets.encrypt!(key)
        end
        secrets.replace(YAML.safe_load(updated_contents))
        secrets.keys.each do |key|
          secrets.encrypt!(key)
        end
        secrets.save(secrets_path.to_s)
      end

      def yaml_dump(obj)
        YAML.dump(obj).sub(/\A---\n/, "")
      end
    end
  end
end
