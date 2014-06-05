require "vagrant-openstack-provider/spec_helper"

describe VagrantPlugins::Openstack::OpenstackClient do

  let(:config) {
    double("config").tap do |config|
      config.stub(:openstack_auth_url) { "http://keystoneAuthV2" }
      config.stub(:openstack_compute_url) { "http://nova" }
      config.stub(:tenant_name) { "testTenant" }
      config.stub(:username) { "username" }
      config.stub(:api_key) { "password" }
    end
  }

  let(:env) {
    Hash.new.tap do |env|
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
            :body => '{"access":{"token":{"id":"0123456789","tenant":{"id":"testTenantId"}}}}',
            :headers => keystone_request_headers)

        @os_client.authenticate(env)

        @os_client.get_token.should eq("0123456789")
        @os_client.get_project_id.should eq("testTenantId")
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

  end

end
