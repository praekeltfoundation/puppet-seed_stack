# == Class: seed_stack::mc2
#
# Runs a Mission Control container in Marathon.
#
class seed_stack::mc2(
  $infr_domain,
  $hub_domain,
  $marathon_host = 'http://marathon.service.consul:8080',
) {
  file { '/etc/marathon-apps': ensure => 'directory' }
  ->
  file { '/etc/marathon-apps/mc2.marathon.json':
    content => template('seed_stack/mc2.marathon.json.erb'),
  }

  class { 'xylem::config::marathon_sync':
    group_json_files => ['/etc/marathon-apps/mc2.marathon.json'],
  }
}
