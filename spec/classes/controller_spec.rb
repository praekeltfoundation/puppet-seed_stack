require 'spec_helper'

describe 'seed_stack::controller' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:concat_basedir => '/tmp/puppetconcat')
      end

      describe 'when controller_addrs and advertise_addr are passed' do
        let(:advertise_addr) { '192.168.0.2' }
        let(:controller_addrs) { ['192.168.0.2'] }
        let(:params) do
          {
            :controller_addrs => controller_addrs,
            :advertise_addr => advertise_addr,
          }
        end

        it { is_expected.to compile }

        it do
          is_expected.to contain_class('webupd8_oracle_java')
            .that_comes_before(
              [
                'Package[zookeeper]',
                'Package[mesos]',
                'Package[marathon]'
              ]
            )
        end

        it do
          is_expected.to contain_class('zookeeper')
            .with_ensure('installed')
            .with_id(1)
            .with_servers(['192.168.0.2'])
            .with_client_ip('0.0.0.0')
        end

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
          is_expected.to contain_class('mesos::master')
            .with_cluster('seed-stack')
            .with_syslog_logger(false)
            .with_single_role(true)
            .with_options(
              'hostname' => 'foo.example.com',
              'advertise_ip' => '192.168.0.2',
              'quorum' => 1
            )
        end

        it do
          is_expected.to contain_service('mesos-slave')
            .with_ensure('stopped')
            .with_enable(false)
            .that_subscribes_to('Package[mesos]')
        end

        it do
          is_expected.to contain_class('marathon')
            .with_package_ensure(/^\d+\.\d+\.\d+.+$/)
            .with_repo_manage(false)
            .with_zookeeper('zk://192.168.0.2:2181/marathon')
            .with_master('zk://192.168.0.2:2181/mesos')
            .with_syslog(false)
            .with_options(
              'hostname' => 'foo.example.com',
              'event_subscriber' => 'http_callback'
            )
        end

        it do
          is_expected.to contain_class('mesos::repo')
            .that_comes_before('Package[marathon]')
        end

        it do
          is_expected.to contain_class('seed_stack::consul_dns')
            .with_consul_version(/\d+\.\d+\.\d+/)
            .with(
              'server' => true,
              'join' => [],
              'bootstrap_expect' => 1,
              'advertise_addr' => '192.168.0.2',
              'client_addr' => '0.0.0.0',
              'domain' => 'consul.',
              'encrypt' => nil,
              'ui' => true,
              'dnsmasq_ensure' => 'installed',
              'dnsmasq_host_alias' => 'servicehost'
            )
        end

        it do
          is_expected.to contain_consul__service('marathon')
            .with_port(8080)
            .with_checks(
              puppet3_hashlist_to_a(
                [{
                  'http' => 'http://127.0.0.1:8080/ping',
                  'interval' => '10s',
                  'timeout' => '1s'
                }]
              )
            )
        end

        it do
          is_expected.to contain_consul__service('mesos-master')
            .with_port(5050)
            .with_checks(
              puppet3_hashlist_to_a(
                [{
                  'http' => 'http://0.0.0.0:5050/master/health',
                  'interval' => '10s',
                  'timeout' => '1s'
                }]
              )
            )
        end

        it do
          is_expected.to contain_consul__service('zookeeper')
            .with_port(2181)
            .with_checks(
              puppet3_hashlist_to_a(
                [{
                  'script' => 'echo "srvr" | nc 0.0.0.0 2181',
                  'interval' => '30s'
                }]
              )
            )
        end
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

      describe 'when controller_worker is true' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.2',
            :controller_worker => true,
          }
        end
        it do
          is_expected.to contain_class('mesos::master')
            .with_single_role(false)
        end
        it { is_expected.not_to contain_service('mesos-slave') }
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
        else
          it { is_expected.to contain_package('mesos').without_install_options }
        end
      end
    end
  end
end
