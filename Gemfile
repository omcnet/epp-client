source 'http://rubygems.org'

# Specify your gem's dependencies in epp-client.gemspec
Dir['*.gemspec'].each do |i|
  gemspec :name => i.sub(/\.gemspec$/, '')
end

group :development,:test do
  gem 'rspec'
  gem 'guard-rspec'
  gem 'pry'
end
