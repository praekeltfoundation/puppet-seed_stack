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

        it { is_expected.to contain_class('seed_stack::worker') }

        it { is_expected.to contain_class('mesos') }

        it do
          is_expected.to contain_service('mesos-master')
            .with_ensure('stopped')
        end

        it do
          is_expected.to contain_class('mesos::slave')
            .with_master('zk://192.168.0.2:2181/mesos')
            .with_resources({})
            .with_syslog_logger(false)
            .with_options(
              'hostname' => 'foo.example.com',
              'advertise_ip' => '192.168.0.3',
              'containerizers' => 'docker,mesos',
              'executor_registration_timeout' => '5mins'
            )
        end

        it do
          is_expected.to contain_class('seed_stack::consul_dns')
            .with_join(['192.168.0.2'])
            .with_advertise_addr('192.168.0.3')
        end

        it { is_expected.to contain_consul__service('mesos-slave') }

        it { is_expected.to contain_class('seed_stack::template_nginx') }

        it do
          is_expected.to contain_class('seed_stack::router')
            .with_listen_addr('192.168.0.3')
            .with_domain('servicehost')
        end

        it { is_expected.to contain_class('docker') }

        it { is_expected.not_to contain_class('xylem::docker') }

        it { is_expected.not_to contain_class('gluster') }

        it { is_expected.not_to contain_class('gluster::client') }
      end

      describe 'when xylem_backend is passed' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.2',
            :xylem_backend => 'gfs1.local',
          }
        end

        it { is_expected.to compile }

        it { is_expected.to contain_class('seed_stack::worker') }

        it { is_expected.to contain_class('mesos') }

        it do
          is_expected.to contain_service('mesos-master')
            .with_ensure('stopped')
        end

        it { is_expected.to contain_class('mesos::slave') }

        it do
          is_expected.to contain_class('seed_stack::consul_dns')
            .with_join(['192.168.0.2'])
            .with_advertise_addr('192.168.0.2')
        end

        it { is_expected.to contain_consul__service('mesos-slave') }

        it { is_expected.to contain_class('seed_stack::template_nginx') }

        it { is_expected.to contain_class('seed_stack::router') }

        it { is_expected.to contain_class('docker') }

        it do
          is_expected.to contain_class('xylem::docker')
            .with_backend('gfs1.local')
            .with_repo_manage(true)
            .that_requires('Class[docker]')
        end

        it { is_expected.not_to contain_class('gluster') }

        it { is_expected.to contain_class('gluster::client') }
      end

      describe 'when gluster_client_manage is false' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.2',
            :xylem_backend => 'gfs1.local',
            :gluster_client_manage => false,
          }
        end

        it { is_expected.to compile }

        it { is_expected.to contain_class('seed_stack::worker') }

        it { is_expected.to contain_class('mesos') }

        it do
          is_expected.to contain_service('mesos-master')
            .with_ensure('stopped')
        end

        it { is_expected.to contain_class('mesos::slave') }

        it do
          is_expected.to contain_class('seed_stack::consul_dns')
            .with_join(['192.168.0.2'])
            .with_advertise_addr('192.168.0.2')
        end

        it { is_expected.to contain_consul__service('mesos-slave') }

        it { is_expected.to contain_class('seed_stack::template_nginx') }

        it { is_expected.to contain_class('seed_stack::router') }

        it { is_expected.to contain_class('docker') }

        it do
          is_expected.to contain_class('xylem::docker')
            .with_backend('gfs1.local')
            .with_repo_manage(true)
            .that_requires('Class[docker]')
        end

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
