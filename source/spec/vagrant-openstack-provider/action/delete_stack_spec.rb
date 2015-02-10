require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Action::DeleteStack do
  let(:heat) do
    double('heat').tap do |app|
      app.stub(:delete_stack)
    end
  end

  let(:openstack_client) do
    double('openstack_client').tap do |os|
      os.stub(:heat) { heat }
    end
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:ui].stub(:error).with(anything)
      env[:openstack_client] = openstack_client
      env[:machine] = OpenStruct.new.tap do |m|
        m.id = 'server_id'
        m.data_dir = '/test'
      end
    end
  end

  before :each do
    DeleteStack.send(:public, *DeleteStack.private_instance_methods)
    app = double('app')
    app.stub(:call).with(anything)
    @action = DeleteStack.new(app, nil)
  end

  describe 'call' do
    context 'when id is present' do
      it 'delete stack' do
        expect(heat).to receive(:delete_stack).with(env, 'test1', '1234')
        expect(heat).to receive(:delete_stack).with(env, 'test2', '2345')
        @action.stub(:list_stack_files).with(env).and_return([
          {
            name: 'test1',
            id: '1234'
          }, {
            name: 'test2',
            id: '2345'
          }])
        expect(@action).to receive(:waiting_for_stack_to_be_deleted).with(env, 'test1', '1234')
        expect(@action).to receive(:waiting_for_stack_to_be_deleted).with(env, 'test2', '2345')
        @action.call(env)
      end
    end
    context 'when id is not present' do
      it 'delete stack' do
        @action.stub(:list_stack_files).with(env).and_return([])
        expect(heat).should_not_receive(:delete_stack)
        expect(heat).should_not_receive(:waiting_for_stack_to_be_deleted)
        @action.call(env)
      end
    end
  end
end
