require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::NeutronClient do
  let(:http) do
    double('http').tap do |http|
      http.stub(:read_timeout) { 42 }
      http.stub(:open_timeout) { 43 }
    end
  end

  let(:config) do
    double('config').tap do |config|
      config.stub(:http) { http }
      config.stub(:ssl_ca_file) { nil }
      config.stub(:ssl_verify_peer) { true }
    end
  end

  let(:env) do
    {}.tap do |env|
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
    end
  end

  let(:session) do
    VagrantPlugins::Openstack.session
  end

  before :each do
    session.token = '123456'
    session.project_id = 'a1b2c3'
    session.endpoints = { network: 'http://neutron' }
    @neutron_client = VagrantPlugins::Openstack.neutron
  end

  describe 'get_private_networks' do
    context 'with token' do
      it 'returns only private networks for project in session' do
        stub_request(:get, 'http://neutron/networks')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(
            status: 200,
            body: '
              {
                "networks": [
                  { "name": "PublicNetwork", "tenant_id": "admin-tenant-id", "id": "net-pub" },
                  { "name": "net1", "tenant_id": "a1b2c3", "id": "net-1" },
                  { "name": "net2", "tenant_id": "a1b2c3", "id": "net-2" }
                ]
              }
            ')

        networks = @neutron_client.get_private_networks(env)

        expect(networks.length).to eq(2)
        expect(networks[0].id).to eq('net-1')
        expect(networks[0].name).to eq('net1')
        expect(networks[1].id).to eq('net-2')
        expect(networks[1].name).to eq('net2')
      end
    end
  end

  describe 'get_all_networks' do
    context 'with token' do
      it 'returns all networks for project in session' do
        stub_request(:get, 'http://neutron/networks')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'X-Auth-Token' => '123456'
            })
          .to_return(
            status: 200,
            body: '
              {
                "networks": [
                  { "name": "PublicNetwork", "tenant_id": "admin-tenant-id", "id": "net-pub" },
                  { "name": "net1", "tenant_id": "a1b2c3", "id": "net-1" },
                  { "name": "net2", "tenant_id": "a1b2c3", "id": "net-2" }
                ]
              }
            ')

        networks = @neutron_client.get_all_networks(env)

        expect(networks.length).to eq(3)
        expect(networks[0].id).to eq('net-pub')
        expect(networks[0].name).to eq('PublicNetwork')
        expect(networks[1].id).to eq('net-1')
        expect(networks[1].name).to eq('net1')
        expect(networks[2].id).to eq('net-2')
        expect(networks[2].name).to eq('net2')
      end
    end
  end

  describe 'get_subnets' do
    context 'with token' do
      it 'returns all available subnets' do
        stub_request(:get, 'http://neutron/subnets')
          .with(
            headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
          .to_return(
            status: 200,
            body: '
                  {
                    "subnets": [
                      { "id": "subnet-01", "name": "Subnet 1", "cidr": "192.168.1.0/24", "enable_dhcp": true, "network_id": "net-01" },
                      { "id": "subnet-02", "name": "Subnet 2", "cidr": "192.168.2.0/24", "enable_dhcp": false, "network_id": "net-01" },
                      { "id": "subnet-03", "name": "Subnet 3", "cidr": "192.168.100.0/24", "enable_dhcp": true, "network_id": "net-02" }
                    ]
                  }
                  ')

        networks = @neutron_client.get_subnets(env)

        expect(networks).to eq [Subnet.new('subnet-01', 'Subnet 1', '192.168.1.0/24', true, 'net-01'),
                                Subnet.new('subnet-02', 'Subnet 2', '192.168.2.0/24', false, 'net-01'),
                                Subnet.new('subnet-03', 'Subnet 3', '192.168.100.0/24', true, 'net-02')]
      end
    end
  end

  describe 'get_api_version_list' do
    context 'basic' do
      it 'returns version list' do
        stub_request(:get, 'http://neutron/')
          .with(header: { 'Accept' => 'application/json' })
          .to_return(
            status: 200,
            body: '{
              "versions": [
                {
                  "status": "...",
                  "id": "v1.0",
                  "links": [
                    {
                      "href": "http://neutron/v1.0",
                      "rel": "self"
                    }
                  ]
                },
                {
                  "status": "CURRENT",
                  "id": "v2.0",
                  "links": [
                    {
                      "href": "http://neutron/v2.0",
                      "rel": "self"
                    }
                  ]
                }
              ]}')

        versions = @neutron_client.get_api_version_list(env, :network)

        expect(versions.size).to eq(2)
      end
    end
  end
end
