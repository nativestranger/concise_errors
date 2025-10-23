# frozen_string_literal: true

require_relative "lib/concise_errors/version"

Gem::Specification.new do |spec|
  spec.name = "concise_errors"
  spec.version = ConciseErrors::VERSION
  spec.authors = ["Obie Fernandez"]
  spec.email = ["obiefernandez@gmail.com"]

  spec.summary = "Minimal Rails error pages tuned for AI agents and compact debugging."
  spec.description = <<~DESC
    ConciseErrors replaces ActionDispatch::DebugExceptions with a compact error page that highlights the exception and a truncated backtrace, making Rails crashes easier for humans and AI helpers alike.
  DESC
  spec.homepage = "https://github.com/obie/concise_errors"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
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

  spec.add_dependency "actionpack", ">= 6.1", "< 9.0"
end
