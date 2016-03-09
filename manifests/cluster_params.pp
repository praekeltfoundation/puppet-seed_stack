# == Class: seed_stack
#
# Cluster-wide parameters for configuring seed_stack nodes. This class doesn't
# *do* anything- it just holds parameters. This is not an exhaustive list of
# parameters but it includes those that should generally be consistent across
# the cluster.
#
# === Parameters
#
# [*advertise_addr*]
#   The advertise IP address for the node. All services will be exposed on this
#   address.
#
# [*controller_addrs*]
#   A list of IP addresses for all controllers in the cluster (i.e. a list of
#   each controller's advertise_addr). NOTE: This list must be identical (same
#   elements, same order) for ALL controller nodes.
#
# [*docker_ensure*]
#   The package ensure value for Docker Engine.
#
# [*zookeeper_ensure*]
#   The package ensure value for zookeeper.
#
# [*zookeeper_client_addr*]
#   The address that Zookeeper will listen for clients on.
#
# [*mesos_ensure*]
#   The package ensure value for Mesos.
#
# [*mesos_listen_addr*]
#   The address that Mesos will listen on.
#
# [*mesos_cluster*]
#   The Mesos cluster name.
#
# [*marathon_ensure*]
#   The package ensure value for Marathon.
#
# [*consul_version*]
#   The version of Consul to install.
#
# [*consul_client_addr*]
#   The address to which Consul will bind client interfaces, including the HTTP,
#   DNS, and RPC servers.
#
# [*consul_domain*]
#   The domain to be served by Consul DNS.
#
# [*consul_encrypt*]
#   The secret key to use for encryption of Consul network traffic.
#
# [*consular_ensure*]
#   The package ensure value for Consular.
#
# [*consular_sync_interval*]
#   The interval in seconds between Consular syncs.
#
# [*consul_template_version*]
#   The version of Consul Template to install.
#
# [*nginx_ensure*]
#   The package ensure value for Nginx.
#
# [*nginx_router_listen_addr*]
#   The address that Nginx should listen on when serving routing requests.
#
# [*nginx_router_listen_port*]
#   The port that Nginx should listen on when serving routing requests.
#
# [*nginx_router_domain*]
#   The domain that Nginx should serve for routing.
class seed_stack::cluster_params(
  $advertise_addr           = undef,
  $controller_addrs         = undef,

  $docker_ensure            = '1.10.2-0~trusty',

  $zookeeper_ensure         = 'installed',
  $zookeeper_client_addr    = '0.0.0.0',

  $mesos_ensure             = '0.27.1-2.0.226.ubuntu1404',
  $mesos_listen_addr        = '0.0.0.0',
  $mesos_cluster            = 'seed-stack',

  $marathon_ensure          = '0.15.3-1.0.463.ubuntu1404',

  $consul_version           = '0.6.3',
  $consul_client_addr       = '0.0.0.0',
  $consul_domain            = 'consul.',
  $consul_encrypt           = undef,

  $consular_ensure          = '1.2.0*',
  $consular_sync_interval   = '300',

  $consul_template_version  = '0.14.0',

  $nginx_ensure             = 'installed',
  $nginx_router_listen_addr = '0.0.0.0',
  $nginx_router_listen_port = 80,
  $nginx_router_domain      = 'servicehost',
) {

}
