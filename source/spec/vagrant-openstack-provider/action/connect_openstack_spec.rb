require 'vagrant-openstack-provider/spec_helper'

include VagrantPlugins::Openstack::Action
include VagrantPlugins::Openstack::HttpUtils

describe VagrantPlugins::Openstack::Action::ConnectOpenstack do

  let(:app) do
    double.tap do |app|
      app.stub(:call)
    end
  end

  let(:config) do
    double.tap do |config|
      config.stub(:openstack_auth_url) { 'http://keystoneAuthV2' }
      config.stub(:openstack_compute_url) { nil }
      config.stub(:openstack_network_url) { nil }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
    end
  end

  let(:neutron) do
    double.tap do |neutron|
      neutron.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v2.0',
            'links' => [
              {
                'href' => 'http://neutron/v2.0',
                'rel' => 'self'
              }
            ]
          }
        ]
      end
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double
      env[:ui].stub(:info).with(anything)
      env[:ui].stub(:warn).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:neutron) { neutron }
    end
  end

  before(:all) do
    ConnectOpenstack.send(:public, *ConnectOpenstack.private_instance_methods)
  end

  before :each do
    VagrantPlugins::Openstack.session.reset
    @action = ConnectOpenstack.new(app, env)
  end

  describe 'ConnectOpenstack' do
    context 'with one endpoint by service' do
      it 'read service catalog and stores endpoints URL in session' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://nova/v2/projectId',
                'id' => '1'
              }
            ],
            'type' => 'compute',
            'name' => 'nova'
          },
          {
            'endpoints' => [
              {
                'publicURL' => 'http://neutron',
                'id' => '2'
              }
            ],
            'type' => 'network',
            'name' => 'neutron'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:openstack_client].stub(:keystone) { keystone }
        end
        env[:openstack_client].stub(:neutron) { neutron }

        @action.call(env)

        expect(env[:openstack_client].session.endpoints)
          .to eq(compute: 'http://nova/v2/projectId', network: 'http://neutron/v2.0')
      end
    end

    context 'with multiple endpoints for a service' do
      it 'takes the first one' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://neutron/alt',
                'id' => '2'
              },
              {
                'publicURL' => 'http://neutron',
                'id' => '3'
              }
            ],
            'type' => 'network',
            'name' => 'neutron'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:openstack_client].stub(:keystone) { keystone }
        end
        env[:openstack_client].stub(:neutron) { neutron }

        @action.call(env)

        expect(env[:openstack_client].session.endpoints).to eq(network: 'http://neutron/v2.0')
      end
    end

    context 'with multiple versions for network service' do

      let(:neutron) do
        double.tap do |neutron|
          neutron.stub(:get_api_version_list).with(anything) do
            [
              {
                'status' => 'CURRENT',
                'id' => 'v2.0',
                'links' => [
                  {
                    'href' => 'http://neutron/v2.0',
                    'rel' => 'self'
                  }
                ]
              },
              {
                'status' => '...',
                'id' => 'v1.0',
                'links' => [
                  {
                    'href' => 'http://neutron/v1.0',
                    'rel' => 'self'
                  }
                ]
              }
            ]
          end
        end
      end

      it 'raise a MultipleApiVersion error' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://neutron',
                'id' => '3'
              }
            ],
            'type' => 'network',
            'name' => 'neutron'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:openstack_client].stub(:keystone) { keystone }
        end
        env[:openstack_client].stub(:neutron) { neutron }

        expect { @action.call(env) }.to raise_error(Errors::MultipleApiVersion)
      end
    end
  end
end
