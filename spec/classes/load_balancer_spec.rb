require 'spec_helper'

describe 'seed_stack::load_balancer' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({:concat_basedir => '/tmp/puppetconcat'})
      end

      it { is_expected.to compile }
    end
  end
end
