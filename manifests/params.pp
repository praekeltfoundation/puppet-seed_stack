# == Class: seed_stack::params
#
# PRIVATE CLASS: do not use directly
class seed_stack::params inherits seed_stack::globals {
  $advertise_addr           = $seed_stack::globals::advertise_addr
  $controller_addrs         = $seed_stack::globals::controller_addrs

  $docker_ensure            = $seed_stack::globals::docker_ensure

  $zookeeper_ensure         = $seed_stack::globals::zookeeper_ensure
  $zookeeper_client_addr    = $seed_stack::globals::zookeeper_client_addr

  $mesos_ensure             = $seed_stack::globals::mesos_ensure
  $mesos_listen_addr        = $seed_stack::globals::mesos_listen_addr
  $mesos_cluster            = $seed_stack::globals::mesos_cluster

  $marathon_ensure          = $seed_stack::globals::marathon_ensure

  $consul_version           = $seed_stack::globals::consul_version
  $consul_client_addr       = $seed_stack::globals::consul_client_addr
  $consul_domain            = $seed_stack::globals::consul_domain
  $consul_encrypt           = $seed_stack::globals::consul_encrypt

  $consular_ensure          = $seed_stack::globals::consular_ensure
  $consular_sync_interval   = $seed_stack::globals::consular_sync_interval

  $consul_template_version  = $seed_stack::globals::consul_template_version

  $nginx_ensure             = $seed_stack::globals::nginx_ensure
  $nginx_router_listen_addr = $seed_stack::globals::nginx_router_listen_addr
  $nginx_router_listen_port = $seed_stack::globals::nginx_router_listen_port
  $nginx_router_domain      = $seed_stack::globals::nginx_router_domain
}
