require 'spec_helper'

describe 'seed_stack::worker' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:concat_basedir => '/tmp/puppetconcat')
      end

      describe 'when controller_addrs and advertise_addr are passed' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.2',
          }
        end

        it { is_expected.to compile }

        it { is_expected.to contain_class('seed_stack::worker') }

        it { is_expected.to contain_class('mesos') }

        it do
          is_expected.to contain_service('mesos-master')
            .with_ensure('stopped')
        end

        it { is_expected.to contain_class('mesos::slave') }

        it do
          is_expected.to contain_class('seed_stack::consul_dns')
            .with_join('192.168.0.2')
            .with_advertise_addr('192.168.0.2')
        end

        it { is_expected.to contain_consul__service('mesos-slave') }

        it { is_expected.to contain_class('seed_stack::template_nginx') }

        it { is_expected.to contain_class('seed_stack::router') }

        it { is_expected.to contain_class('docker') }

        it { is_expected.not_to contain_class('xylem::docker') }
      end

      describe 'when xylem_backend is passed' do
        let(:params) do
          {
            :controller_addrs => ['192.168.0.2'],
            :advertise_addr => '192.168.0.2',
            :xylem_backend => 'gfs1.local',
          }
        end

        it { is_expected.to compile }

        it { is_expected.to contain_class('seed_stack::worker') }

        it { is_expected.to contain_class('mesos') }

        it do
          is_expected.to contain_service('mesos-master')
            .with_ensure('stopped')
        end

        it { is_expected.to contain_class('mesos::slave') }

        it do
          is_expected.to contain_class('seed_stack::consul_dns')
            .with_join('192.168.0.2')
            .with_advertise_addr('192.168.0.2')
        end

        it { is_expected.to contain_consul__service('mesos-slave') }

        it { is_expected.to contain_class('seed_stack::template_nginx') }

        it { is_expected.to contain_class('seed_stack::router') }

        it { is_expected.to contain_class('docker') }

        it do
          is_expected.to contain_class('xylem::docker')
            .with_backend('gfs1.local')
            .with_repo_manage(true)
            .that_requires('Class[docker]')
        end
      end

      describe 'when controller_addrs is not passed' do
        let(:params) { {:advertise_addr => '192.168.0.2'} }
        it do
          is_expected.to compile.and_raise_error(must_pass 'controller_addrs')
        end
      end

      describe 'when advertise_addr is not passed' do
        let(:params) { {:controller_addrs => ['192.168.0.2']} }
        it do
          is_expected.to compile.and_raise_error(must_pass 'advertise_addr')
        end
      end
    end
  end
end
