source 'https://rubygems.org'

group :test do
  # Rake's 'last_comment', which is used by puppet-catalog-test, was briefly
  # removed in Rake 11.0.x. It will be removed in Rake 12.
  # See release notes for Rake 11.0.0 and 11.1.0:
  # https://github.com/ruby/rake/blob/master/History.rdoc
  # ...and https://github.com/invadersmustdie/puppet-catalog-test/pull/29
  gem 'rake', '>= 11.1.0', '< 12'

  puppetversion = ENV['PUPPET_VERSION'] || '~> 4'
  gem 'puppet', puppetversion

  gem 'librarian-puppet'
  gem 'metadata-json-lint'
  gem 'puppet-lint', '~> 2.0.0'
  gem 'puppetlabs_spec_helper', '~> 1.1.0'
  gem 'rspec-puppet-facts'

  gem 'rubocop', '~>0.37.0'
  # On certain setups, rubocop seems to crash without this gem :-/
  gem 'safe_yaml', '~> 1.0.0'

  if RUBY_VERSION < '2.0'
    # Some things depend on this, and newer versions hate old Ruby.
    gem 'json', '< 2.0.0'
  end
end
