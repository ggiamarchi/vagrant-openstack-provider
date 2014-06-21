require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::NeutronClient do

  let(:env) do
    Hash.new
  end

  let(:session) do
    VagrantPlugins::Openstack.session
  end

  before :each do
    session.token = '123456'
    session.project_id = 'a1b2c3'
    session.endpoints = { network: 'http://neutron' }
    @neutron_client = VagrantPlugins::Openstack::NeutronClient.new
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
        expect(networks[0][:id]).to eq('net-1')
        expect(networks[0][:name]).to eq('net1')
        expect(networks[1][:id]).to eq('net-2')
        expect(networks[1][:name]).to eq('net2')
      end
    end
  end
end
