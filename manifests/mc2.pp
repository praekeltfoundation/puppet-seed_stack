# == Class: seed_stack::mc2
#
# Runs a Mission Control container in Marathon.
#
class seed_stack::mc2 {

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
    source => 'puppet:///modules/seed_stack/mc2.marathon.json',
  }

  $mc2_marathon_cmd = join([
    '/usr/local/bin/manage-marathon-group.sh',
    '/etc/marathon-apps/mc2.marathon.json',
    'marathon.service.consul',
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

  include seed_stack::template_nginx

  file { '/etc/consul-template/nginx-mc2.ctmpl':
    source => 'puppet:///modules/seed_stack/nginx-mc2.ctmpl',
  }
  ~>
  consul_template::watch { 'nginx-mc2':
    source      => '/etc/consul-template/nginx-mc2.ctmpl',
    destination => '/etc/nginx/sites-enabled/seed-mc2.conf',
    command     => '/etc/init.d/nginx reload',
    require     => Service['nginx'],
  }
}
