require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Action do

  let(:builder) do
    double('builder').tap do |builder|
      builder.stub(:use)
    end
  end

  before :each do
    Action.stub(:new_builder) { builder }
  end

  describe 'action_destroy' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_destroy
    end
  end

  describe 'action_provision' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_provision
    end
  end

  describe 'action_read_ssh_info' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(ReadSSHInfo)
      Action.action_read_ssh_info
    end
  end

  describe 'action_read_state' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(ReadState)
      Action.action_read_state
    end
  end

  describe 'action_ssh' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      Action.action_ssh
    end
  end

  describe 'action_ssh_run' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_ssh_run
    end
  end

  describe 'action_up' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_up
    end
  end

  describe 'action_halt' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_halt
    end
  end

  describe 'action_suspend' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_suspend
    end
  end

  describe 'action_resume' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_resume
    end
  end

  describe 'action_reload' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_reload
    end
  end
end
