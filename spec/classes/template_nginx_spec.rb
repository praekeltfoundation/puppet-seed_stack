require 'spec_helper'

describe 'seed_stack::template_nginx' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:concat_basedir => '/tmp/puppetconcat')
      end

      describe 'with default parameters' do
        it { is_expected.to compile }
        it { is_expected.not_to contain_package('nginx-light') }
        it { is_expected.not_to contain_service('nginx') }

        it do
          is_expected.to contain_package('unzip')
            .with_ensure('installed')
        end
        it do
          is_expected.to contain_class('consul_template')
            .with_version(/\d+\.\d+\.\d+/)
            .with(
              'config_dir' => '/etc/consul-template',
              'user' => 'root',
              'group' => 'root',
              'consul_host' => '0.0.0.0',
              'consul_port' => 8500,
              'consul_retry' => '10s',
              'log_level' => 'warn'
            )
        end
        it do
          is_expected.to contain_class('consul_template::install')
            .that_requires('Package[unzip]')
        end

        it do
          is_expected.to(
            contain_file('/etc/consul-template/nginx-upstreams.ctmpl')
          )
        end
        it do
          is_expected.to contain_consul_template__watch('nginx-upstreams')
            .with(
              'source' => '/etc/consul-template/nginx-upstreams.ctmpl',
              'destination' => '/etc/nginx/sites-enabled/seed-upstreams.conf',
              'command' => '/etc/init.d/nginx reload'
            ).that_subscribes_to(
              'File[/etc/consul-template/nginx-upstreams.ctmpl]')
        end
      end
    end
  end
end
