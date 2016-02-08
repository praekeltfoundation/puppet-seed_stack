# == Class: seed_stack::worker
#
# === Parameters
#
# [*controller_addresses*]
#   A list of IP addresses for all controllers in the cluster.
#
# [*address*]
#   The advertise IP address for the node. All services will be exposed on this
#   address.
#
# [*hostname*]
#   The hostname for the node.
#
# [*controller_worker*]
#   Whether or not this node is a combination controller/worker.
#
# [*mesos_ensure*]
#   The package ensure value for Mesos.
#
# [*mesos_listen_addr*]
#   The address that Mesos will listen on.
#
# [*mesos_resources*]
#   A hash of the available Mesos resources for the node.
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
#   An alias for the host (advertise) address that Dnsmasq will serve. This
#   will also be used for the Nginx service router's domain.
#
# [*consul_template_version*]
#   The version of Consul Template to install.
#
# [*nginx_ensure*]
#   The ensure value for the Nginx package.
#
# [*nginx_router_listen_addr*]
#   The address that Nginx should listen on when serving routing requests.
#
# [*docker_ensure*]
#   The package ensure value for Docker Engine.
class seed_stack::worker (
  # Common
  $controller_addresses,
  $address,
  $hostname                 = $::fqdn,
  $controller_worker        = false,

  # Mesos
  $mesos_ensure             = $seed_stack::params::mesos_ensure,
  $mesos_listen_addr        = $seed_stack::params::mesos_listen_addr,
  $mesos_resources          = $seed_stack::params::mesos_resources,

  # Consul
  $consul_version           = $seed_stack::params::consul_version,
  $consul_client_addr       = $seed_stack::params::consul_client_addr,
  $consul_domain            = $seed_stack::params::consul_domain,
  $consul_encrypt           = undef,
  $consul_ui                = false,

  # Dnsmasq
  $dnsmasq_ensure         = $seed_stack::params::dnsmasq_ensure,
  $dnsmasq_host_alias     = $seed_stack::params::dnsmasq_host_alias,

  # Consul Template
  $consul_template_version  = $seed_stack::params::consul_template_version,

  # Nginx
  $nginx_ensure             = $seed_stack::params::nginx_ensure,
  $nginx_router_listen_addr = $seed_stack::params::nginx_router_listen_addr,

  # Docker
  $docker_ensure            = $seed_stack::params::docker_ensure,
) inherits seed_stack::params {
  validate_array($controller_addresses)
  validate_ip_address($address)
  validate_bool($controller_worker)
  validate_ip_address($mesos_listen_addr)
  validate_hash($mesos_resources)
  validate_ip_address($consul_client_addr)
  validate_bool($consul_ui)
  validate_ip_address($nginx_router_listen_addr)

  $zk_base = join(suffix($controller_addresses, ':2181'), ',')
  $mesos_zk = "zk://${zk_base}/mesos"
  if ! $controller_worker {
    class { 'mesos':
      ensure         => $mesos_ensure,
      repo           => 'mesosphere',
      listen_address => $mesos_listen_addr,
      zookeeper      => $mesos_zk,
    }

    # Make Puppet stop the mesos-master service
    service { 'mesos-master':
      ensure  => stopped,
      enable  => false,
      require => Package['mesos'],
    }
  }

  class { 'mesos::slave':
    master    => $mesos_zk,
    resources => $mesos_resources,
    options   => {
      hostname                      => $hostname,
      advertise_ip                  => $address,
      containerizers                => 'docker,mesos',
      executor_registration_timeout => '5mins',
    },
  }

  if ! $controller_worker {
    class { 'seed_stack::consul_dns':
      consul_version     => $consul_version,
      server             => false,
      join               => $controller_addresses,
      advertise_addr     => $address,
      client_addr        => $consul_client_addr,
      domain             => $consul_domain,
      encrypt            => $consul_encrypt,
      ui                 => $consul_ui,
      dnsmasq_ensure     => $dnsmasq_ensure,
      dnsmasq_host_alias => $dnsmasq_host_alias,
    }
  }
  consul::service { 'mesos-slave':
    port   => 5051,
    checks => [
      {
        http     => "http://${mesos_listen_addr}:5051/slave(1)/health",
        interval => '10s',
        timeout  => '1s',
      },
    ],
  }

  class { 'seed_stack::template_nginx':
    nginx_package_ensure    => $nginx_ensure,
    consul_template_version => $consul_template_version,
    consul_address          => $consul_client_addr,
  }
  class { 'seed_stack::router':
    listen_addr => $nginx_router_listen_addr,
    domain      => $dnsmasq_host_alias,
  }

  # Docker, using the host for DNS
  class { 'docker':
    ensure => $docker_ensure,
    dns    => $address,
  }
}
