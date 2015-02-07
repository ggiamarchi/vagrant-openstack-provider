require 'vagrant-openstack-provider/spec_helper'
require 'ostruct'
require 'sshkey'

include VagrantPlugins::Openstack::Action
include VagrantPlugins::Openstack::HttpUtils
include VagrantPlugins::Openstack::Domain

describe VagrantPlugins::Openstack::Action::CreateStack do
  let(:config) do
    double('config').tap do |config|
      config.stub(:stacks) do
        [
          {
            name: 'stack1',
            template: 'template.yml'
          },
          {
            name: 'stack2',
            template: 'template.yml'
          }
        ]
      end
      config.stub(:stack_create_timeout) { 200 }
    end
  end

  let(:heat) do
    double('heat')
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine] = OpenStruct.new.tap do |m|
        m.provider_config = config
        m.id = nil
      end
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:heat) { heat }
    end
  end
  before :each do
    CreateStack.send(:public, *CreateStack.private_instance_methods)
    app = double('app')
    app.stub(:call).with(anything)
    @action = CreateStack.new(app, nil)
    YAML.stub(:load_file).with('template.yml').and_return(YAML.load('
      heat_template_version: 2013-05-23

      description: Simple template to deploy a single compute instance

      resources:
        my_instance:
          type: OS::Nova::Server
          properties:
            key_name: julien-mac
            image: CoreOS
            flavor: 1_vCPU_RAM_512M_HD_10G
    '))
  end

  describe 'call' do
    it 'should create stacks on heat twice' do
      heat.stub(:create_stack).and_return('idstack')
      File.should_receive(:write).with('/stack_stack1_id', 'idstack')
      File.should_receive(:write).with('/stack_stack2_id', 'idstack')
      # TODO(julienvey) assert content of create call is correct
      heat.should_receive(:create_stack).exactly(2).times
      heat.stub(:get_stack_details).and_return('stack_status' => 'CREATE_COMPLETE')
      @action.call(env)
    end
  end

  describe 'waiting_for_server_to_be_built' do
    context 'when server is not yet active' do
      it 'become active after one retry' do
        heat.stub(:get_stack_details).and_return({ 'stack_status' => 'CREATE_IN_PROGRESS' }, 'stack_status' => 'CREATE_COMPLETE')
        heat.should_receive(:get_stack_details).with(env, 'stack1', 'id-01').exactly(2).times
        config.stub(:stack_create_timeout) { 5 }
        @action.waiting_for_stack_to_be_created(env, 'stack1', 'id-01', 1)
      end
      it 'timeout before the server become active' do
        heat.stub(:get_stack_details).and_return({ 'stack_status' => 'CREATE_IN_PROGRESS' }, 'stack_status' => 'CREATE_IN_PROGRESS')
        heat.should_receive(:get_stack_details).with(env, 'stack1', 'id-01').at_least(2).times
        config.stub(:stack_create_timeout) { 3 }
        expect { @action.waiting_for_stack_to_be_created(env, 'stack1', 'id-01', 1) }.to raise_error Errors::Timeout
      end
      it 'raise an error after one retry' do
        heat.stub(:get_stack_details).and_return({ 'stack_status' => 'CREATE_IN_PROGRESS' }, 'stack_status' => 'CREATE_FAILED')
        heat.should_receive(:get_stack_details).with(env, 'stack1', 'id-01').exactly(2).times
        config.stub(:stack_create_timeout) { 3 }
        expect { @action.waiting_for_stack_to_be_created(env, 'stack1', 'id-01', 1) }.to raise_error Errors::StackStatusError
      end
    end
  end
end
