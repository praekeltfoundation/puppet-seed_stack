# == Class: seed_stack::worker
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
# [*controller*]
#   Whether or not this worker node is also a controller.
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
# [*consul_template_version*]
#   The version of Consul Template to install.
#
# [*docker_ensure*]
#   The package ensure value for Docker Engine.
class seed_stack::worker (
  # Common
  $controller_addresses    = [$::ipaddress_lo],
  $address                 = $::ipaddress_lo,
  $hostname                = $::hostname,
  $controller              = false,

  # Mesos
  $mesos_ensure            = $seed_stack::params::mesos_ensure,
  $mesos_listen_addr       = $seed_stack::params::mesos_listen_addr,
  $mesos_resources         = $seed_stack::params::mesos_resources,

  # Consul
  $consul_version          = $seed_stack::params::consul_version,
  $consul_client_addr      = $seed_stack::params::consul_client_addr,
  $consul_domain           = $seed_stack::params::consul_domain,
  $consul_encrypt          = undef,
  $consul_ui               = false,

  # Consul Template
  $consul_template_version = $seed_stack::params::consul_template_version,

  # Docker
  $docker_ensure           = $seed_stack::params::docker_ensure,
) inherits seed_stack::params {

  # Basic parameter validation
  validate_ip_address($address)
  validate_bool($controller)
  validate_ip_address($mesos_listen_addr)
  validate_hash($mesos_resources)
  validate_ip_address($consul_client_addr)
  validate_bool($consul_ui)

  $mesos_zk = inline_template('zk://<%= @controller_addresses.map { |c| "#{c}:2181"}.join(",") %>/mesos')
  if ! $controller {
    class { 'mesos':
      ensure         => $mesos_ensure,
      repo           => 'mesosphere',
      listen_address => $mesos_listen_addr,
      zookeeper      => $mesos_zk,
    }

    # We need this because mesos::install doesn't wait for apt::update before
    # trying to install the package.
    Class['apt::update'] -> Package['mesos']
  }

  class { 'mesos::slave':
    master    => $mesos_zk,
    resources => $mesos_resources,
    options   => {
      hostname                      => $hostname,
      containerizers                => 'docker,mesos',
      executor_registration_timeout => '5mins',
    },
  }

  if ! $controller {
    # Consul requires unzip to install
    package { 'unzip':
      ensure => installed,
    }

    class { 'consul':
      version     => $consul_version,
      config_hash => {
        'bootstrap_expect' => size($controller_addresses),
        'retry_join'       => $controller_addresses,
        'server'           => false,
        'data_dir'         => '/var/consul',
        'log_level'        => 'INFO',
        'advertise_addr'   => $address,
        'client_addr'      => $consul_client_addr,
        'domain'           => $consul_domain,
        'encrypt'          => $consul_encrypt,
        'ui'               => $consul_ui,
      },
      services    => {
        'mesos-slave' => {
          port => 5051
        },
      },
      require     => Package['unzip'],
    }
  }

  package { 'nginx-light': }
  ~>
  service { 'nginx': }

  # Consul Template to dynamically configure Nginx
  class { 'consul_template':
    version      => $consul_template_version,
    config_dir   => '/etc/consul-template',
    user         => 'root',
    group        => 'root',
    consul_host  => $address,
    consul_port  => 8500,
    consul_retry => '10s',
    # For some reason, consul-template doesn't like this option.
    # consul_max_stale => '10m',
    log_level    => 'warn',
    require      => Package['unzip']
  }

  # Configure Nginx to load-balance across uptream services
  file { '/etc/consul-template/nginx-upstreams.ctmpl':
    source => 'puppet:///modules/seed_stack/nginx-upstreams.ctmpl',
  }
  ~>
  consul_template::watch { 'nginx-upstreams':
    source      => '/etc/consul-template/nginx-upstreams.ctmpl',
    destination => '/etc/nginx/sites-enabled/seed-upstreams.conf',
    command     => '/etc/init.d/nginx reload',
    require     => Service['nginx'],
  }

  # Configure Nginx to route to upstream services
  file { '/etc/consul-template/nginx-services.ctmpl':
    source => 'puppet:///modules/seed_stack/nginx-services.ctmpl',
  }
  ~>
  consul_template::watch { 'nginx-services':
    source      => '/etc/consul-template/nginx-services.ctmpl',
    destination => '/etc/nginx/sites-enabled/seed-services.conf',
    command     => '/etc/init.d/nginx reload',
    require     => Service['nginx'],
  }

  # dnsmasq to serve DNS requests, sending requests for the Consul domain to
  # Consul
  if ! controller {
    $dnsmasq_server = inline_template('<%= @consul_domain.chop() %>') # Remove trailing '.'
    package { 'dnsmasq': }
    ~>
    file { '/etc/dnsmasq.d/consul':
      content => "cache-size=0\nserver=/${dnsmasq_server}/${address}#8600",
    }
    ~>
    service { 'dnsmasq': }
  }

  # Docker, using the host for DNS
  class { 'docker':
    ensure => $docker_ensure,
    dns    => $::ipaddress_docker0,
  }
}
