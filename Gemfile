source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.5"

gem "rails", "~> 7.0.3", ">= 7.0.3.1"

gem "sprockets-rails"

gem "pg", "~> 1.1"

gem "puma", "~> 5.0"

gem "jsbundling-rails"

gem "turbo-rails"

gem "stimulus-rails"

gem "cssbundling-rails"

gem "jbuilder"

gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem 'rspec-rails', '~> 5.0.0'
  gem 'factory_bot_rails'
end

group :development do
  gem "web-console"
  gem 'bullet'
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"

end

gem "dockerfile-rails", ">= 1.6", :group => :development

gem 'sorcery', "0.16.3"
gem 'carrierwave', '~> 2.0'
gem 'config'
gem 'letter_opener_web', '~> 2.0'
gem 'dotenv-rails'

gem 'omniauth-google-oauth2'
gem 'httparty'

gem 'ransack', "3.2.1"
gem 'kaminari'
gem 'aws-sdk-s3', require: false
gem 'fog-aws', '~> 3.0'

gem 'rack-cors'
gem 'jwt'
