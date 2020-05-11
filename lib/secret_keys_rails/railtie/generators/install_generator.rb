module SecretKeysRails
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "Generate a custom SecretKeysRails initializer file."

      source_root File.expand_path("../templates", __FILE__)

      def copy_initializer
        template "secret_keys_rails.rb", "config/initializers/secret_keys_rails.rb"
      end

      def modify_gitignore
        create_file ".gitignore" unless File.exist?(".gitignore")
        append_to_file '.gitignore' do
          "\n/config/secret_keys.yml.key\n/config/secret_keys/*.key\n"
        end
      end
    end
  end
end
