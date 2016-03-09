require 'spec_helper'

describe 'seed_stack::template_nginx' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:concat_basedir => '/tmp/puppetconcat')
      end

      describe 'nginx is not managed here' do
        let(:params) do
          {
            :nginx_manage => false
          }
        end
        it { is_expected.to compile }
        it { is_expected.not_to contain_service('nginx') }
      end

      describe 'nginx is managed here' do
        let(:params) do
          {
            :nginx_manage => true
          }
        end
        it { is_expected.to compile }
        it { is_expected.to contain_service('nginx') }
      end

      describe 'no options' do
        it { is_expected.to compile }
      end
    end
  end
end
