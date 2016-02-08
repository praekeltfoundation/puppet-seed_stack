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
  end
end
