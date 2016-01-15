# == Class: seed_stack::router
#
# Defines a dynamically-cofigured Nginx router for internal apps. Apps must
# define a 'location' Marathon label to be accessible through Nginx.
class seed_stack::router {
  include seed_stack::template_nginx

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
}
