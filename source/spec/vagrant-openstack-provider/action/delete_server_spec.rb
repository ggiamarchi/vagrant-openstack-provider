require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Action::DeleteServer do
  let(:nova) do
    double('nova').tap do |app|
      app.stub(:delete_server)
      app.stub(:delete_keypair_if_vagrant)
    end
  end

  let(:openstack_client) do
    double('openstack_client').tap do |os|
      os.stub(:nova) { nova }
    end
  end

  let(:config) do
    double('config')
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:ui].stub(:error).with(anything)
      env[:openstack_client] = openstack_client
      env[:machine] = OpenStruct.new.tap do |m|
        m.provider_config = config
        m.id = 'server_id'
      end
    end
  end

  before :each do
    DeleteServer.send(:public, *DeleteServer.private_instance_methods)
    app = double('app')
    app.stub(:call).with(anything)
    @action = DeleteServer.new(app, nil)
  end

  describe 'call' do
    context 'when id is present' do
      it 'delete server' do
        expect(nova).to receive(:delete_server).with(env, 'server_id')
        expect(nova).to receive(:delete_keypair_if_vagrant).with(env, 'server_id')
        expect(@action).to receive(:waiting_for_instance_to_be_deleted).with(env, 'server_id')
        @action.call(env)
      end
    end
    context 'when id is not present' do
      it 'delete server' do
        env[:machine].id = nil
        expect(nova).should_not_receive(:delete_server)
        expect(nova).should_not_receive(:delete_keypair_if_vagrant)
        @action.call(env)
      end
    end
  end

  describe 'waiting_for_instance_to_be_deleted' do
    context 'when server is not yet active' do
      it 'become deleted after one retry' do
        nova.stub(:get_server_details).once.and_return('status' => 'ACTIVE')
        nova.stub(:get_server_details).once.and_raise(Errors::InstanceNotFound)
        nova.should_receive(:get_server_details).with(env, 'server-01').exactly(1).times
        config.stub(:server_delete_timeout) { 5 }
        @action.waiting_for_instance_to_be_deleted(env, 'server-01', 1)
      end
      it 'become deleted after one retry' do
        nova.stub(:get_server_details).and_return({ 'status' => 'ACTIVE' }, 'status' => 'DELETED')
        nova.should_receive(:get_server_details).with(env, 'server-01').exactly(2).times
        config.stub(:server_delete_timeout) { 5 }
        @action.waiting_for_instance_to_be_deleted(env, 'server-01', 1)
      end
      it 'timeout before the server become active' do
        nova.stub(:get_server_details).and_return({ 'status' => 'ACTIVE' }, 'status' => 'ACTIVE')
        nova.should_receive(:get_server_details).with(env, 'server-01').at_least(2).times
        config.stub(:server_delete_timeout) { 3 }
        expect { @action.waiting_for_instance_to_be_deleted(env, 'server-01', 1) }.to raise_error Errors::Timeout
      end
      it 'raise an error after one retry' do
        nova.stub(:get_server_details).and_return({ 'status' => 'ACTIVE' }, 'status' => 'ERROR')
        nova.should_receive(:get_server_details).with(env, 'server-01').exactly(2).times
        config.stub(:server_delete_timeout) { 3 }
        expect { @action.waiting_for_instance_to_be_deleted(env, 'server-01', 1) }.to raise_error Errors::ServerStatusError
      end
    end
  end
end
