# frozen_string_literal: true

require_relative "lib/xmp_toolkit_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "xmp_toolkit_ruby"
  spec.version = XmpToolkitRuby::VERSION
  spec.authors = ["Dieter S."]
  spec.email = ["101627195+dieter-medium@users.noreply.github.com"]

  spec.summary = "A Ruby interface to Adobe's XMP Toolkit for reading and writing XMP metadata."
  spec.description = "This gem provides a comprehensive Ruby wrapper around Adobe's native XMP Toolkit (C++ library), enabling applications to easily read, write, and manipulate XMP metadata in various file formats. It handles toolkit initialization, plugin path management for different platforms, and XMP data processing."
  spec.homepage = "https://github.com/dieter-medium/xmp_toolkit_ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.4"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/xmp_toolkit_ruby/extconf.rb"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "nokogiri", "~> 1.8"
  spec.add_dependency "thor", "~> 1.3"

  spec.add_development_dependency "irb"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-compiler"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rake", "~> 0.7"
  spec.add_development_dependency "rubocop-rspec", "~> 3.5"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
