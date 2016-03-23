require 'spec_helper'

describe 'seed_stack::worker' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:concat_basedir => '/tmp/puppetconcat')
      end

      describe 'when controller_addrs and advertise_addr are passed' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.3',
          }
        end

        it { is_expected.to compile }

        it do
          is_expected.to contain_class('mesos')
            .with_ensure(/^\d+\.\d+\.\d+.+$/)
            .with_repo('mesosphere')
            .with_listen_address('0.0.0.0')
            .with_zookeeper('zk://192.168.0.2:2181/mesos')
        end

        # Verify behaviour of zookeeper parameter in deric/mesos - a bunch of
        # changes around this in version 0.8.0 of the module
        it do
          is_expected.to contain_file('/etc/mesos/zk')
            .with_ensure('present')
            .with_content('zk://192.168.0.2:2181/mesos')
        end

        it do
          is_expected.to contain_service('mesos-master')
            .with_ensure('stopped')
            .with_enable(false)
            .that_subscribes_to('Package[mesos]')
        end

        it do
          is_expected.to contain_class('mesos::slave')
            .with_master('zk://192.168.0.2:2181/mesos')
            .with_resources({})
            .with_syslog_logger(false)
            .with_single_role(true)
            .with_options(
              'hostname' => 'foo.example.com',
              'advertise_ip' => '192.168.0.3',
              'containerizers' => 'docker,mesos',
              'executor_registration_timeout' => '5mins'
            )
        end

        it do
          is_expected.to contain_class('seed_stack::consul_dns')
            .with_consul_version(/\d+\.\d+\.\d+/)
            .with(
              'server' => false,
              'join' => ['192.168.0.2'],
              'advertise_addr' => '192.168.0.3',
              'client_addr' => '0.0.0.0',
              'domain' => 'consul.',
              'encrypt' => nil,
              'ui' => false,
              'dnsmasq_ensure' => 'installed',
              'dnsmasq_host_alias' => 'servicehost'
            )
        end

        it do
          is_expected.to contain_consul__service('mesos-slave')
            .with_port(5051)
            .with_checks(
              puppet3_hashlist_to_a(
                [{
                  'http' => 'http://0.0.0.0:5051/slave(1)/health',
                  'interval' => '10s',
                  'timeout' => '1s'
                }]
              )
            )
        end

        it do
          is_expected.to contain_class('seed_stack::template_nginx')
            .with_consul_template_version(/\d+\.\d+\.\d+/)
            .with_consul_address('0.0.0.0')
        end

        it do
          is_expected.to contain_class('seed_stack::router')
            .with_listen_addr('192.168.0.3')
            .with_domain('servicehost')
            .with_nginx_manage(true)
        end

        it do
          is_expected.to contain_class('docker')
            .with_ensure(/^\d+\.\d+\.\d+.+$/)
            .with_dns('192.168.0.3')
        end

        it { is_expected.not_to contain_class('xylem::docker') }
        it { is_expected.not_to contain_class('gluster') }
        it { is_expected.not_to contain_class('gluster::client') }
      end

      describe 'when controller_addrs is not passed' do
        let(:params) { {:advertise_addr => '192.168.0.2'} }
        it do
          is_expected.to compile.and_raise_error(mustpass('controller_addrs'))
        end
      end

      describe 'when advertise_addr is not passed' do
        let(:params) { {:controller_addrs => ['192.168.0.2']} }
        it do
          is_expected.to compile.and_raise_error(mustpass('advertise_addr'))
        end
      end

      describe 'when xylem_backend is passed' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.2',
            :xylem_backend => 'gfs1.local',
          }
        end

        it { is_expected.to contain_class('gluster::client') }

        it do
          is_expected.to contain_class('xylem::docker')
            .with_backend('gfs1.local')
            .with_repo_manage(true)
            .that_requires('Class[docker]')
        end

        it { is_expected.not_to contain_class('gluster') }
      end

      describe 'when controller_worker is true' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.3',
            :controller_worker => true,
          }
        end

        it do
          is_expected.to contain_class('mesos::slave')
            .with_single_role(false)
        end

        # Class['mesos'] will still be present because Class['mesos::slave']
        # inherits from it.
        # it { is_expected.not_to contain_class('mesos') }
        it { is_expected.not_to contain_service('zookeeper') }
        it { is_expected.not_to contain_service('mesos-master') }
        it { is_expected.not_to contain_class('seed_stack::consul_dns') }
      end

      context 'Mesos package --no-install-recommends' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.2',
          }
        end
        if Gem::Version.new(Puppet.version) >= Gem::Version.new('3.6.0')
          it do
            is_expected.to contain_package('mesos')
              .with_install_options(['--no-install-recommends'])
          end

          it do
            is_expected.not_to contain_service('zookeeper')
          end
        else
          it { is_expected.to contain_package('mesos').without_install_options }

          it do
            is_expected.to contain_service('zookeeper')
              .with_ensure('stopped')
              .with_enable(false)
              .that_requires('Package[mesos]')
          end
        end
      end
    end
  end
end
