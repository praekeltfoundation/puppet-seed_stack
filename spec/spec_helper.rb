require 'puppetlabs_spec_helper/module_spec_helper'

require 'rspec-puppet-facts'
include RspecPuppetFacts

def must_pass(param)
  /(Must pass #{param}|expects a value for parameter '#{param}')/
end
