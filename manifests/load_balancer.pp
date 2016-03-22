# == Class: seed_stack::load_balancer
#
# Defines a dynamically-cofigured Nginx load-balancer for external-facing apps.
# Apps must define a 'domain' Marathon label to be accessible through Nginx.
#
# === Parameters
#
# [*listen_addr*]
#   The address that seed_stack::router is listening on. This prevents the more
#   specific listen directive in that from masking our server blocks.
#
# [*nginx_manage*]
#   Whether or not to manage the nginx service and package at all
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
class seed_stack::load_balancer (
  $listen_addr             = $seed_stack::params::router_listen_addr,
  $nginx_manage            = $seed_stack::params::nginx_manage,
  $nginx_package           = $seed_stack::params::nginx_package,
  $nginx_package_ensure    = $seed_stack::params::nginx_ensure,
  $nginx_service_ensure    = $seed_stack::params::nginx_service_ensure,

  $consul_template_version = $seed_stack::params::consul_template_version,
  $consul_address          = $seed_stack::params::consul_client_addr,
) inherits seed_stack::params {
  validate_ip_address($listen_addr)

  class{ 'seed_stack::template_nginx':
    nginx_manage            => $nginx_manage,
    nginx_package           => $nginx_package,
    nginx_package_ensure    => $nginx_package_ensure,
    nginx_service_ensure    => $nginx_service_ensure,
    consul_template_version => $consul_template_version,
    consul_address          => $consul_address,
  }

  file { '/etc/consul-template/nginx-websites.ctmpl':
    content => template('seed_stack/nginx-websites.ctmpl.erb'),
  }
  ~>
  consul_template::watch { 'nginx-websites':
    source      => '/etc/consul-template/nginx-websites.ctmpl',
    destination => '/etc/nginx/sites-enabled/seed-websites.conf',
    command     => '/etc/init.d/nginx reload',
  }
}
