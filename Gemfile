source 'http://rubygems.org'

gemspec

group :development do
  gem 'yard'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
end

group :development, :test do
  gem 'rake'
  gem 'rack-test'
  gem 'rspec', '~> 2.9'
  gem 'bundler'
  gem 'pry'
  gem 'faraday'
  gem 'thin'

  # integration
  gem 'capybara-webkit'
  gem 'em-eventsource'
  gem 'em-http-request'
  gem 'sinatra'
  gem 'sinatra-synchrony'
end

# debugger for 1.9 only
group :debug do
  gem 'debugger'
end

# Mac specific
group :darwin do
  gem 'rb-fsevent'
  gem 'growl'
end