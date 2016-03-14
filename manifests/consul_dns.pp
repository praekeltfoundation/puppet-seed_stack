# == Class: seed_stack::consul_dns
#
# Simplifies the installation of Consul with Dnsmasq. Makes it possible to look
# up Consul services via standard DNS - i.e. `dig marathon.service.consul.`
# on the host should work. Also the easiest way to add a node to the Consul
# cluster.
#
# === Parameters
#
# [*consul_version*]
#   The version of Consul to install.
#
# [*server*]
#   Whether or not this node is a Consul server.
#
# [*join*]
#   A list of nodes in the Consul cluster that Consul should attempt to join
#   when starting up.
#
# [*advertise_addr*]
#   The address for Consul to use when advertising services on this node. Also
#   used for the Dnsmasq host alias.
#
# [*client_addr*]
#   The address Consul should use to expose the client. i.e. Consul's listen
#   address.
#
# [*domain*]
#   The domain of addresses that Consul should provide and should be used for
#   for DNS lookups.
#
# [*encrypt*]
#   The encryption key for the Consul cluster.
#
# [*bootstrap_expect*]
#   The number of expected server nodes in the Consul cluster. Consul will wait
#   for this number of servers to be present before bootstrapping the cluster.
#   This parameter is not valid for non-server nodes.
#
# [*ui*]
#   Whether or not to enable the Consul web UI. FIXME: Setting this false
#   doesn't seem to disable the UI. Consul 0.6.1 bug? See #7.
#
# [*recursors*]
#   List of upstream DNS servers to ask about names that Consul isn't
#   authoritative for. By default, this only contains localhost so Consul can
#   resolve the targets of CNAME records and include them in its answer.
#   (Without this, the client would have to make extra queries, and way too
#   many clients give up instead.)
#
# [*dnsmasq_ensure*]
#   The ensure value for the Dnsmasq package.
#
# [*dnsmasq_host_alias*]
#   An alias for the host (advertise) address that Dnsmasq will serve. This
#   should match the domain for the Nginx service router if one is being used.
#
# [*dnsmasq_opts*]
#   A hash of extra options to configure Dnsmasq with. e.g.
#   { 'listen-address' => $::ipaddress_lo, }.
class seed_stack::consul_dns (
  $advertise_addr,
  $join,
  $consul_version     = $seed_stack::params::consul_version,
  $server             = false,
  $client_addr        = $seed_stack::params::consul_client_addr,
  $domain             = $seed_stack::params::consul_domain,
  $encrypt            = undef,
  $bootstrap_expect   = undef,
  $ui                 = true,
  $recursors          = [$::ipaddress_lo],

  $dnsmasq_ensure     = 'installed',
  $dnsmasq_host_alias = $seed_stack::params::router_domain,
  $dnsmasq_opts       = {},
) inherits seed_stack::params {
  validate_bool($server)
  validate_array($join)
  validate_ip_address($advertise_addr)
  validate_ip_address($client_addr)
  validate_bool($ui)
  validate_array($recursors)
  validate_hash($dnsmasq_opts)

  if $bootstrap_expect != undef {
    if $server {
      validate_integer($bootstrap_expect, undef, 1) # Ensure >= 1
    } else {
      fail('"bootstrap_expect" is an invalid parameter for client Consul nodes.')
    }
  }

  # Consul
  # ------

  $base_config_hash = {
    'server'         => $server,
    'data_dir'       => '/var/lib/consul',
    'log_level'      => 'INFO',
    'advertise_addr' => $advertise_addr,
    'client_addr'    => $client_addr,
    'retry_join'     => $join,
    'domain'         => $domain,
    'encrypt'        => $encrypt,
    'ui'             => $ui,
    'recursors'      => $recursors,
  }

  if $server {
    $extra_config_hash = { 'bootstrap_expect' => $bootstrap_expect }
  } else {
    $extra_config_hash = {}
  }

  $config_hash = merge($base_config_hash, $extra_config_hash)

  class { 'consul':
    version     => $consul_version,
    config_hash => $config_hash,
    require     => Package['unzip'],
  }

  if ! defined(Package['unzip']) {
    package { 'unzip':
      ensure => installed,
    }
  }

  $dnsmasq_client_addr = $client_addr ? {
    '0.0.0.0' => $::ipaddress_lo,
    default   => $client_addr,
  }

  # Dnsmasq
  # -------
  $dnsmasq_base_opts = {
    'cache-size'  => '0',
    'server'      => "/${domain}/${dnsmasq_client_addr}#8600",
    'host-record' => "${dnsmasq_host_alias},${advertise_addr}",
  }
  $dnsmasq_final_opts = merge($dnsmasq_base_opts, $dnsmasq_opts)
  $dnsmasq_config = join(join_keys_to_values($dnsmasq_final_opts, '='), "\n")

  package { 'dnsmasq':
    ensure => $dnsmasq_ensure,
  }
  ->
  file { '/etc/dnsmasq.d/consul':
    content => $dnsmasq_config,
  }
  ~>
  service { 'dnsmasq': }
}
