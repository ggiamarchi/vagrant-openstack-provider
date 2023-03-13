require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::KeystoneClient do
  let(:http) do
    double('http').tap do |http|
      http.stub(:read_timeout) { 42 }
      http.stub(:open_timeout) { 43 }
      http.stub(:proxy) { nil }
    end
  end

  let(:config) do
    double('config').tap do |config|
      config.stub(:openstack_auth_url) { 'http://keystoneAuthV2/tokens' }
      config.stub(:openstack_compute_url) { nil }
      config.stub(:openstack_network_url) { nil }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
      config.stub(:http) { http }
      config.stub(:interface_type) { 'public' }
      config.stub(:identity_api_version) { '2' }
      config.stub(:project_name) { 'testTenant' }
      config.stub(:ssl_ca_file) { nil }
      config.stub(:ssl_verify_peer) { true }
      config.stub(:app_cred_id) { 'dummy' }
      config.stub(:app_cred_secret) { 'dummy' }
    end
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
    end
  end

  let(:session) do
    VagrantPlugins::Openstack.session
  end

  describe 'authenticate' do
    let(:keystone_request_headers) do
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }
    end

    let(:keystone_request_body) do
      '{"auth":{"tenantName":"testTenant","passwordCredentials":{"username":"username","password":"password"}}}'
    end

    let(:keystone_response_body) do
      '{"access":{"token":{"id":"0123456789","tenant":{"id":"testTenantId"}},"serviceCatalog":[
         {"endpoints":[{"id":"eid1","publicURL":"http://nova"}],"type":"compute"},
         {"endpoints":[{"id":"eid2","publicURL":"http://neutron"}],"type":"network"}
       ]}}'
    end

    let(:keystone_response_headers_v3) do
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'x_subject_token' => '0123456789'
      }
    end

    let(:keystone_request_body_v3) do
      '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"username","domain":'\
      '{"name":"dummy"},"password":"password"}}},"scope":{"project":{"name":"testTenant","domain":'\
      '{"name":"dummy"}}}}}'
    end

    let(:keystone_response_body_v3) do
      '{"token":{"is_domain":false,"methods":["password"],"roles":[{"id":"1234","name":"_member_"}],
        "is_admin_project":false,"project":{"domain":{"id":"1234","name":"dummy"},"id":"012345678910",
        "name":"testTenantId"},"catalog":[
         {"endpoints":[{"id":"eid1","interface":"public","url":"http://nova"}],"type":"compute"},
         {"endpoints":[{"id":"eid2","interface":"public","url":"http://neutron"}],"type":"network"}
       ]}}'
    end

    let(:keystone_request_body_app_cred) do
      '{"auth":{"identity":{"methods":["application_credential"],"application_credential":{"id":"dummy","secret":"dummy"}}}}'
    end

    before :each do
      @keystone_client = VagrantPlugins::Openstack.keystone
    end

    context 'with good credentials' do
      it 'store token and tenant id' do
        stub_request(:post, 'http://keystoneAuthV2/tokens')
          .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
          .to_return(
            status: 200,
            body: keystone_response_body,
            headers: keystone_request_headers)

        @keystone_client.authenticate(env)

        session.token.should eq('0123456789')
        session.project_id.should eq('testTenantId')
      end
    end

    context 'with wrong credentials' do
      it 'raise an unauthorized error' do
        stub_request(:post, 'http://keystoneAuthV2/tokens')
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

        expect { @keystone_client.authenticate(env) }.to raise_error(Errors::AuthenticationFailed)
      end
    end

    context 'with bad endpoint' do
      it 'raise a BadAuthenticationEndpoint error' do
        stub_request(:post, 'http://keystoneAuthV2/tokens')
          .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
          .to_return(
            status: 404)

        expect { @keystone_client.authenticate(env) }.to raise_error(Errors::BadAuthenticationEndpoint)
      end
    end

    context 'with /tokens suffix missing in URL' do
      it 'raise add the suffix' do
        config.stub(:openstack_auth_url) { 'http://keystoneAuthV2' }

        stub_request(:post, 'http://keystoneAuthV2/tokens')
          .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
          .to_return(
            status: 200,
            body: keystone_response_body,
            headers: keystone_request_headers)

        @keystone_client.authenticate(env)

        session.token.should eq('0123456789')
        session.project_id.should eq('testTenantId')
      end
    end

    context 'with internal server error' do
      it 'raise a VagrantOpenstackError error with response body as message' do
        stub_request(:post, 'http://keystoneAuthV2/tokens')
          .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
          .to_return(
            status: 500,
            body: 'Internal server error')

        begin
          @keystone_client.authenticate(env)
          fail 'Expected Errors::VagrantOpenstackError'
        rescue Errors::VagrantOpenstackError => e
          e.message.should eq('Internal server error')
        end
      end
    end

    # V3
    context 'with good credentials v3' do
      it 'store token and tenant id' do
        config.stub(:user_domain_name) { 'dummy' }
        config.stub(:project_domain_name) { 'dummy' }
        config.stub(:identity_api_version) { '3' }
        config.stub(:openstack_auth_url) { 'http://keystoneAuthV3' }
        config.stub(:openstack_auth_type) { nil }

        stub_request(:post, 'http://keystoneAuthV3/auth/tokens')
          .with(
            body: keystone_request_body_v3,
            headers: keystone_request_headers)
          .to_return(
            status: 200,
            body: keystone_response_body_v3,
            headers: keystone_response_headers_v3)

        @keystone_client.authenticate(env)

        session.token.should eq('0123456789')
        session.project_id.should eq('012345678910')
      end
    end

    context 'with wrong credentials v3' do
      it 'raise an unauthorized error ' do
        config.stub(:user_domain_name) { 'dummy' }
        config.stub(:project_domain_name) { 'dummy' }
        config.stub(:identity_api_version) { '3' }
        config.stub(:openstack_auth_url) { 'http://keystoneAuthV3' }
        config.stub(:openstack_auth_type) { nil }

        stub_request(:post, 'http://keystoneAuthV3/auth/tokens')
          .with(
            body: keystone_request_body_v3,
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
            headers: keystone_response_headers_v3)

        expect { @keystone_client.authenticate(env) }.to raise_error(Errors::AuthenticationFailed)
      end
    end

    context 'with good application credentials' do
      it 'store token and tenant id' do
        config.stub(:identity_api_version) { '3' }
        config.stub(:openstack_auth_url) { 'http://keystoneAuthV3' }
        config.stub(:openstack_auth_type) { 'v3applicationcredential' }

        stub_request(:post, 'http://keystoneAuthV3/auth/tokens')
          .with(
            body: keystone_request_body_app_cred,
            headers: keystone_request_headers)
          .to_return(
            status: 200,
            body: keystone_response_body_v3,
            headers: keystone_response_headers_v3)

        @keystone_client.authenticate(env)

        session.token.should eq('0123456789')
        session.project_id.should eq('012345678910')
      end
    end

    context 'with wrong application credentials' do
      it 'raise an unauthorized error ' do
        config.stub(:identity_api_version) { '3' }
        config.stub(:openstack_auth_url) { 'http://keystoneAuthV3' }
        config.stub(:openstack_auth_type) { nil }
        config.stub(:openstack_auth_type) { 'v3applicationcredential' }

        stub_request(:post, 'http://keystoneAuthV3/auth/tokens')
          .with(
            body: keystone_request_body_app_cred,
            headers: keystone_request_headers)
          .to_return(
            status: 404,
            body: '{
                "error": {
                  "message": "Could not find Application Credential: dummy",
                  "code": 404,
                  "title": "Not Found"
               }
              }',
            headers: keystone_response_headers_v3)

        expect { @keystone_client.authenticate(env) }.to raise_error(Errors::BadAuthenticationEndpoint)
      end
    end
  end
end
