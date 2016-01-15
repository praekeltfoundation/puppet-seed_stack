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
# [*consul_address*]
#   The address for the Consul DNS service.
#
# [*consul_port*]
#   The port for the Consul DNS service.
class seed_stack::dnsmasq_consul (
  $ensure         = 'installed',
  $consul_domain  = 'consul.',
  $consul_address = $::ipaddress_lo,
  $consul_port    = 8600,
) {
  $dnsmasq_domain = inline_template('<%= @consul_domain.chop() %>') # Remove trailing '.'
  package { 'dnsmasq':
    ensure => $ensure
  }
  ->
  file { '/etc/dnsmasq.d/consul':
    content => "cache-size=0\nserver=/${dnsmasq_domain}/${consul_address}#${consul_port}",
  }
  ~>
  service { 'dnsmasq': }
}
