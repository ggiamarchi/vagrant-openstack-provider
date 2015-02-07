require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Command::SubnetList do
  describe 'cmd' do
    let(:neutron) do
      double('neutron').tap do |neutron|
        neutron.stub(:get_subnets) do
          [
            Subnet.new('subnet-01', 'Subnet 1', '192.168.1.0/24', true, 'net-01'),
            Subnet.new('subnet-02', 'Subnet 2', '192.168.2.0/24', false, 'net-01'),
            Subnet.new('subnet-03', 'Subnet 3', '192.168.100.0/24', true, 'net-02')
          ]
        end
      end
    end

    let(:env) do
      {}.tap do |env|
        env[:ui] = double('ui')
        env[:ui].stub(:info).with(anything)
        env[:openstack_client] = double
        env[:openstack_client].stub(:neutron) { neutron }
      end
    end

    before :each do
      @subnet_list_cmd = VagrantPlugins::Openstack::Command::SubnetList.new(nil, env)
    end

    it 'prints subnet list from server' do
      neutron.should_receive(:get_subnets).with(env)

      expect(env[:ui]).to receive(:info).with('
+-----------+----------+------------------+-------+------------+
| Id        | Name     | CIDR             | DHCP  | Network Id |
+-----------+----------+------------------+-------+------------+
| subnet-01 | Subnet 1 | 192.168.1.0/24   | true  | net-01     |
| subnet-02 | Subnet 2 | 192.168.2.0/24   | false | net-01     |
| subnet-03 | Subnet 3 | 192.168.100.0/24 | true  | net-02     |
+-----------+----------+------------------+-------+------------+')

      @subnet_list_cmd.cmd('subnet-list', [], env)
    end
  end
end
