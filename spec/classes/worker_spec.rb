require 'spec_helper'

describe 'seed_stack::worker' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({:concat_basedir => '/tmp/puppetconcat'})
      end

      describe 'when controller_addresses and address are passed' do
        let(:params) do
          {
            :controller_addresses => ['192.168.0.2'],
            :address => '192.168.0.3',
          }
        end
        it { should compile }
      end

      describe 'when controller_addresses is not passed' do
        let(:params) { { :address => '192.168.0.2', } }
        it { should compile.and_raise_error(/Must pass controller_addresses/) }
      end

      describe 'when address is not passed' do
        let(:params) { { :controller_addresses => ['192.168.0.2'], } }
        it { should compile.and_raise_error(/Must pass address/) }
      end
    end
  end
end
