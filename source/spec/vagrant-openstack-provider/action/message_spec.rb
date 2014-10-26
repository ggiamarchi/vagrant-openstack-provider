require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Action::Message do

  let(:ui) do
    double('ui').tap do |ui|
      ui.stub(:info).with(anything)
      ui.stub(:error).with(anything)
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = ui
    end
  end

  let(:app) do
    double('app').tap do |app|
      app.stub(:call).with(anything)
    end
  end

  describe 'call' do
    context 'when message is given' do
      it 'print out the message' do
        expect(ui).to receive(:info).with('Message to show')
        expect(app).to receive(:call)
        @action = Message.new(app, nil, 'Message to show')
        @action.call(env)
      end
    end
  end
end
