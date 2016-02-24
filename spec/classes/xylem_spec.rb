require 'spec_helper'

describe 'seed_stack::xylem' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:concat_basedir => '/tmp/puppetconcat')
      end

      describe 'when gluster_hosts and gluster_mounts are passed' do
        let(:params) do
          {
            :gluster_hosts => ['gfs1.local', 'gfs2.local'],
            :gluster_mounts => ['/data/b1', '/data/b2'],
          }
        end

        it { is_expected.to compile }

        it { is_expected.to contain_class('seed_stack::xylem') }

        it do
          is_expected.to contain_class('xylem::node')
            .with_redis_host('127.0.0.1')
            .with_gluster(true)
            .with_gluster_mounts(['/data/b1', '/data/b2'])
            .with_gluster_nodes(['gfs1.local', 'gfs2.local'])
            .with_gluster_replica(nil)
            .with_gluster_stripe(nil)
            .with_repo_manage(true)
        end

        it { is_expected.not_to contain_class('xylem::docker') }
      end

      describe 'when gluster_replica and gluster_stripe are passed' do
        let(:params) do
          {
            :gluster_hosts => ['gfs1.local', 'gfs2.local'],
            :gluster_mounts => ['/data/b1', '/data/b2'],
            :gluster_replica => 2,
            :gluster_stripe => 3,
          }
        end

        it { is_expected.to compile }

        it { is_expected.to contain_class('seed_stack::xylem') }

        it do
          is_expected.to contain_class('xylem::node')
            .with_redis_host('127.0.0.1')
            .with_gluster(true)
            .with_gluster_mounts(['/data/b1', '/data/b2'])
            .with_gluster_nodes(['gfs1.local', 'gfs2.local'])
            .with_gluster_replica(2)
            .with_gluster_stripe(3)
            .with_repo_manage(true)
        end

        it { is_expected.not_to contain_class('xylem::docker') }
      end

      describe 'when gluster_hosts is not passed' do
        let(:params) { {:gluster_mounts => ['/data/b1', '/data/b2']} }
        it do
          is_expected.to compile.and_raise_error(/Must pass gluster_hosts/)
        end
      end

      describe 'when gluster_mounts is not passed' do
        let(:params) { {:gluster_hosts => ['gfs1.local', 'gfs2.local']} }
        it do
          is_expected.to compile.and_raise_error(/Must pass gluster_mounts/)
        end
      end
    end
  end
end
