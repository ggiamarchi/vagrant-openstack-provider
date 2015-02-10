require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Action::Resume do
  let(:nova) do
    double('nova').tap do |nova|
      nova.stub(:resume_server)
    end
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui').tap do |ui|
        ui.stub(:info).with(anything)
        ui.stub(:error).with(anything)
      end
      env[:openstack_client] = double('openstack_client').tap do |os|
        os.stub(:nova) { nova }
      end
      env[:machine] = OpenStruct.new
    end
  end

  let(:app) do
    double('app').tap do |app|
      app.stub(:call).with(anything)
    end
  end

  describe 'call' do
    context 'when server id is present' do
      it 'starts the server' do
        env[:machine].id = 'server_id'
        expect(nova).to receive(:resume_server).with(env, 'server_id')
        expect(app).to receive(:call)
        @action = Resume.new(app, nil)
        @action.call(env)
      end
    end
    context 'when server id is not present' do
      it 'does nothing' do
        env[:machine].id = nil
        expect(nova).to_not receive(:resume_server)
        expect(app).to receive(:call)
        @action = Resume.new(app, nil)
        @action.call(env)
      end
    end
  end
end
