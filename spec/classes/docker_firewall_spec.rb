require 'spec_helper'

describe 'seed_stack::docker_firewall' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({:network_docker0 => '172.17.0.0'})
      end

      it { should compile }
    end
  end
end
