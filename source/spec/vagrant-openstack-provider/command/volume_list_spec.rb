require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Command::FloatingIpList do
  describe 'cmd' do

    let(:cinder) do
      double('cinder').tap do |cinder|
        cinder.stub(:get_all_volumes) do
          [Volume.new('987', 'vol-01', '2', 'available', 'true', nil, nil),
           Volume.new('654', 'vol-02', '4', 'in-use', 'false', 'inst-01', '/dev/vdc')]
        end
      end
    end

    let(:env) do
      Hash.new.tap do |env|
        env[:ui] = double('ui')
        env[:ui].stub(:info).with(anything)
        env[:openstack_client] = double
        env[:openstack_client].stub(:cinder) { cinder }
      end
    end

    before :each do
      @volume_list_cmd = VagrantPlugins::Openstack::Command::VolumeList.new(nil, env)
    end

    it 'prints volumes list from server' do
      cinder.should_receive(:get_all_volumes).with(env)
      expect(env[:ui]).to receive(:info).with('
+-----+--------+-----------+-----------+-------------------------------------+
| Id  | Name   | Size (Go) | Status    | Attachment (instance id and device) |
+-----+--------+-----------+-----------+-------------------------------------+
| 987 | vol-01 | 2         | available |                                     |
| 654 | vol-02 | 4         | in-use    | inst-01 (/dev/vdc)                  |
+-----+--------+-----------+-----------+-------------------------------------+
')
      @volume_list_cmd.cmd('volume-list', [], env)
    end
  end
end
