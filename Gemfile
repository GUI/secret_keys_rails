source "https://rubygems.org"

# Specify your gem's dependencies in secret_keys_rails.gemspec
gemspec

gem "rake", "~> 12.0"

# Tests
gem "minitest", "~> 5.0"
gem "minitest-reporters", "~> 1.4.2"

# Run each test in isolation, so we can better test how changes would affect
# the app loading.
gem "minitest-fork_executor", "~> 1.0.1"

# Run against multiple Rails versions.
gem "appraisal", "~> 2.2.0"

# Perform tests inside a Rails app, so we can simulate how this plugin
# interacts with application loading.
gem "combustion", "~> 1.3.0"

# Test how this gem interacts with other gems inside the Combustion Rails test
# app.
group :test_app do
  gem "config", "~> 2.2.1"
end
