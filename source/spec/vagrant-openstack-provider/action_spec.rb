require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Action do

  let(:builder) do
    double('builder').tap do |builder|
      builder.stub(:use)
    end
  end

  describe 'action_destroy' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_destroy builder
    end
  end

  describe 'action_provision' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_provision builder
    end
  end

  describe 'action_read_ssh_info' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(ReadSSHInfo)
      Action.action_read_ssh_info builder
    end
  end

  describe 'action_read_state' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(ReadState)
      Action.action_read_state builder
    end
  end

  describe 'action_ssh' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      Action.action_ssh builder
    end
  end

  describe 'action_ssh_run' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_ssh_run builder
    end
  end

  describe 'action_up' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_up builder
    end
  end

  describe 'action_halt' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_halt builder
    end
  end

  describe 'action_suspend' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_suspend builder
    end
  end

  describe 'action_resume' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_resume builder
    end
  end

  describe 'action_reload' do
    it 'add others middleware to builder' do
      expect(builder).to receive(:use).with(ConfigValidate)
      expect(builder).to receive(:use).with(ConnectOpenstack)
      expect(builder).to receive(:use).with(Call, ReadState)
      # TODO, Impove this test to check what's happen after ReadState
      Action.action_reload builder
    end
  end
end
