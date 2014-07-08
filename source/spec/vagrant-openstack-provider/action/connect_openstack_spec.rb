require 'vagrant-openstack-provider/spec_helper'

include VagrantPlugins::Openstack::Action
include VagrantPlugins::Openstack::Utils

describe VagrantPlugins::Openstack::Action::ConnectOpenstack do

  let(:app) do
    double.tap do |app|
      app.stub(:call)
    end
  end

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
      neutron.stub(:get_api_version_list).with(anything) do
        {

        }
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
    ConnectOpenstack.send(:public, *ConnectOpenstack.private_instance_methods)
    @action = ConnectOpenstack.new(app, env)
  end

  describe 'resolve_networks' do

    context 'with only ids of existing networks' do
      it 'return the ids array' do
        #        config.stub(:networks) { %w(net-id-1 net-id-2) }
        #        @action.resolve_networks(env).should eq(%w(net-id-1 net-id-2))
      end
    end

  end
end
