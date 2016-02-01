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
  $default_prerouting_nat_purge_ignore = [
    '^-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER$',
  ]
  $final_prerouting_nat_purge_ignore = concat($default_prerouting_nat_purge_ignore, $prerouting_nat_purge_ignore)
  firewallchain { 'PREROUTING:nat:IPv4':
    ensure => present,
    purge  => true,
    ignore => $final_prerouting_nat_purge_ignore,
    policy => $prerouting_nat_policy,
  }

  # OUTPUT
  $default_output_nat_purge_ignore = [
    '^-A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER$',
  ]
  $final_output_nat_purge_ignore = concat($default_output_nat_purge_ignore, $output_nat_purge_ignore)
  firewallchain { 'OUTPUT:nat:IPv4':
    ensure => present,
    purge  => true,
    ignore => $final_output_nat_purge_ignore,
    policy => $output_nat_policy,
  }

  # POSTROUTING
  $default_postrouting_nat_purge_ignore = [
    '-j MASQUERADE', # Ignore all MASQUERADE rules - they are too complicated for us to do a better match :-/
  ]
  $final_postrouting_nat_purge_ignore = concat($default_postrouting_nat_purge_ignore, $postrouting_nat_purge_ignore)
  firewallchain { 'POSTROUTING:nat:IPv4':
    ensure => present,
    purge  => true,
    ignore => $final_postrouting_nat_purge_ignore,
    policy => $postrouting_nat_policy,
  }

  # DOCKER - let Docker manage this chain completely
  firewallchain { 'DOCKER:nat:IPv4':
    ensure => present,
  }

  # filter table
  # ============

  # Purge Docker's forwarding rules before we add our own
  $default_forward_filter_purge_ignore = [
    #'^-A FORWARD -o docker0 -j DOCKER$', # This allows unfettered access to containers
    #'^-A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT$', # Move to DOCKER_INPUT
    '^-A FORWARD -i docker0 ! -o docker0 -j ACCEPT$',
    #'^-A FORWARD -i docker0 -o docker0 -j ACCEPT$', # Move to DOCKER_INPUT
  ]
  $final_forward_filter_purge_ignore = concat($default_forward_filter_purge_ignore, $forward_filter_purge_ignore)
  firewallchain { 'FORWARD:filter:IPv4':
    purge  => true,
    ignore => $final_forward_filter_purge_ignore,
    policy => $forward_filter_policy,
  }

  # DOCKER_INPUT
  firewallchain { 'DOCKER_INPUT:filter:IPv4':
    ensure => present,
    purge  => true,
  }

  # -A FORWARD -o docker0 -j DOCKER_INPUT
  firewall { '00101 send FORWARD traffic for docker0 to DOCKER_INPUT chain':
    table    => 'filter',
    chain    => 'FORWARD',
    outiface => 'docker0',
    proto    => 'all',
    jump     => 'DOCKER_INPUT',
  }

  # This is a way to achieve "default DROP" for incoming traffic to the docker0
  # interface.
  # -A DOCKER_INPUT -j DROP
  firewall { '00999 drop DOCKER_INPUT traffic':
    table  => 'filter',
    chain  => 'DOCKER_INPUT',
    proto  => 'all',
    action => 'drop',
  }

  # -A DOCKER_INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  firewall { '00100 accept related, established traffic in DOCKER_INPUT chain':
    table   => 'filter',
    chain   => 'DOCKER_INPUT',
    ctstate => ['RELATED','ESTABLISHED'],
    proto   => 'all',
    action  => 'accept',
  }

  # -A DOCKER_INPUT -i docker0 -j ACCEPT
  firewall { '0100 accept traffic from docker0 DOCKER_INPUT chain':
    table   => 'filter',
    chain   => 'DOCKER_INPUT',
    iniface => 'docker0',
    proto   => 'all',
    action  => 'accept',
  }

  # DOCKER - let Docker manage this chain completely
  firewallchain { 'DOCKER:filter:IPv4':
    ensure => present,
  }

  if $accept_icmp {
    # -A DOCKER_INPUT -p icmp -j DOCKER
    firewall { '00200 DOCKER chain, ICMP DOCKER_INPUT traffic':
      table => 'filter',
      chain => 'DOCKER_INPUT',
      proto => 'icmp',
      jump  => 'DOCKER',
    }
  }

  if $accept_lo {
    # -A DOCKER_INPUT -i lo -j DOCKER
    firewall { '00200 DOCKER chain, DOCKER_INPUT traffic from localhost':
      table   => 'filter',
      chain   => 'DOCKER_INPUT',
      iniface => 'lo',
      proto   => 'all',
      jump    => 'DOCKER',
    }
  }

  if $accept_eth0 {
    # -A DOCKER_INPUT -i eth0 -j DOCKER
    firewall { '00200 DOCKER chain, DOCKER_INPUT traffic from eth0':
      table   => 'filter',
      chain   => 'DOCKER_INPUT',
      iniface => 'eth0',
      proto   => 'all',
      jump    => 'DOCKER',
    }
  }

  if $accept_eth1 {
    # -A DOCKER_INPUT -i eth1 -j DOCKER
    firewall { '00200 DOCKER chain, DOCKER_INPUT traffic from eth1':
      table   => 'filter',
      chain   => 'DOCKER_INPUT',
      iniface => 'eth1',
      proto   => 'all',
      jump    => 'DOCKER',
    }
  }
}
