# == Class: seed_stack::controller
#
# === Parameters
#
# [*advertise_addr*]
#   The advertise IP address for the node. All services will be exposed on this
#   address.
#
# [*controller_addrs*]
#   A list of IP addresses for all controllers in the cluster (i.e. a list of
#   each controller's advertise_addr). NOTE: This list must be identical (same
#   elements, same order) for ALL controller nodes.
#
# [*hostname*]
#   The hostname for the node.
#
# [*controller_worker*]
#   Whether or not this node is a combination controller/worker.
#
# [*install_java*]
#   Whether or not to install Oracle Java 8.
#
# [*zookeeper_ensure*]
#   The package ensure value for Zookeeper (note this is for all Zookeeper
#   packages - i.e. 'zookeeper' and 'zookeeperd').
#
# [*zookeeper_client_addr*]
#   The address that Zookeeper will listen for clients on.
#
# [*mesos_ensure*]
#   The package ensure value for Mesos.
#
# [*mesos_listen_addr*]
#   The address that Mesos will listen on.
#
# [*mesos_cluster*]
#   The Mesos cluster name.
#
# [*marathon_ensure*]
#   The package ensure value for Marathon.
#
# [*consul_version*]
#   The version of Consul to install.
#
# [*consul_client_addr*]
#   The address to which Consul will bind client interfaces, including the HTTP,
#   DNS, and RPC servers.
#
# [*consul_domain*]
#   The domain to be served by Consul DNS.
#
# [*consul_encrypt*]
#   The secret key to use for encryption of Consul network traffic.
#
# [*consul_ui*]
#   Whether or not to enable the Consul web UI. FIXME: Setting this false
#   doesn't seem to disable the UI. Consul 0.6.1 bug? See #7.
#
# [*dnsmasq_ensure*]
#   The ensure value for the Dnsmasq package.
#
# [*dnsmasq_host_alias*]
#   An alias for the host (advertise) address that Dnsmasq will serve.
#
# [*consular_ensure*]
#   The package ensure value for Consular.
#
# [*consular_sync_interval*]
#   The interval in seconds between Consular syncs.
class seed_stack::controller (
  # Common
  $advertise_addr         = $seed_stack::cluster_params::advertise_addr,
  $controller_addrs       = $seed_stack::cluster_params::controller_addrs,
  $hostname               = $::fqdn,
  $controller_worker      = false,
  $install_java           = true,

  # Zookeeper
  $zookeeper_ensure       = $seed_stack::cluster_params::zookeeper_ensure,
  $zookeeper_client_addr  = $seed_stack::cluster_params::zookeeper_client_addr,

  # Mesos
  $mesos_ensure           = $seed_stack::cluster_params::mesos_ensure,
  $mesos_listen_addr      = $seed_stack::cluster_params::mesos_listen_addr,
  $mesos_cluster          = $seed_stack::cluster_params::mesos_cluster,

  # Marathon
  $marathon_ensure        = $seed_stack::cluster_params::marathon_ensure,

  # Consul
  $consul_version         = $seed_stack::cluster_params::consul_version,
  $consul_client_addr     = $seed_stack::cluster_params::consul_client_addr,
  $consul_domain          = $seed_stack::cluster_params::consul_domain,
  $consul_encrypt         = $seed_stack::cluster_params::consul_encrypt,
  $consul_ui              = true,

  # Dnsmasq
  $dnsmasq_ensure         = $seed_stack::cluster_params::dnsmasq_ensure,
  $dnsmasq_host_alias     = $seed_stack::cluster_params::dnsmasq_host_alias,

  # Consular
  $consular_ensure        = $seed_stack::cluster_params::consular_ensure,
  $consular_sync_interval = $seed_stack::cluster_params::consular_sync_interval,
) inherits seed_stack::cluster_params {
  if $advertise_addr == undef {
    fail("Must pass advertise_addr to Class[${title}]")
  }
  if $controller_addrs == undef {
    fail("Must pass controller_addrs to Class[${title}]")
  }

  validate_ip_address($advertise_addr)
  validate_array($controller_addrs)
  validate_bool($controller_worker)
  validate_bool($install_java)
  validate_ip_address($zookeeper_client_addr)
  validate_ip_address($mesos_listen_addr)
  validate_ip_address($consul_client_addr)
  validate_bool($consul_ui)
  validate_integer($consular_sync_interval)
  if ! member($controller_addrs, $advertise_addr) {
    fail("The address for this node (${advertise_addr}) must be one of the
      controller addresses (${controller_addrs}).")
  }

  if $install_java {
    include webupd8_oracle_java
    # Ensure Java is installed before any of the things that depend on it
    Class['webupd8_oracle_java'] -> Package['zookeeper']
    Class['webupd8_oracle_java'] -> Package['mesos']
    Class['webupd8_oracle_java'] -> Package['marathon']
  }

  # There is no `find_index` equivalent in Puppet stdlib
  # $zk_id = hash(zip($controller_addrs, range(1, size($controller_addrs))))[$advertise_addr] # :trollface:
  $zk_id = inline_template('<%= (@controller_addrs.find_index(@advertise_addr) || 0) + 1 %>')
  class { 'zookeeper':
    ensure    => $zookeeper_ensure,
    id        => $zk_id,
    servers   => $controller_addrs,
    client_ip => $zookeeper_client_addr,
  }

  $zk_base = join(suffix($controller_addrs, ':2181'), ',')
  $mesos_zk = "zk://${zk_base}/mesos"
  class { 'mesos':
    ensure         => $mesos_ensure,
    repo           => 'mesosphere',
    listen_address => $mesos_listen_addr,
    zookeeper      => $mesos_zk,
  }

  class { 'mesos::master':
    cluster => $mesos_cluster,
    options => {
      hostname     => $hostname,
      advertise_ip => $advertise_addr,
      quorum       => size($controller_addrs) / 2 + 1 # Note: integer division
    },
  }

  if ! $controller_worker {
    # Make Puppet stop the mesos-slave service
    service { 'mesos-slave':
      ensure  => stopped,
      enable  => false,
      require => Package['mesos'],
    }
  }

  $marathon_zk = "zk://${zk_base}/marathon"
  class { 'marathon':
    package_ensure => $marathon_ensure,
    repo_manage    => false,
    zookeeper      => $marathon_zk,
    master         => $mesos_zk,
    syslog         => false,
    options        => {
      hostname         => $hostname,
      event_subscriber => 'http_callback',
    },
  }
  # Ensure Mesos repo is added before installing Marathon
  Class['mesos::repo'] -> Package['marathon']

  class { 'seed_stack::consul_dns':
    consul_version     => $consul_version,
    server             => true,
    join               => delete($controller_addrs, $advertise_addr),
    bootstrap_expect   => size($controller_addrs),
    advertise_addr     => $advertise_addr,
    client_addr        => $consul_client_addr,
    domain             => $consul_domain,
    encrypt            => $consul_encrypt,
    ui                 => $consul_ui,
    dnsmasq_ensure     => $dnsmasq_ensure,
    dnsmasq_host_alias => $dnsmasq_host_alias,
  }

  consul::service {
    'marathon':
      port   => 8080,
      checks => [
        {
          # Marathon listens on all interfaces by default
          http     => "http://${::ipaddress_lo}:8080/ping",
          interval => '10s',
          timeout  => '1s',
        },
      ];

    'mesos-master':
      port   => 5050,
      checks => [
        {
          http     => "http://${mesos_listen_addr}:5050/master/health",
          interval => '10s',
          timeout  => '1s',
        },
      ];

    'zookeeper':
      port   => 2181,
      checks => [
        {
          script   => "echo \"srvr\" | nc ${zookeeper_client_addr} 2181",
          interval => '30s',
        },
      ];
  }

  class { 'consular':
    package_ensure => $consular_ensure,
    consul         => "http://${consul_client_addr}:8500",
    sync_interval  => $consular_sync_interval,
    purge          => true,
  }
}
