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
#   Set to false to avoid managing the nginx package.
#
class seed_stack::load_balancer (
  $listen_addr  = $seed_stack::params::router_listen_addr,
  $nginx_manage = true,
) inherits seed_stack::params {
  validate_ip_address($listen_addr)
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
