require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Command::ImageList do
  describe 'cmd' do

    let(:nova) do
      double('nova').tap do |nova|
        nova.stub(:get_all_images) do
          [
            Item.new('0001', 'ubuntu'),
            Item.new('0002', 'centos'),
            Item.new('0003', 'debian')
          ]
        end
      end
    end

    let(:env) do
      Hash.new.tap do |env|
        env[:ui] = double('ui')
        env[:ui].stub(:info).with(anything)
        env[:openstack_client] = double
        env[:openstack_client].stub(:nova) { nova }
      end
    end

    before :each do
      @image_list_cmd = VagrantPlugins::Openstack::Command::ImageList.new(['--'], env)
    end

    it 'prints image list from server' do

      allow(@image_list_cmd).to receive(:with_target_vms).and_return(nil)

      nova.should_receive(:get_all_images).with(env)

      expect(env[:ui]).to receive(:info).with('
+------+--------+
| Id   | Name   |
+------+--------+
| 0001 | ubuntu |
| 0002 | centos |
| 0003 | debian |
+------+--------+')
      @image_list_cmd.cmd('image-list', [], env)
    end
  end
end
