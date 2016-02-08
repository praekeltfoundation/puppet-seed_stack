require 'spec_helper'

describe 'seed_stack::worker' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({:concat_basedir => '/tmp/puppetconcat'})
      end

      describe 'compiles when controller_addresses and address are specified' do
        let(:params) do
          {
            :controller_addresses => ['192.168.0.2'],
            :address => '192.168.0.3',
          }
        end
        it { should compile }
      end

      describe 'controller_addresses must be specified' do
        let(:params) { { :address => '192.168.0.2', } }
        it { should compile.and_raise_error(/Must pass controller_addresses/) }
      end

      describe 'address must be specified' do
        let(:params) { { :controller_addresses => ['192.168.0.2'], } }
        it { should compile.and_raise_error(/Must pass address/) }
      end
    end
  end
end
