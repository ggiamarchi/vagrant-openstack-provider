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

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:ui].stub(:error).with(anything)
      env[:openstack_client] = openstack_client
      env[:machine] = OpenStruct.new.tap do |m|
        m.id = 'server_id'
      end
    end
  end

  let(:app) do
    double('app').tap do |app|
      app.stub(:call).with(anything)
    end
  end

  describe 'call' do
    context 'when id is present' do
      it 'delete server' do
        expect(nova).to receive(:delete_server).with(env, 'server_id')
        expect(nova).to receive(:delete_keypair_if_vagrant).with(env, 'server_id')
        @action = DeleteServer.new(app, nil)
        @action.call(env)
      end
    end
    context 'when id is not present' do
      it 'delete server' do
        expect(nova).should_not_receive(:delete_server)
        expect(nova).should_not_receive(:delete_keypair_if_vagrant)
        @action = DeleteServer.new(app, nil)
        @action.call(env)
      end
    end
  end
end
