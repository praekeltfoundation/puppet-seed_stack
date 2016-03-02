require 'spec_helper'

describe 'seed_stack::consul_dns' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile }

      describe 'with default parameters' do
        it do
          is_expected.to contain_class('consul')
            .with_version(/\d\.\d\.\d/)
            .with_config_hash(
              'server' => false,
              'data_dir' => '/var/lib/consul',
              'log_level' => 'INFO',
              'advertise_addr' => '127.0.0.1',
              'client_addr' => '0.0.0.0',
              'domain' => 'consul.',
              'encrypt' => :undef,
              'ui' => true,
              'retry_join' => ['127.0.0.1'],
              'recursors' => ['127.0.0.1']
            ).that_requires('Package[unzip]')
        end

        it { is_expected.to contain_package('unzip').with_ensure('installed') }

        it do
          is_expected.to contain_package('dnsmasq').with_ensure('installed')
        end
        it do
          is_expected.to contain_file('/etc/dnsmasq.d/consul')
            .with_content(/^cache-size=0$/)
            .with_content(/^server=\/consul\.\/127\.0\.0\.1#8600$/)
            .with_content(/^host-record=servicehost,127\.0\.0\.1$/)
            .that_requires('Package[dnsmasq]')
        end
        it do
          is_expected.to contain_service('dnsmasq')
            .that_subscribes_to('File[/etc/dnsmasq.d/consul]')
        end
      end

      context 'when server is true' do
        describe 'when bootstrap_expect is unset' do
          let(:params) do
            {
              :server => true,
              :bootstrap_expect => :undef
            }
          end
          it do
            is_expected.to contain_class('consul')
              .with_config_hash(
                'server' => true,
                'data_dir' => '/var/lib/consul',
                'log_level' => 'INFO',
                'advertise_addr' => '127.0.0.1',
                'client_addr' => '0.0.0.0',
                'domain' => 'consul.',
                'encrypt' => :undef,
                'ui' => true,
                'retry_join' => ['127.0.0.1'],
                'recursors' => ['127.0.0.1'],
                # This is ok - the resulting JSON doesn't contain this key
                'bootstrap_expect' => :undef
              )
          end
        end

        describe 'when bootstrap_expect is 1' do
          let(:params) do
            {
              :server => true,
              :bootstrap_expect => 1
            }
          end
          it do
            is_expected.to contain_class('consul')
              .with_config_hash(
                'server' => true,
                'data_dir' => '/var/lib/consul',
                'log_level' => 'INFO',
                'advertise_addr' => '127.0.0.1',
                'client_addr' => '0.0.0.0',
                'domain' => 'consul.',
                'encrypt' => :undef,
                'ui' => true,
                'retry_join' => ['127.0.0.1'],
                'recursors' => ['127.0.0.1'],
                'bootstrap_expect' => 1
              )
          end
        end

        describe 'when bootstrap_expect is 0' do
          let(:params) do
            {
              :server => true,
              :bootstrap_expect => 0
            }
          end
          it do
            is_expected.to raise_error(/Expected 0 to be greater or equal to 1/)
          end
        end
      end

      context 'when server is false' do
        describe 'when bootstrap_expect is set' do
          let(:params) do
            {
              :server => false,
              :bootstrap_expect => -42
            }
          end
          it do
            is_expected.to raise_error(
              /"bootstrap_expect" is an invalid parameter/)
          end
        end
      end

      describe 'when domain is set to seed-stack' do
        let(:params) { {:domain => 'seed-stack.'} }
        it do
          is_expected.to contain_class('consul')
            .with_config_hash(
              'server' => false,
              'data_dir' => '/var/lib/consul',
              'log_level' => 'INFO',
              'advertise_addr' => '127.0.0.1',
              'client_addr' => '0.0.0.0',
              'domain' => 'seed-stack.',
              'encrypt' => :undef,
              'ui' => true,
              'retry_join' => ['127.0.0.1'],
              'recursors' => ['127.0.0.1']
            )
        end
        it do
          is_expected.to contain_file('/etc/dnsmasq.d/consul')
            .with_content(/^server=\/seed-stack\.\/127\.0\.0\.1#8600$/)
        end
      end

      describe 'when client_addr is set to 192.168.0.2' do
        let(:params) { {:client_addr => '192.168.0.2'} }
        it do
          is_expected.to contain_class('consul')
            .with_config_hash(
              'server' => false,
              'data_dir' => '/var/lib/consul',
              'log_level' => 'INFO',
              'advertise_addr' => '127.0.0.1',
              'client_addr' => '192.168.0.2',
              'domain' => 'consul.',
              'encrypt' => :undef,
              'ui' => true,
              'retry_join' => ['127.0.0.1'],
              'recursors' => ['127.0.0.1']
            )
        end
        it do
          is_expected.to contain_file('/etc/dnsmasq.d/consul')
            .with_content(/^server=\/consul\.\/192\.168\.0\.2#8600$/)
        end
      end

      describe 'when recursors is set to []' do
        let(:params) { {:recursors => []} }
        it do
          is_expected.to contain_class('consul')
            .with_config_hash(
              'server' => false,
              'data_dir' => '/var/lib/consul',
              'log_level' => 'INFO',
              'advertise_addr' => '127.0.0.1',
              'client_addr' => '0.0.0.0',
              'domain' => 'consul.',
              'encrypt' => :undef,
              'ui' => true,
              'retry_join' => ['127.0.0.1'],
              'recursors' => []
            )
        end
      end

      describe 'when recursors is set to ["foo", "bar"]' do
        let(:params) { {:recursors => ['foo', 'bar']} }
        it do
          is_expected.to contain_class('consul')
            .with_config_hash(
              'server' => false,
              'data_dir' => '/var/lib/consul',
              'log_level' => 'INFO',
              'advertise_addr' => '127.0.0.1',
              'client_addr' => '0.0.0.0',
              'domain' => 'consul.',
              'encrypt' => :undef,
              'ui' => true,
              'retry_join' => ['127.0.0.1'],
              'recursors' => ['foo', 'bar']
            )
        end
      end

      describe 'when dnsmasq_host_alias is set to dockerhost' do
        let(:params) { {:dnsmasq_host_alias => 'dockerhost'} }
        it do
          is_expected.to contain_file('/etc/dnsmasq.d/consul')
            .with_content(/^host-record=dockerhost,127\.0\.0\.1$/)
        end
      end

      describe 'when advertise_addr is set to 192.168.0.2' do
        let(:params) { {:advertise_addr => '192.168.0.2'} }
        it do
          is_expected.to contain_class('consul')
            .with_config_hash(
              'server' => false,
              'data_dir' => '/var/lib/consul',
              'log_level' => 'INFO',
              'advertise_addr' => '192.168.0.2',
              'client_addr' => '0.0.0.0',
              'domain' => 'consul.',
              'encrypt' => :undef,
              'ui' => true,
              'retry_join' => ['127.0.0.1'],
              'recursors' => ['127.0.0.1']
            )
        end
        it do
          is_expected.to contain_file('/etc/dnsmasq.d/consul')
            .with_content(/^host-record=servicehost,192\.168\.0\.2$/)
        end
      end

      describe 'when custom dnsmasq options are set' do
        let(:params) do
          {
            :dnsmasq_opts => {
              'cache-size' => '150',
              'max-ttl' => '10'
            }
          }
        end
        it do
          is_expected.to contain_file('/etc/dnsmasq.d/consul')
            .with_content(/^cache-size=150$/)
            .without_content(/^cache-size=0$/)
            .with_content(/^max-ttl=10$/)
        end
      end
    end
  end
end
