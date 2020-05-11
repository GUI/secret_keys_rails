require "rails/railtie"

module SecretKeysRails
  class Railtie < ::Rails::Railtie
    config.before_configuration do
      initializer = ::Rails.root.join("config", "initializers", "secret_keys_rails.rb")
      require initializer if File.exist?(initializer)

      SecretKeysRails.load
    end

    load_hooks = ActiveSupport.instance_variable_get(:@load_hooks)
    if load_hooks && load_hooks[:before_configuration]
      load_hooks[:before_configuration] = load_hooks[:before_configuration].rotate(-1)
    end

    rake_tasks do
      load "secret_keys_rails/railtie/secret_keys.rake"
    end

    generators do
      require "secret_keys_rails/railtie/generators/install_generator"
    end
  end
end
