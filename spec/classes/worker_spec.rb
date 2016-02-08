require 'spec_helper'

describe 'seed_stack::worker' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({:concat_basedir => '/tmp/puppetconcat'})
      end

      let(:params) do
        {
          :controller_addresses => ['192.168.0.2'],
          :address => '192.168.0.3',
        }
      end

      it { should compile }
    end

    context 'controller_addresses is required' do
      let(:params) do
        { :address => '192.168.0.2', }
      end

      it { should compile.and_raise_error(/Must pass controller_addresses/) }
    end

    context 'address is required' do
      let(:params) do
        { :controller_addresses => ['192.168.0.2'], }
      end

      it { should compile.and_raise_error(/Must pass address/) }
    end
  end
end
