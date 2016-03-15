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
class seed_stack::load_balancer (
  $listen_addr = $seed_stack::params::router_listen_addr,
) inherits seed_stack::params {
  validate_ip_address($listen_addr)

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
