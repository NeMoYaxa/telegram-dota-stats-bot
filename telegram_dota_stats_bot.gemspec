# frozen_string_literal: true

require_relative "lib/telegram_dota_stats_bot/version"

Gem::Specification.new do |spec|
  spec.name = "telegram_dota_stats_bot"
  spec.version = TelegramDotaStatsBot::VERSION
  spec.authors = ["Yakov"]
  spec.email = ["yaxa499@gmail.com"]

  spec.summary = "."
  spec.description = "."
  spec.homepage = "."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["allowed_push_host"] = ""
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "."
  spec.metadata["changelog_uri"] = "."
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dotenv"
  spec.add_dependency "graphql-client"
  spec.add_dependency "hashie"
  spec.add_dependency "httparty"
  spec.add_dependency "telegram-bot-ruby"
end
