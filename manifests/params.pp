# == Class: seed_stack::params
#
# This class doesn't *do* anything- it just holds parameters. This is not an
# exhaustive list of parameters but it includes those that should generally be
# consistent across the cluster.
#
# === Parameters
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
# [*consul_template_version*]
#   The version of Consul Template to install.
#
# [*nginx_ensure*]
#   The package ensure value for Nginx.
#
# [*router_listen_addr*]
#   The address that Nginx should listen on when serving routing requests.
#
# [*router_listen_port*]
#   The port that Nginx should listen on when serving routing requests.
#
# [*router_domain*]
#   The domain that Nginx should serve for routing.
#
# [*dnsmasq_ensure*]
#   The ensure value for the Dnsmasq package.
#
class seed_stack::params {
  $docker_ensure            = '1.11.0-0~trusty'

  $zookeeper_ensure         = 'installed'
  $zookeeper_client_addr    = '0.0.0.0'

  $mesos_ensure             = '0.28.1-2.0.20.ubuntu1404'
  $mesos_listen_addr        = '0.0.0.0'
  $mesos_cluster            = 'seed-stack'

  $marathon_ensure          = '1.1.1-1.0.472.ubuntu1404'

  $consul_version           = '0.6.4'
  $consul_client_addr       = '0.0.0.0'
  $consul_domain            = 'consul.'

  $consul_template_version  = '0.14.0'

  $nginx_ensure             = 'installed'
  $nginx_package            = 'nginx-light'

  $router_listen_addr       = $::ipaddress_lo
  $router_listen_port       = 80
  $router_domain            = 'servicehost'

  $dnsmasq_ensure           = 'installed'
}
