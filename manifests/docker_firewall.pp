# == Class: seed_stack::docker_firewall
#
# Manages Docker firewall (iptables) rules. This class keeps a few of the
# standard Docker iptables rules and rewrites a few of the others to prevent
# access to Docker containers from the outside world.
#
# The major functionality of the class (limiting outside connections to
# containers) works by adding a chain called DOCKER_INPUT that handles
# connections destined for the docker0 interface. This chain can be used much
# like the INPUT chain in the filter table is typically used to whitelist
# connections, but instead of ACCEPT-ing connections, rather jump to the DOCKER
# chain.
#
# For example, for a regular input rule that allows connections from
# 192.168.0.1 you could do something like:
# -A INPUT -s 192.168.0.1/32 -j ACCEPT
#
# To allow access to Docker containers you would do:
# -A DOCKER_INPUT -s 192.168.0.1/32 -j DOCKER
#
# This class manages all the iptables chains that Docker typically would:
# --nat table:--
# * PREROUTING
# * OUTPUT
# * POSTROUTING
#
# --filter table:--
# * FORWARD
#
# All 4 of the above chains are purged by Puppet. Any rules in those chains that
# aren't managed by Puppet and aren't matched by one of the ignore patterns will
# be deleted.
#
# The management of the DOCKER nat and filter chains is left up to the Docker
# daemon. As such, this class should be used in combination with the
# `--iptables=true` flag (the default) when starting the Docker daemon.
#
# Many of these firewall rules were adapted from:
# https://github.com/hesco/hesco-weave/blob/v0.8.7/manifests/firewall/docker.pp
#
# === Parameters
#
# [*prerouting_nat_purge_ignore*]
#   A list of regexes to use when purging the PREROUTING chain in the nat table.
#   Rules that match one or more of the regexes will not be deleted.
#
# [*prerouting_nat_policy*]
#   The default policy for the PREROUTING chain in the nat table.
#
# [*output_nat_purge_ignore*]
#   A list of regexes to use when purging the OUTPUT chain in the nat table.
#   Rules that match one or more of the regexes will not be deleted.
#
# [*output_nat_policy*]
#   The default policy for the OUTPUT chain in the nat table.
#
# [*postrouting_nat_purge_ignore*]
#   A list of regexes to use when purging the POSTROUTING chain in the nat
#   table. Rules that match one or more of the regexes will not be deleted.
#
# [*output_nat_policy*]
#   The default policy for the POSTROUTING chain in the nat table.
#
# [*forward_filter_purge_ignore*]
#   A list of regexes to use when purging the OUTPUT chain in the nat table.
#   Rules that match one or more of the regexes will not be deleted.
#
# [*output_nat_policy*]
#   The default policy for the OUTPUT chain in the nat table.
#
# [*accept_eth0*]
#   Whether or not to accept connections to Docker containers from the eth0
#   interface.
#
# [*accept_eth1*]
#   Whether or not to accept connections to Docker containers from the eth1
#   interface.
class seed_stack::docker_firewall (
  $prerouting_nat_purge_ignore  = [],
  $prerouting_nat_policy        = undef,
  $output_nat_purge_ignore      = [],
  $output_nat_policy            = undef,
  $postrouting_nat_purge_ignore = [],
  $postrouting_nat_policy       = undef,
  $forward_filter_purge_ignore  = [],
  $forward_filter_policy        = undef,

  $accept_eth0                  = false,
  $accept_eth1                  = false,
) {
  validate_array($prerouting_nat_purge_ignore)
  validate_array($output_nat_purge_ignore)
  validate_array($postrouting_nat_purge_ignore)
  validate_array($forward_filter_purge_ignore)
  validate_bool($accept_eth0)
  validate_bool($accept_eth1)

  include firewall

  # nat table
  # =========

  # PREROUTING
  firewallchain { 'PREROUTING:nat:IPv4':
    ensure => present,
    purge  => true,
    ignore => $prerouting_nat_purge_ignore,
    policy => $prerouting_nat_policy,
  }
  # -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
  firewall { '100 DOCKER table PREROUTING LOCAL traffic':
    table    => 'nat',
    chain    => 'PREROUTING',
    dst_type => 'LOCAL',
    proto    => 'all',
    jump     => 'DOCKER',
  }

  # OUTPUT
  firewallchain { 'OUTPUT:nat:IPv4':
    ensure => present,
    purge  => true,
    ignore => $output_nat_purge_ignore,
    policy => $output_nat_policy,
  }
  # -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
  firewall { '100 DOCKER chain, route LOCAL non-loopback traffic to DOCKER':
    table       => 'nat',
    chain       => 'OUTPUT',
    destination => "! ${::network_lo}/8",
    dst_type    => 'LOCAL',
    proto       => 'all',
    jump        => 'DOCKER',
  }

  # POSTROUTING
  # Docker dynamically adds masquerade rules per container. These are difficult
  # to match on accurately. This regex matches a POSTROUTING rule with identical
  # source (-s) and destination IPv4 addresses (-d), plus some other parameters
  # (likely to be a match on the TCP or UDP port), that jumps to the MASQUERADE
  # action.
  $default_postrouting_nat_purge_ignore = [
    '^-A POSTROUTING -s (?<source>(?:[0-9]{1,3}\.){3}[0-9]{1,3})\/32 -d (\g<source>)\/32 .* -j MASQUERADE$',
  ]
  $final_postrouting_nat_purge_ignore = concat($default_postrouting_nat_purge_ignore, $postrouting_nat_purge_ignore)
  firewallchain { 'POSTROUTING:nat:IPv4':
    ensure => present,
    purge  => true,
    ignore => $final_postrouting_nat_purge_ignore,
    policy => $postrouting_nat_policy,
  }
  if has_ip_network('docker0') {
    # -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
    firewall { '100 DOCKER chain, MASQUERADE docker bridge traffic not bound to docker bridge':
      table    => 'nat',
      chain    => 'POSTROUTING',
      source   => "${::network_docker0}/16",
      outiface => '! docker0',
      proto    => 'all',
      jump     => 'MASQUERADE',
    }
  } else {
    warning('The docker0 interface has not been detected by Facter yet. You may
      need to re-run Puppet and/or ensure that the Docker service is started.')
  }

  # DOCKER - let Docker manage this chain completely
  firewallchain { 'DOCKER:nat:IPv4':
    ensure => present,
  }

  # filter table
  # ============

  # FORWARD
  firewallchain { 'FORWARD:filter:IPv4':
    purge  => true,
    ignore => $forward_filter_purge_ignore,
    policy => $forward_filter_policy,
  }
  # -A FORWARD -i docker0 ! -o docker0 -j ACCEPT
  firewall { '100 accept docker0 traffic to other interfaces on FORWARD chain':
    table    => 'filter',
    chain    => 'FORWARD',
    iniface  => 'docker0',
    outiface => '! docker0',
    proto    => 'all',
    action   => 'accept',
  }

  # DOCKER - let Docker manage this chain completely
  firewallchain { 'DOCKER:filter:IPv4':
    ensure => present,
  }

  # DOCKER_INPUT
  firewallchain { 'DOCKER_INPUT:filter:IPv4':
    ensure => present,
    purge  => true,
  }

  # -A FORWARD -o docker0 -j DOCKER_INPUT
  firewall { '101 send FORWARD traffic for docker0 to DOCKER_INPUT chain':
    table    => 'filter',
    chain    => 'FORWARD',
    outiface => 'docker0',
    proto    => 'all',
    jump     => 'DOCKER_INPUT',
  }

  # This is a way to achieve "default DROP" for incoming traffic to the docker0
  # interface.
  # -A DOCKER_INPUT -j DROP
  firewall { '999 drop DOCKER_INPUT traffic':
    table  => 'filter',
    chain  => 'DOCKER_INPUT',
    proto  => 'all',
    action => 'drop',
  }

  # -A DOCKER_INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  firewall { '100 accept related, established traffic in DOCKER_INPUT chain':
    table   => 'filter',
    chain   => 'DOCKER_INPUT',
    ctstate => ['RELATED', 'ESTABLISHED'],
    proto   => 'all',
    action  => 'accept',
  }

  # -A DOCKER_INPUT -i docker0 -j ACCEPT
  firewall { '100 accept traffic from docker0 DOCKER_INPUT chain':
    table   => 'filter',
    chain   => 'DOCKER_INPUT',
    iniface => 'docker0',
    proto   => 'all',
    action  => 'accept',
  }

  if $accept_eth0 {
    # -A DOCKER_INPUT -i eth0 -j DOCKER
    firewall { '200 DOCKER chain, DOCKER_INPUT traffic from eth0':
      table   => 'filter',
      chain   => 'DOCKER_INPUT',
      iniface => 'eth0',
      proto   => 'all',
      jump    => 'DOCKER',
    }
  }

  if $accept_eth1 {
    # -A DOCKER_INPUT -i eth1 -j DOCKER
    firewall { '200 DOCKER chain, DOCKER_INPUT traffic from eth1':
      table   => 'filter',
      chain   => 'DOCKER_INPUT',
      iniface => 'eth1',
      proto   => 'all',
      jump    => 'DOCKER',
    }
  }
}
