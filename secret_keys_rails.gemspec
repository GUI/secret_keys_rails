require_relative 'lib/secret_keys_rails/version'

Gem::Specification.new do |spec|
  spec.name          = "secret_keys_rails"
  spec.version       = SecretKeysRails::VERSION
  spec.authors       = ["Nick Muerdter"]
  spec.email         = ["12112+GUI@users.noreply.github.com"]

  spec.summary       = %q{Git-friendly encrypted secrets for Rails.}
  spec.homepage      = "https://github.com/GUI/secret_keys_rails"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/GUI/secret_keys_rails"
  spec.metadata["source_code_uri"] = "https://github.com/GUI/secret_keys_rails/tree/v#{SecretKeysRails::VERSION}"
  spec.metadata["changelog_uri"] = "https://github.com/GUI/secret_keys_rails/blob/v#{SecretKeysRails::VERSION}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "secret_keys"
  spec.add_dependency "rails", ">= 4"
  spec.add_dependency "ice_nine"
  spec.add_dependency "thor"
end
