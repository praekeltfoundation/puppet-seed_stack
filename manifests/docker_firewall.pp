# == Class: seed_stack::docker_firewall
#
# Roughly taken from: https://github.com/hesco/hesco-weave/blob/master/manifests/firewall/docker.pp
class seed_stack::docker_firewall (
  $accept_icmp = true,
  $accept_lo   = true,
  $accept_eth0 = false,
  $accept_eth1 = false,
) {
  include firewall

  # filter table
  # ============

  # -A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  firewall { '00100 accept related, established traffic returning to docker0 bridge in FORWARD chain':
    table    => 'filter',
    chain    => 'FORWARD',
    outiface => 'docker0',
    proto    => 'all',
    ctstate  => ['RELATED','ESTABLISHED'],
    action   => 'accept',
  }

  # -A FORWARD -i docker0 ! -o docker0 -j ACCEPT
  firewall { '00100 accept docker0 traffic to other interfaces on FORWARD chain':
    table    => 'filter',
    chain    => 'FORWARD',
    iniface  => 'docker0',
    outiface => '! docker0',
    proto    => 'all',
    action   => 'accept',
  }

  # -A FORWARD -i docker0 -o docker0 -j ACCEPT
  firewall { '00100 accept docker0 to docker0 FORWARD traffic':
    table    => 'filter',
    chain    => 'FORWARD',
    iniface  => 'docker0',
    outiface => 'docker0',
    proto    => 'all',
    action   => 'accept',
  }

  firewallchain { 'DOCKER_INPUT:filter:IPv4':
    ensure => present,
  }

  # -A FORWARD -o docker0 -j DOCKER_INPUT
  firewall { '0101 DOCKER_INPUT chain, docker0 FORWARD traffic':
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

  firewallchain { 'DOCKER:filter:IPv4':
    ensure => present,
  }

  if $accept_icmp {
    # -A DOCKER_INPUT -p icmp -j DOCKER
    firewall { '0100 DOCKER chain, ICMP DOCKER_INPUT traffic':
      table => 'filter',
      chain => 'DOCKER_INPUT',
      proto => 'icmp',
      jump  => 'DOCKER',
    }
  }

  if $accept_lo {
    # -A DOCKER_INPUT -i lo -j DOCKER
    firewall { '0100 DOCKER chain, DOCKER_INPUT traffic from localhost':
      table   => 'filter',
      chain   => 'DOCKER_INPUT',
      iniface => 'lo',
      proto   => 'all',
      jump    => 'DOCKER',
    }
  }

  if $accept_eth0 {
    # -A DOCKER_INPUT -i eth0 -j DOCKER
    firewall { '0100 DOCKER chain, DOCKER_INPUT traffic from eth0':
      table   => 'filter',
      chain   => 'DOCKER_INPUT',
      iniface => 'eth0',
      proto   => 'all',
      jump    => 'DOCKER',
    }
  }

  if $accept_eth1 {
    # -A DOCKER_INPUT -i eth1 -j DOCKER
    firewall { '0100 DOCKER chain, DOCKER_INPUT traffic from eth1':
      table   => 'filter',
      chain   => 'DOCKER_INPUT',
      iniface => 'eth1',
      proto   => 'all',
      jump    => 'DOCKER',
    }
  }

  # This is a rule that we don't actually want but Docker adds if it is not
  # present. Set the priority really low so that it comes last.
  # -A FORWARD -o docker0 -j DOCKER
  firewall { '00999 DOCKER chain, docker0 traffic':
    table    => 'filter',
    chain    => 'FORWARD',
    outiface => 'docker0',
    proto    => 'all',
    jump     => 'DOCKER',
  }


  # nat table
  # =========

  # -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
  firewall { '00100 DOCKER chain PREROUTING LOCAL traffic':
    table    => 'nat',
    chain    => 'PREROUTING',
    dst_type => 'LOCAL',
    proto    => 'all',
    jump     => 'DOCKER',
  }

  # -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
  firewall { '00100 DOCKER chain, route LOCAL non-loopback traffic to DOCKER':
    table       => 'nat',
    chain       => 'OUTPUT',
    destination => "! ${::network_lo}/8",
    dst_type    => 'LOCAL',
    proto       => 'all',
    jump        => 'DOCKER',
  }

  # -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
  firewall { '00100 DOCKER chain, MASQUERADE docker bridge traffic not bound to docker bridge':
    table    => 'nat',
    chain    => 'POSTROUTING',
    source   => "${::network_docker0}/16",
    outiface => '! docker0',
    proto    => 'all',
    jump     => 'MASQUERADE',
  }

  firewallchain { 'DOCKER:nat:IPv4':
    ensure => present,
  }
}
