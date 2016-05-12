require 'puppetlabs_spec_helper/module_spec_helper'

require 'rspec-puppet-facts'
include RspecPuppetFacts

def mustpass(param)
  /(Must pass #{param}|expects a value for parameter '#{param}')/
end

def puppet3_hashlist_to_a(hashlist)
  # Puppet 3 does weird things to lists of hashes. This method converts a list
  # of hashes to a list of arrays when running under Puppet 3.
  if Gem::Version.new(Puppet.version) < Gem::Version.new('4.0.0')
    listlist = hashlist.map(&:to_a)
    return listlist.length == 1 ? listlist.flatten(1) : listlist
  end
  hashlist
end


def match_json(expected)
  proc { |content| match(expected) === JSON.load(content) }
end
