require "vagrant-openstack-provider/spec_helper"

describe VagrantPlugins::Openstack::KeystoneClient do

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
      env[:ui].stub(:info).with(anything)
      env[:machine] = double("machine")
      env[:machine].stub(:provider_config) { config }
    end
  }

  let(:session) {
    VagrantPlugins::Openstack.session
  }

  describe "authenticate" do

    let(:keystone_request_headers) {
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
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
      @keystone_client = VagrantPlugins::Openstack::KeystoneClient.new
    end

    context "with good credentials" do

      it "store token and tenant id" do
        stub_request(:post, "http://keystoneAuthV2")
        .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
        .to_return(
            status: 200,
            body: keystone_response_body,
            headers: keystone_request_headers)

        @keystone_client.authenticate(env)

        session.token.should eq("0123456789")
        session.project_id.should eq("testTenantId")
        session.endpoints[:compute].should eq('http://nova')
        session.endpoints[:network].should eq('http://neutron')
      end

      context "with compute endpoint override" do
        it "store token and tenant id" do
          config.stub(:openstack_compute_url) { 'http://novaOverride' }

          stub_request(:post, "http://keystoneAuthV2")
          .with(
              body: keystone_request_body,
              headers: keystone_request_headers)
          .to_return(
              status: 200,
              body: keystone_response_body,
              headers: keystone_request_headers)

          @keystone_client.authenticate(env)

          session.token.should eq("0123456789")
          session.project_id.should eq("testTenantId")
          session.endpoints[:compute].should eq('http://novaOverride')
          session.endpoints[:network].should eq('http://neutron')
        end
      end

    end

    context "with wrong credentials" do
      it "raise an unauthorized error" do
        stub_request(:post, "http://keystoneAuthV2")
        .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
        .to_return(
            status: 401,
            body: '{
                "error": {
                  "message": "The request you have made requires authentication.",
                  "code": 401,
                  "title": "Unauthorized"
               }
              }',
            headers: keystone_request_headers)

        expect { @keystone_client.authenticate(env) }.to raise_error(RestClient::Unauthorized)
      end
    end

  end
end
