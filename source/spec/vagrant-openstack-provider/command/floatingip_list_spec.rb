require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Command::FloatingIpList do
  describe 'cmd' do
    let(:nova) do
      double('nova').tap do |nova|
        nova.stub(:get_floating_ip_pools) do
          [
            {
              'name' => 'pool1'
            },
            {
              'name' => 'pool2'
            }
          ]
        end
        nova.stub(:get_floating_ips) do
          [
            {
              'fixed_ip' => nil,
              'id' => 1,
              'instance_id' => nil,
              'ip' => '10.10.10.1',
              'pool' => 'pool1'
            },
            {
              'fixed_ip' => nil,
              'id' => 2,
              'instance_id' => 'inst001',
              'ip' => '10.10.10.2',
              'pool' => 'pool2'
            }
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
      end
    end

    before :each do
      @floating_ip_list_cmd = VagrantPlugins::Openstack::Command::FloatingIpList.new(nil, env)
    end

    it 'prints floating ip and floating ip pool from server' do
      nova.should_receive(:get_floating_ip_pools).with(env)
      nova.should_receive(:get_floating_ips).with(env)

      expect(env[:ui]).to receive(:info).with('
+-------------------+
| Floating IP pools |
+-------------------+
| pool1             |
| pool2             |
+-------------------+').ordered

      expect(env[:ui]).to receive(:info).with('
+----+------------+-------+-------------+
| ID | IP         | Pool  | Instance ID |
+----+------------+-------+-------------+
| 1  | 10.10.10.1 | pool1 |             |
| 2  | 10.10.10.2 | pool2 | inst001     |
+----+------------+-------+-------------+').ordered

      @floating_ip_list_cmd.cmd('floatingip-list', [], env)
    end
  end
end
