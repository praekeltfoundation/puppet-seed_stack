# == Class: seed_stack::docker_firewall
#
# Roughly taken from: https://github.com/hesco/hesco-weave/blob/master/manifests/firewall/docker.pp
class seed_stack::docker_firewall (
  $prerouting_nat_purge_ignore  = [],
  $prerouting_nat_policy        = undef,
  $output_nat_purge_ignore      = [],
  $output_nat_policy            = undef,
  $postrouting_nat_purge_ignore = [],
  $postrouting_nat_policy       = undef,
  $forward_filter_purge_ignore  = [],
  $forward_filter_policy        = undef,

  $accept_icmp                  = true,
  $accept_lo                    = true,
  $accept_eth0                  = false,
  $accept_eth1                  = false,
) {
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
  # -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
  firewall { '100 DOCKER chain, MASQUERADE docker bridge traffic not bound to docker bridge':
    table    => 'nat',
    chain    => 'POSTROUTING',
    source   => "${::network_docker0}/16",
    outiface => '! docker0',
    proto    => 'all',
    jump     => 'MASQUERADE',
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

  if $accept_icmp {
    # -A DOCKER_INPUT -p icmp -j DOCKER
    firewall { '200 DOCKER chain, ICMP DOCKER_INPUT traffic':
      table => 'filter',
      chain => 'DOCKER_INPUT',
      proto => 'icmp',
      jump  => 'DOCKER',
    }
  }

  if $accept_lo {
    # -A DOCKER_INPUT -i lo -j DOCKER
    firewall { '200 DOCKER chain, DOCKER_INPUT traffic from localhost':
      table   => 'filter',
      chain   => 'DOCKER_INPUT',
      iniface => 'lo',
      proto   => 'all',
      jump    => 'DOCKER',
    }
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
