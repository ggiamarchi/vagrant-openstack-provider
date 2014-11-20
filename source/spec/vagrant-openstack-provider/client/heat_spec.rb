require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::NovaClient do
  include FakeFS::SpecHelpers::All

  let(:config) do
    double('config').tap do |config|
      config.stub(:openstack_auth_url) { 'http://heatAuthV2' }
      config.stub(:openstack_orchestration_url) { nil }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
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
    session.endpoints = { orchestration: 'http://heat/a1b2c3' }
    @heat_client = VagrantPlugins::Openstack.heat
  end

  describe 'stack_exists' do
    context 'stack not found' do
      it 'raise an StackNotFound error' do
        stub_request(:get, 'http://heat/a1b2c3/stacks/stack_name/stack_id')
            .with(
              headers:
              {
                'Accept' => 'application/json',
                'Accept-Encoding' => 'gzip, deflate',
                'X-Auth-Token' => '123456'
              })
            .to_return(
              status: 404,
              body: '{"itemNotFound": {"message": "Stack could not be found", "code": 404}}')

        expect { @heat_client.get_stack_details(env, 'stack_name', 'stack_id') }.to raise_error(VagrantPlugins::Openstack::Errors::StackNotFound)

      end
    end
  end

  describe 'create_stack' do
    context 'with token and project_id acquainted' do
      it 'returns new stack id' do

        stub_request(:post, 'http://heat/a1b2c3/stacks')
            .with(
              body: '{"stack_name":"stck","template":"toto"}',
              headers:
              {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 202, body: '{ "stack": { "id": "o1o2o3" } }')

        stack_id = @heat_client.create_stack(env, name: 'stck', template: 'toto')

        expect(stack_id).to eq('o1o2o3')
      end
    end
  end

  describe 'get_stack_details' do
    context 'with token and project_id acquainted' do
      it 'returns stack details' do

        stub_request(:get, 'http://heat/a1b2c3/stacks/stack_id/stack_name')
            .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 200, body: '
            {
                "stack": {
                    "description": "sample stack",
                    "disable_rollback": "True",
                    "id": "stack_id",
                    "stack_name": "stack_name",
                    "stack_status": "CREATE_COMPLETE"
                }
            }')

        stack = @heat_client.get_stack_details(env, 'stack_id', 'stack_name')

        expect(stack['id']).to eq('stack_id')
        expect(stack['stack_name']).to eq('stack_name')
      end
    end
  end

  describe 'delete_stack' do
    context 'with token and project_id acquainted' do
      it 'deletes the stack' do

        stub_request(:delete, 'http://heat/a1b2c3/stacks/stack_id/stack_name')
            .with(headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
            .to_return(status: 204)

        @heat_client.delete_stack(env, 'stack_id', 'stack_name')
      end
    end
  end
end
