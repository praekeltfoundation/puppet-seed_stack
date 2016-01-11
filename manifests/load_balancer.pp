# == Class: seed_stack::load_balancer
#
# Defines a dynamically-cofigured Nginx router/load-balancer for external-facing
# apps. Apps must define a 'domain' Marathon label to be accessible through
# nginx.
#
# === Parameters
#
# [*manage_nginx*]
#   Whether or not to install the nginx package and manage the service.
#
# [*nginx_service*]
#   When manage_nginx is false, the resource that should be notified for nginx
#   config changes should be provided here. When manage_nginx is true, this
#   parameter has no effect.
#
# [*manage_consul_template*]
#   Whether or not to install the consul_template package and manage the
#   service.
#
# [*consul_template_version*]
#   The version of Consul Template to install. If manage_consul_template is
#   false, this parameter has no effect.
#
# [*consul_address*]
#   The address for the Consul agent for Consul Template to connect to. If
#   manage_consul_template is false, this parameter has no effect.
#
# [*upstreams*]
#   Whether or not to add a Consul Template template for the nginx upstreams.
#   It may be necessary to set this false if the upstreams are already
#   templated - which could be the case if this is also a routing node.
class seed_stack::load_balancer (
  $manage_nginx            = true,
  $nginx_service           = undef,

  $manage_consul_template  = true,
  $consul_template_version = $seed_stack::params::consul_template_version,
  $consul_address          = '127.0.0.1',

  $upstreams               = true,
) inherits seed_stack::params {
  if $manage_nginx {
    package { 'nginx-light':
      ensure => installed,
    }~>
    service { 'nginx':
      ensure => running,
    }

    $nginx_srvc = Service['nginx']
  } else {
    $nginx_srvc = $nginx_service
  }

  if $manage_consul_template {
    if ! defined (Package['unzip']) {
      package { 'unzip':
        ensure => installed,
      }
    }

    class { 'consul_template':
      version      => $consul_template_version,
      config_dir   => '/etc/consul-template',
      user         => 'root',
      group        => 'root',
      consul_host  => $consul_address,
      consul_port  => 8500,
      consul_retry => '10s',
      # For some reason, consul-template doesn't like this option.
      # consul_max_stale => '10m',
      log_level    => 'warn',
      require      => Package['unzip']
    }
  }

  if $upstreams {
    # Configure Nginx to load-balance across uptream services
    file { '/etc/consul-template/nginx-upstreams.ctmpl':
      source => 'puppet:///modules/seed_stack/nginx-upstreams.ctmpl',
    }
    ~>
    consul_template::watch { 'nginx-upstreams':
      source      => '/etc/consul-template/nginx-upstreams.ctmpl',
      destination => '/etc/nginx/sites-enabled/seed-upstreams.conf',
      command     => '/etc/init.d/nginx reload',
      require     => $nginx_srvc,
    }
  }

  file { '/etc/consul-template/nginx-websites.ctmpl':
    source => 'puppet:///modules/seed_stack/nginx-websites.ctmpl',
  }
  ~>
  consul_template::watch { 'nginx-websites':
    source      => '/etc/consul-template/nginx-websites.ctmpl',
    destination => '/etc/nginx/sites-enabled/seed-websites.conf',
    command     => '/etc/init.d/nginx reload',
    require     => $nginx_srvc,
  }
}
