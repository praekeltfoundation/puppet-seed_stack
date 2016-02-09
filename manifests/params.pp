# == Class: seed_stack::params
#
class seed_stack::params {

  $docker_ensure            = '1.10.0*'

  $zookeeper_ensure         = 'installed'
  $zookeeper_client_addr    = '0.0.0.0'

  $mesos_ensure             = '0.27.0*'
  $mesos_listen_addr        = '0.0.0.0'
  $mesos_cluster            = 'seed-stack'
  $mesos_resources          = {}

  $marathon_ensure          = '0.15.1*'
  $marathon_default_options = { # TODO
    'event_subscriber' => 'http_callback' # HTTP callbacks for Consular
  }

  $consul_version           = '0.6.3'
  $consul_client_addr       = '0.0.0.0'
  $consul_domain            = 'consul.'

  $consular_ensure          = '1.2.0*'
  $consular_sync_interval   = '300'

  $consul_template_version  = '0.12.2'

  $nginx_ensure             = 'installed'
  $nginx_router_listen_addr = '0.0.0.0'
  $nginx_router_listen_port = 80
  $nginx_router_domain      = 'servicehost'
}
