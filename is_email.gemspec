# frozen_string_literal: true

require_relative "lib/is_email/version"

Gem::Specification.new do |spec|
  spec.name = "is_email"
  spec.version = IsEmail::VERSION
  spec.authors = ["Michael Herold"]
  spec.email = ["opensource@michaeljherold.com"]

  spec.summary = "is_email is a no-nonsense approach for checking whether that user-supplied email address could be real. Sick of not being able to use email address tagging to sort through your Bacn? We can fix that."
  spec.description = spec.summary
  spec.homepage = "https://github.com/michaelherold/is_email"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files = %w[CHANGELOG.md CONTRIBUTING.md LICENSE.md README.md]
  spec.files += %w[is_email.gemspec]
  spec.files += Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/michaelherold/is_email/issues",
    "changelog_uri" => "https://github.com/michaelherold/is_email/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/is_email/#{IsEmail::VERSION}",
    "homepage_uri" => "https://github.com/michaelherold/is_email",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/michaelherold/is_email"
  }
end
