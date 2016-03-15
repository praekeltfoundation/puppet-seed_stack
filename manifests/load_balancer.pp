# == Class: seed_stack::load_balancer
#
# Defines a dynamically-cofigured Nginx load-balancer for external-facing apps.
# Apps must define a 'domain' Marathon label to be accessible through Nginx.
class seed_stack::load_balancer {
  include seed_stack::template_nginx

  file { '/etc/consul-template/nginx-websites.ctmpl':
    source => 'puppet:///modules/seed_stack/nginx-websites.ctmpl',
  }
  ~>
  consul_template::watch { 'nginx-websites':
    source      => '/etc/consul-template/nginx-websites.ctmpl',
    destination => '/etc/nginx/sites-enabled/seed-websites.conf',
    command     => '/etc/init.d/nginx reload',
  }
}
