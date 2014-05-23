require "utils/coverage"
require 'webmock/rspec'
require "vagrant-openstack-provider/openstack_client"

describe VagrantPlugins::Openstack::OpenstackClient do

  describe "authenticate" do

    class OpenstackClientTest < VagrantPlugins::Openstack::OpenstackClient
      def get_token()
        return @token
      end

      def get_project_id()
        return @project_id
      end
    end

    let(:config) {
      double("config").tap do |config|
        config.stub(:openstack_auth_url) { "http://keystoneAuthV2" }
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

end
