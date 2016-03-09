# == Class: seed_stack::template_nginx
#
# Installs Nginx and Consul Template as well as a Consul Template template for
# configuring Nginx load-balancing across upstream services.
#
# === Parameters
#
# [*nginx_package*]
#   The name of the Nginx package to install.
#
# [*nginx_package_ensure*]
#   The ensure value for the Nginx package.
#
# [*nginx_service_ensure*]
#   The ensure value for the Nginx service.
#
# [*consul_template_version*]
#   The version of Consul Template to install.
#
# [*consul_address*]
#   The address for the Consul agent for Consul Template to connect to.
class seed_stack::template_nginx (
  $nginx_package           = 'nginx-light',
  $nginx_package_ensure    = $seed_stack::params::nginx_ensure,
  $nginx_service_ensure    = 'running',

  $consul_template_version = $seed_stack::params::consul_template_version,
  $consul_address          = $seed_stack::params::consul_client_addr,
) inherits seed_stack::params {
  validate_ip_address($consul_address)

  package { $nginx_package:
    ensure => $nginx_package_ensure,
  }->
  service { 'nginx':
    ensure => $nginx_service_ensure,
  }

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
  }
  # FIXME: See gdhbashton/puppet-consul_template#61
  Package['unzip'] -> Class['consul_template::install']

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
}
