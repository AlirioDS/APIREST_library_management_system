source "https://rubygems.org"

ruby "3.4.4"

gem "rails", "~> 8.0.2"
gem "pg", "~> 1.5.9"
gem "puma", "6.6.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "rack-cors"

# Authentication & Authorization
gem "jwt"
gem "pundit"
gem "bcrypt", "~> 3.1.7"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  # Testing gems
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.5"
end

group :test do
  gem "shoulda-matchers", "~> 6.4"
end
