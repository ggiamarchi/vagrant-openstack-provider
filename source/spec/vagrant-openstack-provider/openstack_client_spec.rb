require "vagrant-openstack-provider/spec_helper"

describe VagrantPlugins::Openstack::OpenstackClient do

  let(:config) {
    double("config").tap do |config|
      config.stub(:openstack_auth_url) { "http://keystoneAuthV2" }
      config.stub(:openstack_compute_url) { nil }
      config.stub(:tenant_name) { "testTenant" }
      config.stub(:username) { "username" }
      config.stub(:password) { "password" }
    end
  }

  let(:env) {
    Hash.new.tap do |env|
      env[:ui] = double("ui")
      env[:ui].stub(:info).with(anything())
      env[:machine] = double("machine")
      env[:machine].stub(:provider_config) { config }
    end
  }

  describe "authenticate" do

    class OpenstackClientTest < VagrantPlugins::Openstack::OpenstackClient
      def get_token()
        return @token
      end

      def get_project_id()
        return @project_id
      end

      def get_endpoints()
        return @endpoints
      end
    end

    let(:keystone_request_headers) {
      {
          'Accept'=>'application/json',
          'Content-Type'=>'application/json'
      }
    }

    let(:keystone_request_body) {
      '{"auth":{"tenantName":"testTenant","passwordCredentials":{"username":"username","password":"password"}}}'
    }

    let(:keystone_response_body) {
      '{"access":{"token":{"id":"0123456789","tenant":{"id":"testTenantId"}},"serviceCatalog":[
         {"endpoints":[{"id":"eid1","publicURL":"http://nova"}],"type":"compute"},
         {"endpoints":[{"id":"eid2","publicURL":"http://neutron"}],"type":"network"}
       ]}}'
    }

    before :each do
      @os_client = OpenstackClientTest.new
    end

    context "with good credentials" do

      it "store token and tenant id" do
        stub_request(:post, "http://keystoneAuthV2").
          with(
            :body => keystone_request_body,
            :headers => keystone_request_headers).
          to_return(
            :status => 200,
            :body => keystone_response_body,
            :headers => keystone_request_headers)

        @os_client.authenticate(env)

        @os_client.get_token.should eq("0123456789")
        @os_client.get_project_id.should eq("testTenantId")
        @os_client.get_endpoints()['compute'].should eq('http://nova')
        @os_client.get_endpoints()['network'].should eq('http://neutron')
      end

      context "with compute endpoint override" do
        it "store token and tenant id" do
          config.stub(:openstack_compute_url) { 'http://novaOverride' }

          stub_request(:post, "http://keystoneAuthV2").
            with(
              :body => keystone_request_body,
              :headers => keystone_request_headers).
            to_return(
              :status => 200,
              :body => keystone_response_body,
              :headers => keystone_request_headers)

          @os_client.authenticate(env)

          @os_client.get_token.should eq("0123456789")
          @os_client.get_project_id.should eq("testTenantId")
          @os_client.get_endpoints()['compute'].should eq('http://novaOverride')
          @os_client.get_endpoints()['network'].should eq('http://neutron')
        end
      end

    end

    context "with wrong credentials" do
      it "raise an unauthorized error" do
        stub_request(:post, "http://keystoneAuthV2").
            with(
              :body => keystone_request_body,
              :headers => keystone_request_headers).
            to_return(
              :status => 401,
              :body => '{
                "error": {
                  "message": "The request you have made requires authentication.",
                  "code": 401,
                  "title": "Unauthorized"
               }
              }',
              :headers => keystone_request_headers)

        expect { @os_client.authenticate(env) }.to raise_error(RestClient::Unauthorized)
      end
    end

  end

  describe "nova api calls" do

    class OpenstackClientNovaTest < VagrantPlugins::Openstack::OpenstackClient
      def initialize()
        @token = "123456"
        @project_id = "a1b2c3"
        @endpoints = Hash.new
        @endpoints['compute'] = "http://nova/a1b2c3"
      end
    end

    before :each do
      @os_client = OpenstackClientNovaTest.new
    end

    describe "get_all_flavors" do
      context "with token and project_id acquainted" do
        it "returns all flavors" do
          stub_request(:get, "http://nova/a1b2c3/flavors").
              with(
                :headers => {
                    'Accept'=>'application/json',
                    'X-Auth-Token'=>'123456'
              }).
              to_return(
                :status => 200,
                :body => '{ "flavors": [ { "id": "f1", "name": "flavor1"}, { "id": "f2", "name": "flavor2"} ] }')

          flavors = @os_client.get_all_flavors(env)

          expect(flavors.length).to eq(2)
          expect(flavors[0].id).to eq('f1')
          expect(flavors[0].name).to eq('flavor1')
          expect(flavors[1].id).to eq('f2')
          expect(flavors[1].name).to eq('flavor2')
        end
      end
    end

    describe "get_all_images" do
      context "with token and project_id acquainted" do
        it "returns all images" do
          stub_request(:get, "http://nova/a1b2c3/images").
              with(
              :headers => {
                  'Accept'=>'application/json',
                  'X-Auth-Token'=>'123456'
              }).
              to_return(
              :status => 200,
              :body => '{ "images": [ { "id": "i1", "name": "image1"}, { "id": "i2", "name": "image2"} ] }')

          images = @os_client.get_all_images(env)

          expect(images.length).to eq(2)
          expect(images[0].id).to eq('i1')
          expect(images[0].name).to eq('image1')
          expect(images[1].id).to eq('i2')
          expect(images[1].name).to eq('image2')
        end
      end
    end

    describe "create_server" do
      context "with token and project_id acquainted" do
        it "returns new instance id" do

          stub_request(:post, "http://nova/a1b2c3/servers").
              with(
              :body => '{"server":{"name":"inst","imageRef":"img","flavorRef":"flav","key_name":"key"}}',
              :headers => {
                'Accept'=>'application/json',
                'Content-Type'=>'application/json',
                'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 202, :body => '{ "server": { "id": "o1o2o3" } }')

          instance_id = @os_client.create_server(env, "inst", "img", "flav", "key")

          expect(instance_id).to eq('o1o2o3')

        end
      end
    end

    describe "delete_server" do
      context "with token and project_id acquainted" do
        it "returns new instance id" do

          stub_request(:delete, "http://nova/a1b2c3/servers/o1o2o3").
              with(
              :headers => {
                'Accept'=>'application/json',
                'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 204)

          @os_client.delete_server(env, "o1o2o3")

        end
      end
    end

    describe "suspend_server" do
      context "with token and project_id acquainted" do
        it "returns new instance id" do

          stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action").
              with(
                :body => "{ \"suspend\": null }",
                :headers => {
                    'Accept'=>'application/json',
                    'Content-Type'=>'application/json',
                    'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 202)

          @os_client.suspend_server(env, "o1o2o3")
        end
      end
    end

    describe "resume_server" do
      context "with token and project_id acquainted" do
        it "returns new instance id" do

          stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action").
              with(
                :body => "{ \"resume\": null }",
                :headers => {
                    'Accept'=>'application/json',
                    'Content-Type'=>'application/json',
                    'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 202)

          @os_client.resume_server(env, "o1o2o3")
        end
      end
    end

    describe "stop_server" do
      context "with token and project_id acquainted" do
        it "returns new instance id" do

          stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action").
              with(
                :body => "{ \"os-stop\": null }",
                :headers => {
                    'Accept'=>'application/json',
                    'Content-Type'=>'application/json',
                    'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 202)

          @os_client.stop_server(env, "o1o2o3")

        end
      end
    end

    describe "start_server" do
      context "with token and project_id acquainted" do
        it "returns new instance id" do

          stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action").
              with(
                :body => "{ \"os-start\": null }",
                :headers => {
                    'Accept'=>'application/json',
                    'Content-Type'=>'application/json',
                    'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 202)

          @os_client.start_server(env, "o1o2o3")

        end
      end
    end

    describe "get_server_details" do
      context "with token and project_id acquainted" do
        it "returns server details" do

          stub_request(:get, "http://nova/a1b2c3/servers/o1o2o3").
              with(:headers => {
              'Accept'=>'application/json',
              'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 200, :body => '
                {
                  "server": {
                     "addresses": { "private": [ { "addr": "192.168.0.3", "version": 4 } ] },
                     "created": "2012-08-20T21:11:09Z",
                     "flavor": { "id": "1" },
                     "id": "o1o2o3",
                     "image": { "id": "i1" },
                     "name": "new-server-test",
                     "progress": 0,
                     "status": "ACTIVE",
                     "tenant_id": "openstack",
                     "updated": "2012-08-20T21:11:09Z",
                     "user_id": "fake"
                  }
                }
              ')

          server = @os_client.get_server_details(env, "o1o2o3")

          expect(server['id']).to eq('o1o2o3')
          expect(server['status']).to eq('ACTIVE')
          expect(server['tenant_id']).to eq('openstack')
          expect(server['image']['id']).to eq('i1')
          expect(server['flavor']['id']).to eq('1')

        end
      end
    end

    describe "add_floating_ip" do

      context "with token and project_id acquainted and IP available" do
        it "returns server details" do

          stub_request(:get, "http://nova/a1b2c3/os-floating-ips").
              with(:headers => {
              'Accept'=>'application/json',
              'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 200, :body => '
                {
                    "floating_ips": [
                        {
                            "fixed_ip": null,
                            "id": 1,
                            "instance_id": null,
                            "ip": "1.2.3.4",
                            "pool": "nova"
                        },
                        {
                            "fixed_ip": null,
                            "id": 2,
                            "instance_id": null,
                            "ip": "5.6.7.8",
                            "pool": "nova"
                        }
                    ]
                }')

          stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action").
              with(:body => '{"addFloatingIp":{"address":"1.2.3.4"}}',
                   :headers => {
                       'Accept'=>'application/json',
                       'Content-Type'=>'application/json',
                       'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 202)

          @os_client.add_floating_ip(env, "o1o2o3", "1.2.3.4")
        end
      end

      context "with token and project_id acquainted and IP already in use" do
        it "raise an error" do

          stub_request(:get, "http://nova/a1b2c3/os-floating-ips").
              with(:headers => {
              'Accept'=>'application/json',
              'X-Auth-Token'=>'123456'
              }).
              to_return(:status => 200, :body => '
                {
                    "floating_ips": [
                        {
                            "fixed_ip": null,
                            "id": 1,
                            "instance_id": "inst",
                            "ip": "1.2.3.4",
                            "pool": "nova"
                        },
                        {
                            "fixed_ip": null,
                            "id": 2,
                            "instance_id": null,
                            "ip": "5.6.7.8",
                            "pool": "nova"
                        }
                    ]
                }')

          expect { @os_client.add_floating_ip(env, "o1o2o3", "1.2.3.4") }.to raise_error(RuntimeError)
        end
      end

      context "with token and project_id acquainted and IP not allocated" do
        it "raise an error" do

          stub_request(:get, "http://nova/a1b2c3/os-floating-ips").
              with(:headers => {
              'Accept'=>'application/json',
              'X-Auth-Token'=>'123456'
          }).
              to_return(:status => 200, :body => '
                {
                    "floating_ips": [
                        {
                            "fixed_ip": null,
                            "id": 2,
                            "instance_id": null,
                            "ip": "5.6.7.8",
                            "pool": "nova"
                        }
                    ]
                }')

          expect { @os_client.add_floating_ip(env, "o1o2o3", "1.2.3.4") }.to raise_error(RuntimeError)
        end
      end

    end

  end

end
