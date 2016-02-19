# == Class: seed_stack::xylem
#
# === Parameters
#
class seed_stack::xylem (
  $gluster_hosts,
  $gluster_mounts,
  $gluster_replica = undef,
  $gluster_stripe  = undef,
) inherits seed_stack::params {

  include gluster

  gluster_peer { $gluster_hosts: }

  class { 'xylem::node':
    gluster         => true,
    gluster_mounts  => $gluster_mounts,
    gluster_nodes   => $gluster_hosts,
    gluster_replica => $gluster_replica,
    gluster_stripe  => $gluster_stripe,
    repo_manage     => !defined(Class['xylem::repo']),
  }
}
