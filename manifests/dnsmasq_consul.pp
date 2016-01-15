# == Class: seed_stack::dnsmasq_consul
#
# Dnsmasq can be used to serve DNS requests, sending requests for the Consul
# domain to Consul and everything else through regular DNS.
#
# === Parameters
#
# [*ensure*]
#   The package ensure value for Dnsmasq.
#
# [*consul_domain*]
#   The domain for which DNS lookups should be sent to Consul.
#
# [*consul_client_addr*]
#   The address for the Consul DNS service.
class seed_stack::dnsmasq_consul (
  $ensure             = 'installed',
  $consul_domain      = $seed_stack::params::consul_domain,
  $consul_client_addr = $seed_stack::params::consul_client_addr,
) inherits seed_stack::params {
  $dnsmasq_domain = inline_template('<%= @consul_domain.chop() %>') # Remove trailing '.'
  package { 'dnsmasq':
    ensure => $ensure
  }
  ->
  file { '/etc/dnsmasq.d/consul':
    content => "cache-size=0\nserver=/${dnsmasq_domain}/${consul_client_addr}#8600",
  }
  ~>
  service { 'dnsmasq': }
}
