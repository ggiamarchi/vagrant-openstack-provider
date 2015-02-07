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
        neutron.stub(:get_all_networks) do
          [
            Item.new('pub-01', 'public'),
            Item.new('net-01', 'internal'),
            Item.new('net-02', 'external')
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
+--------+----------+')

      @network_list_cmd.cmd('network-list', [], env)
    end

    it 'prints all networks list from server' do
      neutron.should_receive(:get_all_networks).with(env)

      expect(env[:ui]).to receive(:info).with('
+--------+----------+
| Id     | Name     |
+--------+----------+
| pub-01 | public   |
| net-01 | internal |
| net-02 | external |
+--------+----------+')

      @network_list_cmd.cmd('network-list', ['all'], env)
    end
  end
end
