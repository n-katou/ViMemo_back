# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!
Rails.application.config.secret_key_base = ENV["SECRET_KEY_BASE"]
