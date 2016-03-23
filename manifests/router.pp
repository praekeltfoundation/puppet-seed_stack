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
#   Set to false to avoid managing the nginx package.
#
class seed_stack::router (
  $listen_addr  = $seed_stack::params::router_listen_addr,
  $listen_port  = $seed_stack::params::router_listen_port,
  $domain       = $seed_stack::params::router_domain,
  $nginx_manage = true,
) inherits seed_stack::params {
  validate_ip_address($listen_addr)
  validate_integer($listen_port, 65535, 1)
  validate_bool($nginx_manage)

  if $nginx_manage {
    package { $seed_stack::params::nginx_package:
      ensure => $seed_stack::params::nginx_ensure,
    }->
    service { 'nginx':
      ensure => 'running',
    }
  }

  include seed_stack::template_nginx

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
