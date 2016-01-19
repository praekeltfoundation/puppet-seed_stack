# == Class: seed_stack::params
#
class seed_stack::params {

  $docker_ensure            = '1.9.1*'

  $zookeeper_ensure         = 'present'
  $zookeeper_client_addr    = '0.0.0.0'

  $mesos_ensure             = '0.26.0*'
  $mesos_listen_addr        = '0.0.0.0'
  $mesos_cluster            = 'seed-stack'
  $mesos_resources          = {}

  $marathon_ensure          = '0.14.0*'
  $marathon_default_options = { # TODO
    'event_subscriber' => 'http_callback' # HTTP callbacks for Consular
  }

  $consul_version           = '0.6.1'
  $consul_client_addr       = '0.0.0.0'
  $consul_domain            = 'consul.'

  $consular_ensure          = '1.2.0*'
  $consular_sync_interval   = '300'

  $consul_template_version  = '0.12.1'
}
