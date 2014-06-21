require 'vagrant-openstack-provider/spec_helper'

include VagrantPlugins::Openstack::Action

describe VagrantPlugins::Openstack::Action::CreateServer do

  let(:config) do
    double('config').tap do |config|
      config.stub(:openstack_auth_url) { 'http://keystoneAuthV2' }
      config.stub(:openstack_compute_url) { nil }
      config.stub(:openstack_network_url) { nil }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
    end
  end

  let(:neutron) do
    double('neutron').tap do |neutron|
      neutron.stub(:get_private_networks).with(anything) do
        [{ id: 'net-id-1', name: 'net-1' }, { id: 'net-id-2', name: 'net-2' }]
      end
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:neutron) { neutron }
    end
  end

  before :each do
    CreateServer.send(:public, *CreateServer.private_instance_methods)
    @action = CreateServer.new(nil, nil)
  end

  describe 'resolve_networks' do

    context 'with only ids of existing networks' do
      it 'return the ids array' do
        config.stub(:networks) { %w(net-id-1 net-id-2) }
        @action.resolve_networks(env).should eq(%w(net-id-1 net-id-2))
      end
    end

    context 'with only names of existing networks' do
      it 'return the ids array' do
        config.stub(:networks) { %w(net-1 net-2) }
        @action.resolve_networks(env).should eq(%w(net-id-1 net-id-2))
      end
    end

    context 'with only names and ids of existing networks' do
      it 'return the ids array' do
        config.stub(:networks) { %w(net-1 net-id-2) }
        @action.resolve_networks(env).should eq(%w(net-id-1 net-id-2))
      end
    end

    context 'with not existing networks' do
      it 'return the ids array' do
        config.stub(:networks) { %w(net-1 net-id-3) }
        expect { @action.resolve_networks(env) }.to raise_error
      end
    end

    context 'with no network returned by neutron and no network specified in vagrant provider' do
      it 'return the ids array' do
        neutron.stub(:get_private_networks).with(anything) { [] }
        config.stub(:networks) { [] }
        @action.resolve_networks(env).should eq([])
      end
    end

    context 'with no network returned by neutron and one network specified in vagrant provider' do
      it 'return the ids array' do
        neutron.stub(:get_private_networks).with(anything) { [] }
        config.stub(:networks) { ['net-id-1'] }
        expect { @action.resolve_networks(env) }.to raise_error
      end
    end

  end
end
