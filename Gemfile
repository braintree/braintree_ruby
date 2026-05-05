source "https://rubygems.org"

gem "builder", "3.2.4"
gem "nokogiri", "~> 1.12"
gem "require_all", "3.0.0"

group :development do
  gem "pry", "~> 0.14.0"
  gem "rake", "13.0.1"
  gem "rspec", "3.9.0"
  gem "webrick", "~>1.7.0"

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7")
    gem "rubocop", "1.85.1"
    gem "rubocop-rspec", "3.9.0"
  else
    gem "rubocop", "1.50.2"
  end
end

# Ruby 3.0+ compatibility - these were removed from default gems starting in Ruby 3.0 or later
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0")
  gem "rexml"
end

# Ruby 3.4+ compatibility - these were removed from default gems starting in Ruby 3.4
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4")
  gem "base64"
  gem "bigdecimal"
  gem "ostruct"
  gem "benchmark"
  gem "logger"
end

# Ruby 4.0+ compatibility - these were removed from default gems starting in Ruby 4.0
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("4.0")
  gem "cgi"
end

group :test do
  gem "rspec_junit_formatter"
  gem "rspec-retry"
  gem "simplecov"
end
