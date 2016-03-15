require 'spec_helper'

describe 'seed_stack::load_balancer' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:concat_basedir => '/tmp/puppetconcat')
      end

      it { is_expected.to compile }
      it { is_expected.to contain_class('seed_stack::template_nginx') }
      it do
        is_expected.to contain_file('/etc/consul-template/nginx-websites.ctmpl')
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
  end
end
