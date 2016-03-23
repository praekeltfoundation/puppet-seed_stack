require 'spec_helper'

describe 'seed_stack::load_balancer' do
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
          is_expected.to contain_file(
            '/etc/consul-template/nginx-websites.ctmpl')
            .with_content(/^\s*listen 80;/)
            .with_content(/^\s*listen 127\.0\.0\.1:80;/)
        end

        it do
          is_expected.to contain_consul_template__watch('nginx-websites')
            .with(
              'source' => '/etc/consul-template/nginx-websites.ctmpl',
              'destination' => '/etc/nginx/sites-enabled/seed-websites.conf',
              'command' => '/etc/init.d/nginx reload'
            ).that_subscribes_to(
              'File[/etc/consul-template/nginx-websites.ctmpl]')
        end
      end

      describe 'with custom parameters' do
        let(:params) { {:listen_addr => '192.168.0.1'} }

        it do
          is_expected.to contain_file(
            '/etc/consul-template/nginx-websites.ctmpl')
            .with_content(/^\s*listen 80;/)
            .with_content(/^\s*listen 192\.168\.0\.1:80;/)
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
