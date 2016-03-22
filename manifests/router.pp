# == Class: seed_stack::router
#
# Defines a dynamically-cofigured Nginx router for internal apps. Apps must
# define a 'location' Marathon label to be accessible through Nginx.
#
# === Parameters
#
# [*listen_addr*]
#   The address that Nginx should listen on when serving requests. NOTE: If you
#   are using an address and port that are available from the outside internet,
#   your services will be exposed via the router.
#
# [*listen_port*]
#   The port that Nginx should listen on when serving requests.
#
# [*domain*]
#   The domain that Nginx should serve for routing.
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
class seed_stack::router (
  $listen_addr             = $seed_stack::params::router_listen_addr,
  $listen_port             = $seed_stack::params::router_listen_port,
  $domain                  = $seed_stack::params::router_domain,
  $nginx_manage            = $seed_stack::params::nginx_manage,
  $nginx_package           = $seed_stack::params::nginx_package,
  $nginx_package_ensure    = $seed_stack::params::nginx_ensure,
  $nginx_service_ensure    = $seed_stack::params::nginx_service_ensure,

  $consul_template_version = $seed_stack::params::consul_template_version,
  $consul_address          = $seed_stack::params::consul_client_addr,
) inherits seed_stack::params {
  validate_ip_address($listen_addr)
  validate_integer($listen_port, 65535, 1)

  class{ 'seed_stack::template_nginx':
    nginx_manage            => $nginx_manage,
    nginx_package           => $nginx_package,
    nginx_package_ensure    => $nginx_package_ensure,
    nginx_service_ensure    => $nginx_service_ensure,
    consul_template_version => $consul_template_version,
    consul_address          => $consul_address,
  }

  # Configure Nginx to route to upstream services
  file { '/etc/consul-template/nginx-services.ctmpl':
    content => template('seed_stack/nginx-services.ctmpl.erb'),
  }
  ~>
  consul_template::watch { 'nginx-services':
    source      => '/etc/consul-template/nginx-services.ctmpl',
    destination => '/etc/nginx/sites-enabled/seed-services.conf',
    command     => '/etc/init.d/nginx reload',
  }
}
