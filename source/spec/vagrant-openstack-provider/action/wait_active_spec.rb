require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Action::WaitForServerToBeActive do

  let(:nova) do
    double('nova')
  end

  let(:config) do
    double('config')
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui').tap do |ui|
        ui.stub(:info).with(anything)
        ui.stub(:error).with(anything)
      end
      env[:openstack_client] = double('openstack_client').tap do |os|
        os.stub(:nova) { nova }
      end
      env[:machine] = OpenStruct.new.tap do |m|
        m.provider_config = config
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
    context 'when server is not yet active' do
      it 'become active after one retry' do
        nova.stub(:get_server_details).and_return({ 'status' => 'BUILD' }, { 'status' => 'ACTIVE' })
        expect(nova).to receive(:get_server_details).with(env, 'server_id').exactly(2).times
        expect(app).to receive(:call)
        config.stub(:server_active_timeout) { 5 }
        @action = WaitForServerToBeActive.new(app, nil, 1)
        @action.call(env)
      end
      it 'timeout after one retry' do
        nova.stub(:get_server_details).and_return({ 'status' => 'BUILD' }, { 'status' => 'BUILD' })
        expect(nova).to receive(:get_server_details).with(env, 'server_id').at_least(2).times
        config.stub(:server_active_timeout) { 2 }
        @action = WaitForServerToBeActive.new(app, nil, 1)
        expect { @action.call(env) }.to raise_error Errors::Timeout
      end
    end
  end
end
