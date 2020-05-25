require_relative "test_helper"
require "open3"

class SecretKeysRailsTest < Minitest::Test
  def setup
    clean
    super
  end

  def teardown
    clean
    super
  end

  def test_version_number
    require_lib do
      refute_nil ::SecretKeysRails::VERSION
    end
  end

  def test_no_secrets_loaded_without_railtie
    require_lib do
      assert_raises(SecretKeysRails::NotLoadedError) do
        SecretKeysRails.secrets
      end
    end
  end

  def test_loads_empty_secrets_by_default
    load_app do
      assert_equal({}, SecretKeysRails.secrets)
    end
  end

  def test_empty_secrets_is_frozen
    load_app do
      assert_equal(true, SecretKeysRails.secrets.frozen?)
      assert_equal({}, SecretKeysRails.secrets)
    end
  end

  def test_loads_existing_secrets_with_key_file
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app do
      assert_equal({
        "foo" => "bar",
        "baz" => {
          "test" => ["a", "b"],
        },
      }, SecretKeysRails.secrets)
    end
  end

  def test_loads_existing_secrets_with_environment_variable_file
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    with_env("SECRET_KEYS_ENCRYPTION_KEY" => "dummy_key") do
      load_app do
        assert_equal({
          "foo" => "bar",
          "baz" => {
            "test" => ["a", "b"],
          },
        }, SecretKeysRails.secrets)
      end
    end
  end

  def test_secrets_with_indiffferent_access
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app do
      assert_equal({
        "foo" => "bar",
        "baz" => {
          "test" => ["a", "b"],
        },
      }, SecretKeysRails.secrets)
      assert_instance_of(ActiveSupport::HashWithIndifferentAccess, SecretKeysRails.secrets)
      assert_equal("bar", SecretKeysRails.secrets.fetch("foo"))
      assert_equal("bar", SecretKeysRails.secrets.fetch(:foo))

      assert_instance_of(ActiveSupport::HashWithIndifferentAccess, SecretKeysRails.secrets.fetch("baz"))
      assert_equal(["a", "b"], SecretKeysRails.secrets.fetch("baz").fetch("test"))
      assert_equal(["a", "b"], SecretKeysRails.secrets.fetch(:baz).fetch(:test))
    end
  end

  def test_secrets_are_deeply_frozen
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app do
      assert_equal(true, SecretKeysRails.secrets.frozen?)
      assert_equal(true, SecretKeysRails.secrets.fetch("foo").frozen?)
      assert_equal(true, SecretKeysRails.secrets.fetch(:foo).frozen?)
      assert_equal(true, SecretKeysRails.secrets.fetch("baz").frozen?)
      assert_equal(true, SecretKeysRails.secrets.fetch(:baz).frozen?)
      assert_equal(true, SecretKeysRails.secrets.fetch("baz").fetch("test").frozen?)
      assert_equal(true, SecretKeysRails.secrets.fetch("baz").fetch("test")[0].frozen?)
    end
  end

  def test_initializer_require_encryption_key
    File.open("test/internal/config/initializers/secret_keys_rails.rb", "w") do |f|
      f.puts("SecretKeysRails.require_encryption_key = true")
    end
    require "secret_keys_rails/errors"
    assert_raises(SecretKeysRails::MissingKeyError) do
      load_app do
        SecretKeysRails.secrets
      end
    end
  end

  def test_initializer_secrets_path
    File.open("test/internal/config/initializers/secret_keys_rails.rb", "w") do |f|
      f.puts("SecretKeysRails.secrets_path = 'config/custom_secret_keys.yml'")
    end
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/custom_secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app do
      assert_equal("bar", SecretKeysRails.secrets.dig(:foo))
    end
  end

  def test_initializer_key_path
    File.open("test/internal/config/initializers/secret_keys_rails.rb", "w") do |f|
      f.puts("SecretKeysRails.key_path = 'config/custom_secret_keys.yml.key'")
    end
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/custom_secret_keys.yml.key")
    load_app do
      assert_equal("bar", SecretKeysRails.secrets.dig(:foo))
    end
  end

  def test_loads_early_enough_for_database_yml
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app do
      assert_equal("bar", Rails.configuration.database_configuration.fetch("test").fetch("password"))
    end
  end

  def test_no_config_gem_by_default
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app do
      refute(defined?(Settings))
    end
  end

  def test_loads_before_config_gem
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app(libs: ["config"]) do
      assert(defined?(Settings))
      assert_equal("bar", Settings.foo)
    end
  end

  def test_show_cli
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app(libs: ["config"]) do
      stdout, stderr, status = Open3.capture3("bundle exec secret_keys_rails show")
      if RUBY_VERSION.to_f < 2.7 || ::Rails.version.to_f >= 6.0
        assert_equal("", stderr)
      end
      assert_equal("foo: bar\nbaz:\n  test:\n  - a\n  - b\n", stdout)
      assert_equal(true, status.success?)
    end
  end

  def test_show_rake
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app(libs: ["config"]) do
      stdout, stderr, status = Open3.capture3("bundle exec rake secret_keys:show")
      if RUBY_VERSION.to_f < 2.7 || ::Rails.version.to_f >= 6.0
        assert_equal("", stderr)
      end
      assert_equal("foo: bar\nbaz:\n  test:\n  - a\n  - b\n", stdout)
      assert_equal(true, status.success?)
    end
  end

  def test_show_rails
    FileUtils.cp("test/fixtures/secret_keys.yml", "test/internal/config/secret_keys.yml")
    FileUtils.cp("test/fixtures/secret_keys.yml.key", "test/internal/config/secret_keys.yml.key")
    load_app(libs: ["config"]) do
      skip if ::Rails.version.to_f < 5.0

      stdout, stderr, status = Open3.capture3("bundle exec ./bin/rails secret_keys:show")
      if RUBY_VERSION.to_f < 2.7 || ::Rails.version.to_f >= 6.0
        assert_equal("", stderr)
      end
      assert_equal("foo: bar\nbaz:\n  test:\n  - a\n  - b\n", stdout)
      assert_equal(true, status.success?)
    end
  end

  private

  def require_lib
    require "secret_keys_rails"
    yield
  end

  def load_app(libs: [])
    Dir.chdir("test/internal") do
      # Load Rails and require optional libraries before requiring Combustion.
      # Requiring Combustion first triggers the before_configuration hooks to
      # fire earlier than during a normal rails load process (since the
      # inherited "Application" class Combustion defines gets read in before
      # other libraries are required). So we do this dance to better test the
      # specific behavior and ordering of our "before_configuration" hook.
      require "rails/all"
      libs << "secret_keys_rails"
      libs.sort.each do |lib|
        require lib
      end

      require "combustion"
      Combustion.path = "."
      Combustion.initialize!

      yield
    end
  end

  def with_env(new_values)
    old_values = new_values.keys.map { |key| [key, ENV[key]] }.to_h
    new_values.each do |key, value|
      ENV[key] = value
    end
    yield
  ensure
    old_values.each do |key, value|
      ENV[key] = value
    end
  end

  def clean
    stdout, status = Open3.capture2("git clean -f -d test/internal")
    assert_equal(true, status.success?)
  end
end
