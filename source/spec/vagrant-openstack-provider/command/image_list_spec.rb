require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Command::ImageList do
  let(:nova) do
    double('nova').tap do |nova|
      nova.stub(:get_all_images) do
        [
          Image.new('0001', 'ubuntu'),
          Image.new('0002', 'centos'),
          Image.new('0003', 'debian')
        ]
      end
    end
  end

  let(:glance) do
    double('nova').tap do |nova|
      nova.stub(:get_all_images) do
        [
          Image.new('0001', 'ubuntu', 'public',  700 * 1024 * 1024, 1, 10),
          Image.new('0002', 'centos', 'private', 800 * 1024 * 1024, 2, 20),
          Image.new('0003', 'debian', 'shared',  900 * 1024 * 1024, 4, 30)
        ]
      end
    end
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:openstack_client] = double
      env[:openstack_client].stub(:nova) { nova }
      env[:openstack_client].stub(:glance) { glance }
    end
  end

  before :each do
    @image_list_cmd = VagrantPlugins::Openstack::Command::ImageList.new(['--'], env)
  end

  describe 'cmd' do
    context 'when glance is not available' do
      let(:session) do
        double('session').tap do |s|
          s.stub(:endpoints) { {} }
        end
      end

      it 'prints image list with only the id and the name' do
        env[:openstack_client].stub(:session) { session }
        allow(@image_list_cmd).to receive(:with_target_vms).and_return(nil)
        nova.should_receive(:get_all_images).with(env)

        expect(env[:ui]).to receive(:info).with('
+------+--------+
| ID   | Name   |
+------+--------+
| 0001 | ubuntu |
| 0002 | centos |
| 0003 | debian |
+------+--------+')
        @image_list_cmd.cmd('image-list', [], env)
      end
    end

    context 'when glance is available' do
      let(:session) do
        double('session').tap do |s|
          s.stub(:endpoints) do
            {
              image: 'http://glance'
            }
          end
        end
      end

      it 'prints image list with id, name and details' do
        env[:openstack_client].stub(:session) { session }
        allow(@image_list_cmd).to receive(:with_target_vms).and_return(nil)
        glance.should_receive(:get_all_images).with(env)

        expect(env[:ui]).to receive(:info).with('
+------+--------+------------+-----------+--------------+---------------+
| ID   | Name   | Visibility | Size (Mo) | Min RAM (Go) | Min Disk (Go) |
+------+--------+------------+-----------+--------------+---------------+
| 0001 | ubuntu | public     | 700       | 1            | 10            |
| 0002 | centos | private    | 800       | 2            | 20            |
| 0003 | debian | shared     | 900       | 4            | 30            |
+------+--------+------------+-----------+--------------+---------------+')
        @image_list_cmd.cmd('image-list', [], env)
      end
    end
  end
end
