require 'spec_helper'

describe 'seed_stack::mc2' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:concat_basedir => '/tmp/puppetconcat')
      end

      def mc2_app_json(kvs)
        match_json(match(
            "id" => "/seed-infra-mc2",
            "apps" => [include({"id" => "/seed-infra-mc2/mc2"}.merge(kvs))],
        ))
      end

      describe 'when infr_domain and hub_domain are passed' do
        let(:params) do
          {
            :infr_domain => 'infr.example.com',
            :hub_domain => 'hub.example.com',
          }
        end

        it { is_expected.to contain_class('seed_stack::mc2') }

        it do
          is_expected.to contain_file('/etc/marathon-apps')
            .with(ensure: 'directory')
        end

        it do
          is_expected.to contain_file('/etc/marathon-apps/mc2.marathon.json')
            .with_content(mc2_app_json(
              "container" => include(
                "type" => "DOCKER",
                "docker" => include(
                  "image" => "praekeltfoundation/mc2",
                  "forcePullImage" => true,
                  "portMappings" => [include("containerPort" => 80)],
                  "parameters" => contain_exactly(
                    { "key" => "volume-driver", "value" => "xylem" },
                    { "key" => "volume", "value" => "seed-infra-mc2:/data" },
                  ),
                ),
              ),
              "env" => include(
                "MESOS_MARATHON_HOST" => "http://marathon.service.consul:8080",
                "HUB_DOMAIN" => "hub.example.com",
              ),
            ))
        end
      end

      describe 'when marathon_host is passed' do
        let(:params) do
          {
            :infr_domain => 'infr.example.com',
            :hub_domain => 'hub.example.com',
            :marathon_host => 'http://marathon.example.com:8080',
          }
        end

        it do
          is_expected.to contain_file('/etc/marathon-apps/mc2.marathon.json')
            .with_content(mc2_app_json(
              "container" => include(
                "type" => "DOCKER",
                "docker" => include(
                  "image" => "praekeltfoundation/mc2",
                  "forcePullImage" => true,
                  "portMappings" => [include("containerPort" => 80)],
                  "parameters" => contain_exactly(
                    { "key" => "volume-driver", "value" => "xylem" },
                    { "key" => "volume", "value" => "seed-infra-mc2:/data" },
                  ),
                ),
              ),
              "env" => include(
                "MESOS_MARATHON_HOST" => "http://marathon.example.com:8080",
                "HUB_DOMAIN" => "hub.example.com",
              ),
            ))
        end
      end

    end
  end
end
