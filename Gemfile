source 'https://rubygems.org'
ruby '2.3.3', engine: 'jruby', engine_version: '9.1.13.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.10'
# Use sqlite3 as the database for Active Record
gem 'jdbc-sqlite3', platform: :jruby
gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3', '>= 1.3.24', platform: :jruby

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
#gem 'therubyracer',  platforms: :ruby
gem 'therubyrhino'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'
gem 'puma'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

# Pagination
gem 'kaminari', '~> 1.1', '>= 1.1.1'

# PDF generation
gem 'wicked_pdf', '~> 1.1'
gem 'wkhtmltopdf-binary', '~> 0.12.3.1'

# simple_form
gem 'simple_form'

# For schema_to_scaffold
gem 'activesupport'

# Scaffold for schema.rb
gem 'schema_to_scaffold'

# Google Maps for rails - https://github.com/apneadiving/Google-Maps-for-Rails
gem 'gmaps4rails'

# Geocoder - https://github.com/alexreisner/geocoder
# Für grobe Entfernung
gem 'geocoder'

# for calculation of drive time
gem 'google_directions', git: 'https://github.com/hendricius/google-directions-ruby.git'

gem 'bundler'

gem 'rails-jquery-ui-sortable'

gem 'bootstrap-sass', '3.3.5'
gem 'bootstrap-sass-extras'
gem 'devise', '~> 4.3'
gem 'tzinfo-data'
gem 'validates_formatting_of'
gem 'font-awesome-rails'
gem 'active_link_to'

gem 'rails-i18n'
gem 'devise-i18n'
gem 'client_side_validations'
gem 'client_side_validations-simple_form'

# file management / upload
gem 'paperclip', '~> 4.3', '>= 4.3.7'

group :development do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger', '>= 0.1.1'

  # Remove the following if your app does not use Rails
  gem 'capistrano-rails'

  # Remove the following if your server does not use RVM
  gem 'capistrano-rvm'

  # Pry debugger
  gem 'pry'
  gem 'pry-rails'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'better_errors', '~> 2.4'
end

group :development, :test do
  gem 'rspec-rails', '~> 3.6'
  gem 'factory_girl_rails', '~> 4.9'
  gem 'faker', '~> 1.7', '>= 1.7.3'
  gem 'webmock', '~> 3.0', '>= 3.0.1'
end
