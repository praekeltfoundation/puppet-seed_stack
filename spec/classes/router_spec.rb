require 'spec_helper'

describe 'seed_stack::router' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:concat_basedir => '/tmp/puppetconcat')
      end

      describe 'with default parameters' do
        it { is_expected.to compile }

        it do
          is_expected.to contain_package('nginx-light')
            .with_ensure('installed')
        end

        it do
          is_expected.to contain_service('nginx')
            .with_ensure('running')
            .that_requires('Package[nginx-light]')
        end

        it { is_expected.to contain_class('seed_stack::template_nginx') }

        it do
          is_expected.to(
            contain_file('/etc/consul-template/nginx-services.ctmpl')
              .with_content(/^\s*listen 127\.0\.0\.1:80;$/)
              .with_content(/^\s*server_name servicehost;$/)
          )
        end

        it do
          is_expected.to contain_consul_template__watch('nginx-services')
            .with(
              'source' => '/etc/consul-template/nginx-services.ctmpl',
              'destination' => '/etc/nginx/sites-enabled/seed-services.conf',
              'command' => '/etc/init.d/nginx reload'
            ).that_subscribes_to(
              'File[/etc/consul-template/nginx-services.ctmpl]')
        end
      end

      describe 'with custom parameters' do
        let(:params) do
          {
            :listen_addr => '192.168.0.1',
            :listen_port => 8000,
            :domain => 'dockerhost'
          }
        end

        it do
          is_expected.to(
            contain_file('/etc/consul-template/nginx-services.ctmpl')
              .with_content(/^\s*listen 192\.168\.0\.1:8000;$/)
              .with_content(/^\s*server_name dockerhost;$/)
          )
        end
      end

      describe 'when nginx_manage is false' do
        let(:params) { {:nginx_manage => false} }
        it { is_expected.not_to contain_package('nginx-light') }
        it { is_expected.not_to contain_service('nginx') }
      end
    end
  end
end
