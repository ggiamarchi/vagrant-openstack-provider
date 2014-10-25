require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Action::WaitForServerToStop do

  let(:nova) do
    double('nova')
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
    context 'when server is active' do
      it 'become shutoff after one retry' do
        nova.stub(:get_server_details).and_return({ 'status' => 'ACTIVE' }, { 'status' => 'SHUTOFF' })
        expect(nova).to receive(:get_server_details).with(env, 'server_id').exactly(2).times
        @action = WaitForServerToStop.new(app, nil, 1, 5)
        @action.call(env)
      end
      it 'timeout after one retry' do
        nova.stub(:get_server_details).and_return({ 'status' => 'ACTIVE' }, { 'status' => 'ACTIVE' })
        expect(nova).to receive(:get_server_details).with(env, 'server_id').at_least(2).times
        @action = WaitForServerToStop.new(app, nil, 1, 2)
        expect { @action.call(env) }.to raise_error Timeout::Error
      end
    end
  end
end
