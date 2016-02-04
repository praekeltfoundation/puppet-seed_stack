# == Class: seed_stack::router
#
# Defines a dynamically-cofigured Nginx router for internal apps. Apps must
# define a 'location' Marathon label to be accessible through Nginx.
#
# === Parameters
#
# [*listen_address*]
#   The address that Nginx should listen on when serving requests.
#
# [*listen_port*]
#   The port that Nginx should listen on when serving requests.
#
# [*domain*]
#   The domain that Nginx should serve for routing.
class seed_stack::router (
  $listen_address = '0.0.0.0',
  $listen_port    = 80,
  $domain         = 'servicehost',
) {
  validate_ip_address($listen_address)
  validate_integer($listen_port, 65535, 0)

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
    require     => Service['nginx'],
  }
}
