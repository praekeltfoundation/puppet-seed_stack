# == Class: seed_stack::xylem
#
# === Parameters
#
class seed_stack::xylem (
  $gluster_hosts,
  $gluster_mounts,
  $gluster_replica = undef,
  $gluster_stripe  = undef,
  $redis_host      = '127.0.0.1',
) inherits seed_stack::params {

  include gluster

  gluster_peer { $gluster_hosts: }

  class { 'xylem::node':
    redis_host      => $redis_host,
    gluster         => true,
    gluster_mounts  => $gluster_mounts,
    gluster_nodes   => $gluster_hosts,
    gluster_replica => $gluster_replica,
    gluster_stripe  => $gluster_stripe,
    repo_manage     => !defined(Class['xylem::repo']),
  }
}
