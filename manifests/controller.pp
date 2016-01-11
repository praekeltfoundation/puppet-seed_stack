# == Class: seed_stack::controller
#
# === Parameters
#
# [*controller_addresses*]
#   A list of IP addresses for all controllers in the cluster.
#
# [*address*]
#   The IP address for the node. All services will be exposed on this address.
#
# [*hostname*]
#   The hostname for the node.
#
# [*install_java*]
#   Whether or not to install Oracle Java 8.
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
# [*consular_ensure*]
#   The package ensure value for Consular.
#
# [*consular_sync_interval*]
#   The interval in seconds between Consular syncs.
class seed_stack::controller (
  # Common
  $controller_addresses   = [$::ipaddress_lo],
  $address                = $::ipaddress_lo,
  $hostname               = $::hostname,
  $install_java           = true,

  # Mesos
  $mesos_ensure           = $seed_stack::params::mesos_ensure,
  $mesos_listen_addr      = $seed_stack::params::mesos_listen_addr,
  $mesos_cluster          = $seed_stack::params::mesos_cluster,

  # Marathon
  $marathon_ensure        = $seed_stack::params::marathon_ensure,

  # Consul
  $consul_version         = $seed_stack::params::consul_version,
  $consul_client_addr     = $seed_stack::params::consul_client_addr,
  $consul_domain          = $seed_stack::params::consul_domain,
  $consul_encrypt         = undef,
  $consul_ui              = true,

  # Consular
  $consular_ensure        = $seed_stack::params::consular_ensure,
  $consular_sync_interval = $seed_stack::params::consular_sync_interval,
) inherits seed_stack::params {

  # Basic parameter validation
  validate_ip_address($address)
  validate_bool($install_java)
  validate_ip_address($mesos_listen_addr)
  validate_ip_address($consul_client_addr)
  validate_bool($consul_ui)
  validate_integer($consular_sync_interval)
  if ! member($controller_addresses, $address) {
    fail("The address for this node (${address}) must be one of the controller
      addresses (${controller_addresses}).")
  }

  if $install_java {
    include webupd8_oracle_java
    # Ensure Java is installed before any of the things that depend on it
    Package['oracle-java8-installer'] -> Package['zookeeper']
    Package['oracle-java8-installer'] -> Package['mesos']
    Package['oracle-java8-installer'] -> Package['marathon']
  }

  class { 'zookeeper':
    servers   => $controller_addresses,
    client_ip => $address
  }

  $mesos_zk = inline_template('zk://<%= @controller_addresses.map { |c| "#{c}:2181"}.join(",") %>/mesos')
  class { 'mesos':
    ensure         => $mesos_ensure,
    repo           => 'mesosphere',
    listen_address => $mesos_listen_addr,
    zookeeper      => $mesos_zk,
  }

  class { 'mesos::master':
    cluster => $mesos_cluster,
    options => {
      hostname => $hostname,
      quorum   => inline_template('<%= (@controller_addresses.size() / 2 + 1).floor() %>'),
    },
  }

  $marathon_zk = inline_template('zk://<%= @controller_addresses.map { |c| "#{c}:2181"}.join(",") %>/marathon')
  class { 'marathon':
    ensure      => $marathon_ensure,
    manage_repo => false,
    zookeeper   => $marathon_zk,
    master      => $mesos_zk,
    options     => {
      hostname         => $hostname,
      event_subscriber => 'http_callback',
    },
  }
  # Ensure Mesos repo is added before installing Marathon
  Apt::Source['mesosphere'] -> Package['marathon']

  # Consul requires unzip to install
  package { 'unzip':
    ensure => installed,
  }

  class { 'consul':
    version     => $consul_version,
    config_hash => {
      'server'           => true,
      'bootstrap_expect' => size($controller_addresses),
      'retry_join'       => delete($controller_addresses, $address),
      'data_dir'         => '/var/consul',
      'log_level'        => 'INFO',
      'advertise_addr'   => $address,
      'client_addr'      => $consul_client_addr,
      'domain'           => $consul_domain,
      'encrypt'          => $consul_encrypt,
      'ui'               => $consul_ui,
    },
    services    => {
      'marathon'     => {
        port => 8080
      },
      'mesos-master' => {
        port => 5050
      },
      'zookeeper'    => {
        port => 2181
      },
    },
    require     => Package['unzip']
  }

  $dnsmasq_server = inline_template('<%= @consul_domain.chop() %>') # Remove trailing '.'
  package { 'dnsmasq': }
  ~>
  file { '/etc/dnsmasq.d/consul':
    content => "cache-size=0\nserver=/${dnsmasq_server}/${address}#8600",
  }
  ~>
  service { 'dnsmasq': }

  class { 'consular':
    ensure        => $consular_ensure,
    consular_args => [
      "--host=${address}",
      "--sync-interval=${consular_sync_interval}",
      '--purge', # TODO: Make configurable
      "--registration-id=${hostname}",
      "--consul=http://${address}:8500",
      "--marathon=http://${address}:8080",
    ],
  }
}
