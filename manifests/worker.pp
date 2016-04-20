# == Class: seed_stack::worker
#
# === Parameters
#
# [*advertise_addr*]
#   The advertise IP address for the node. All services will be exposed on this
#   address.
#
# [*controller_addrs*]
#   A list of IP addresses for all controllers in the cluster (i.e. a list of
#   each controller's advertise_addr).
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
# [*nginx_manage*]
#   Set to false to avoid managing the nginx package.
#
# [*docker_ensure*]
#   The package ensure value for Docker Engine.
#
# [*docker_extra_parameters*]
#   Extra parameters to pass to the docker daemon.
#
# [*xylem_backend*]
#   Backend host for Xylem Docker plugin. If given, the Xylem Docker volume
#   plugin will be installed and managed.
#
# [*gluster_client_manage*]
#   Set to false to avoid installing the Glusterfs client when xylem_backend is
#   set. (Do this when seed_stack::xylem is included in the same node to avoid
#   repo management conflicts.)
#
class seed_stack::worker (
  # Common
  $advertise_addr,
  $controller_addrs,
  $hostname                 = $::fqdn,
  $controller_worker        = false,

  # Mesos
  $mesos_ensure             = $seed_stack::params::mesos_ensure,
  $mesos_listen_addr        = $seed_stack::params::mesos_listen_addr,
  $mesos_resources          = {},

  # Consul
  $consul_version           = $seed_stack::params::consul_version,
  $consul_client_addr       = $seed_stack::params::consul_client_addr,
  $consul_domain            = $seed_stack::params::consul_domain,
  $consul_encrypt           = undef,
  $consul_ui                = false,

  # Dnsmasq
  $dnsmasq_ensure           = $seed_stack::params::dnsmasq_ensure,
  $dnsmasq_host_alias       = $seed_stack::params::router_domain,

  # Consul Template
  $consul_template_version  = $seed_stack::params::consul_template_version,

  # Nginx
  $nginx_manage             = true,

  # Docker
  $docker_ensure            = $seed_stack::params::docker_ensure,
  $docker_extra_parameters  = undef,

  # Xylem
  $xylem_backend            = undef,
  $gluster_client_manage    = true,
) inherits seed_stack::params {
  validate_ip_address($advertise_addr)
  validate_array($controller_addrs)
  validate_bool($controller_worker)
  validate_ip_address($mesos_listen_addr)
  validate_hash($mesos_resources)
  validate_ip_address($consul_client_addr)
  validate_bool($consul_ui)
  validate_bool($gluster_client_manage)

  $mesos_zk = zookeeper_servers_url($controller_addrs)
  if ! $controller_worker {
    class { 'mesos':
      ensure         => $mesos_ensure,
      repo           => 'mesosphere',
      listen_address => $mesos_listen_addr,
      zookeeper      => $mesos_zk,
    }

    if versioncmp($::puppetversion, '3.6.0') >= 0 {
      Package <| title == 'mesos' |> {
        # Skip installing the recommended Mesos packages as they are just
        # Zookeeper packages that we don't need.
        install_options => ['--no-install-recommends'],
      }
    } else {
      # We can't *not* install Zookeeper but we can stop it from running.
      service { 'zookeeper':
        ensure  => stopped,
        enable  => false,
        require => Package['mesos'],
      }
    }
  }

  # Need to ensure port 4000 is available for marathon-consul
  $base_port_range = has_key($mesos_resources, 'ports(*)') ? {
    true  => regsubst($mesos_resources['ports(*)'], '[\[\]]', '', 'G'),
    false => '31000-32000', # Mesos default
  }
  $real_port_range = empty($base_port_range) ? {
    false => join([$base_port_range, '4000-4000'], ','),
    true  => '4000-4000',
  }
  $real_resources = merge($mesos_resources, {
    'ports(*)' => "[${real_port_range}]"
  })
  class { 'mesos::slave':
    master        => $mesos_zk,
    resources     => $real_resources,
    syslog_logger => false,
    single_role   => !$controller_worker,
    options       => {
      hostname                      => $hostname,
      advertise_ip                  => $advertise_addr,
      containerizers                => 'docker,mesos',
      executor_registration_timeout => '5mins',
    },
  }

  if ! $controller_worker {
    class { 'seed_stack::consul_dns':
      consul_version     => $consul_version,
      server             => false,
      join               => $controller_addrs,
      advertise_addr     => $advertise_addr,
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
    consul_template_version => $consul_template_version,
    consul_address          => $consul_client_addr,
  }
  class { 'seed_stack::router':
    listen_addr  => $advertise_addr,
    domain       => $dnsmasq_host_alias,
    nginx_manage => $nginx_manage,
  }

  # Docker, using the host for DNS
  class { 'docker':
    ensure           => $docker_ensure,
    dns              => $advertise_addr,
    extra_parameters => $docker_extra_parameters,
  }

  if $xylem_backend {
    if $gluster_client_manage {
      include gluster::client
    }

    class { 'xylem::docker':
      backend     => $xylem_backend,
      repo_manage => !defined(Class['xylem::repo']),
      require     => Class['docker'],
    }
  }

  # If mesos-slave starts too early, it crashes on startup fast enough that it
  # hits upstart's respawn limit in two or three seconds.
  Service['docker'] -> Service['mesos-slave']
}
