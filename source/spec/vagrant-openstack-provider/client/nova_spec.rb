require "vagrant-openstack-provider/spec_helper"

describe VagrantPlugins::Openstack::NovaClient do

  let(:config) {
    double("config").tap do |config|
      config.stub(:openstack_auth_url) { "http://novaAuthV2" }
      config.stub(:openstack_compute_url) { nil }
      config.stub(:tenant_name) { "testTenant" }
      config.stub(:username) { "username" }
      config.stub(:password) { "password" }
    end
  }

  let(:env) {
    Hash.new.tap do |env|
      env[:ui] = double("ui")
      env[:ui].stub(:info).with(anything)
      env[:machine] = double("machine")
      env[:machine].stub(:provider_config) { config }
    end
  }

  let(:session) {
    VagrantPlugins::Openstack.session
  }

  before :each do
    session.token = "123456"
    session.project_id = "a1b2c3"
    session.endpoints = { compute: "http://nova/a1b2c3" }
    @nova_client = VagrantPlugins::Openstack::NovaClient.new
  end

  describe "get_all_flavors" do
    context "with token and project_id acquainted" do
      it "returns all flavors" do
        stub_request(:get, "http://nova/a1b2c3/flavors")
            .with(
              headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(
              status: 200,
              body: '{ "flavors": [ { "id": "f1", "name": "flavor1"}, { "id": "f2", "name": "flavor2"} ] }')

        flavors = @nova_client.get_all_flavors(env)

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
        stub_request(:get, "http://nova/a1b2c3/images")
            .with(
              headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(
              status: 200,
              body: '{ "images": [ { "id": "i1", "name": "image1"}, { "id": "i2", "name": "image2"} ] }')

        images = @nova_client.get_all_images(env)

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

        stub_request(:post, "http://nova/a1b2c3/servers")
            .with(
              body: '{"server":{"name":"inst","imageRef":"img","flavorRef":"flav","key_name":"key"}}',
              headers:
              {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 202, body: '{ "server": { "id": "o1o2o3" } }')

        instance_id = @nova_client.create_server(env, "inst", "img", "flav", "key")

        expect(instance_id).to eq('o1o2o3')

      end
    end
  end

  describe "delete_server" do
    context "with token and project_id acquainted" do
      it "returns new instance id" do

        stub_request(:delete, "http://nova/a1b2c3/servers/o1o2o3")
            .with(
              headers: {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 204)

        @nova_client.delete_server(env, "o1o2o3")

      end
    end
  end

  describe "suspend_server" do
    context "with token and project_id acquainted" do
      it "returns new instance id" do

        stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action")
            .with(
              body: "{ \"suspend\": null }",
              headers:
              {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 202)

        @nova_client.suspend_server(env, "o1o2o3")
      end
    end
  end

  describe "resume_server" do
    context "with token and project_id acquainted" do
      it "returns new instance id" do

        stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action")
            .with(
              body: "{ \"resume\": null }",
              headers:
              {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 202)

        @nova_client.resume_server(env, "o1o2o3")
      end
    end
  end

  describe "stop_server" do
    context "with token and project_id acquainted" do
      it "returns new instance id" do

        stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action")
            .with(
              body: '{ "os-stop": null }',
              headers:
              {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 202)

        @nova_client.stop_server(env, "o1o2o3")

      end
    end
  end

  describe "start_server" do
    context "with token and project_id acquainted" do
      it "returns new instance id" do

        stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action")
            .with(
              body: "{ \"os-start\": null }",
              headers:
              {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 202)

        @nova_client.start_server(env, "o1o2o3")

      end
    end
  end

  describe "get_server_details" do
    context "with token and project_id acquainted" do
      it "returns server details" do

        stub_request(:get, "http://nova/a1b2c3/servers/o1o2o3")
            .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 200, body: '
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

        server = @nova_client.get_server_details(env, "o1o2o3")

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

        stub_request(:get, "http://nova/a1b2c3/os-floating-ips")
            .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 200, body: '
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

        stub_request(:post, "http://nova/a1b2c3/servers/o1o2o3/action")
            .with(body: '{"addFloatingIp":{"address":"1.2.3.4"}}',
                  headers:
                  {
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                    'X-Auth-Token' => '123456'
                  })
            .to_return(status: 202)

        @nova_client.add_floating_ip(env, "o1o2o3", "1.2.3.4")
      end
    end

    context "with token and project_id acquainted and IP already in use" do
      it "raise an error" do

        stub_request(:get, "http://nova/a1b2c3/os-floating-ips")
            .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 200, body: '
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

        expect { @nova_client.add_floating_ip(env, "o1o2o3", "1.2.3.4") }.to raise_error(RuntimeError)
      end
    end

    context "with token and project_id acquainted and IP not allocated" do
      it "raise an error" do

        stub_request(:get, "http://nova/a1b2c3/os-floating-ips")
            .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 200, body: '
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

        expect { @nova_client.add_floating_ip(env, "o1o2o3", "1.2.3.4") }.to raise_error(RuntimeError)
      end
    end

  end
end
