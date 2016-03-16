# == Class: seed_stack::mc2
#
# Runs a Mission Control container in Marathon.
#
class seed_stack::mc2(
  $infr_domain,
  $hub_domain,
  $marathon_host = 'marathon.service.consul',
) {

  unless defined(Package['curl']) {
    package { 'curl': ensure => 'installed' }
  }

  file { '/usr/local/bin/manage-marathon-group.sh':
    source  => 'puppet:///modules/seed_stack/manage-marathon-group.sh',
    mode    => '0755',
    require => Package['curl'],
  }

  file { '/etc/marathon-apps': ensure => 'directory' }
  ->
  file { '/etc/marathon-apps/mc2.marathon.json':
    content => template('seed_stack/mc2.marathon.json.erb'),
  }

  $mc2_marathon_cmd = join([
    '/usr/local/bin/manage-marathon-group.sh',
    '/etc/marathon-apps/mc2.marathon.json',
    $marathon_host,
  ], ' ')

  # This is unconditional because Marathon does nothing when the group
  # definition is unchanged.
  exec { 'mc2 marathon app':
    command => $mc2_marathon_cmd,
    require => [
      File['/usr/local/bin/manage-marathon-group.sh'],
      File['/etc/marathon-apps/mc2.marathon.json'],
    ],
  }
}
