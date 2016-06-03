source 'https://rubygems.org'

group :test do
  gem 'rake', '<11.0.0' # See https://github.com/invadersmustdie/puppet-catalog-test/pull/29

  puppetversion = ENV['PUPPET_VERSION'] || '~> 4'
  gem 'puppet', puppetversion

  gem 'librarian-puppet'
  gem 'metadata-json-lint'
  gem 'puppetlabs_spec_helper', '~> 1.1.0'
  gem 'rspec-puppet-facts'

  gem 'rubocop', '~>0.37.0'
  # On certain setups, rubocop seems to crash without this gem :-/
  gem 'safe_yaml', '~> 1.0.0'
end
