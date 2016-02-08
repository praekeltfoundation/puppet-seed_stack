require 'spec_helper'

describe 'seed_stack::worker' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({:concat_basedir => '/tmp/puppetconcat'})
      end

      describe 'when controller_addrs and advertise_addr are passed' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.3',
          }
        end
        it { should compile }
      end

      describe 'when controller_addrs is not passed' do
        let(:params) { { :advertise_addr => '192.168.0.2', } }
        it { should compile.and_raise_error(/Must pass controller_addrs/) }
      end

      describe 'when advertise_addr is not passed' do
        let(:params) { { :controller_addrs => ['192.168.0.2'], } }
        it { should compile.and_raise_error(/Must pass advertise_addr/) }
      end
    end
  end
end
