require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Command::NetworkList do
  describe 'cmd' do

    let(:neutron) do
      double('neutron').tap do |neutron|
        neutron.stub(:get_private_networks) do
          [
            Item.new('net-01', 'internal'),
            Item.new('net-02', 'external')
          ]
        end
      end
    end

    let(:env) do
      Hash.new.tap do |env|
        env[:ui] = double('ui')
        env[:ui].stub(:info).with(anything)
        env[:openstack_client] = double
        env[:openstack_client].stub(:neutron) { neutron }
      end
    end

    before :each do
      @network_list_cmd = VagrantPlugins::Openstack::Command::NetworkList.new(nil, env)
    end

    it 'prints network list from server' do
      neutron.should_receive(:get_private_networks).with(env)

      expect(env[:ui]).to receive(:info).with('
+--------+----------+
| Id     | Name     |
+--------+----------+
| net-01 | internal |
| net-02 | external |
+--------+----------+
')
      @network_list_cmd.cmd('network-list', [], env)
    end
  end
end
