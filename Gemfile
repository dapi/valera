# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.1.1'
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem 'tailwindcss-rails'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Данный репоизтоий используется только из-за поддержки Rails 8.1.
# Реальный оригиниальный источник с документацией - https://github.com/telegram-bot-rb/telegram-bot
gem 'telegram-bot', github: 'mprokopov/telegram-bot'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem 'thruster', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'image_processing', '~> 1.2'

group :development, :test do
  gem 'vcr'
  gem 'webmock'
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem 'bundler-audit', require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem 'brakeman', require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem 'rubocop-rails-omakase', require: false
  gem 'rubocop-yard', require: false

  # Additional RuboCop extensions for better Rails integration
  gem 'rubocop-capybara', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false

  # YARD Documentation generation
  gem 'yard', require: false
end

group :development do
  gem 'claude-on-rails'
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # YardMCP - MCP server for YARD documentation integration with Claude
  gem 'yardmcp', require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'

  # Testing dependencies for analytics
  gem 'mocha'
  gem 'timecop'
  gem 'minitest-stub_any_instance'
end

gem 'slim-rails', '~> 3.7'

gem 'anyway_config', '~> 2.7'

gem 'semver2', '~> 3.4'

gem 'ruby_llm', github: 'crmne/ruby_llm'

gem 'hiredis', '~> 0.6.3'
gem 'redis', '~> 5.4'

gem 'bugsnag', '~> 6.28'

gem 'request_store'

gem 'nanoid', '~> 2.0'

# Markdown processing for Telegram Bot API compatibility
gem 'kramdown', '~> 2.5'
gem 'sanitize', '~> 7.0'
