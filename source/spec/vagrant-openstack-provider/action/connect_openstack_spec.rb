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
      config.stub(:openstack_volume_url) { nil }
      config.stub(:openstack_image_url) { nil }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
      config.stub(:region) { nil }
      config.stub(:endpoint_type) { 'publicURL' }
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

  let(:neutron_admin_url) do
    double.tap do |neutron|
      neutron.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v2.0',
            'links' => [
              {
                'href' => 'http://neutron/v2.0/admin',
                'rel' => 'self'
              }
            ]
          }
        ]
      end
    end
  end

  let(:neutron_france) do
    double.tap do |neutron|
      neutron.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v2.0',
            'links' => [
              {
                'href' => 'http://france.neutron/v2.0',
                'rel' => 'self'
              }
            ]
          }
        ]
      end
    end
  end

  let(:glance) do
    double.tap do |glance|
      glance.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v2.1',
            'links' => [
              {
                'href' => 'http://glance/v2.0',
                'rel' => 'self'
              }
            ]
          }
        ]
      end
    end
  end

  let(:glance_admin_url) do
    double.tap do |glance|
      glance.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v2.1',
            'links' => [
              {
                'href' => 'http://glance/v2.0/admin',
                'rel' => 'self'
              }
            ]
          }
        ]
      end
    end
  end

  let(:glance_v1) do
    double.tap do |glance|
      glance.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v1.0',
            'links' => [
              {
                'href' => 'http://glance/v1',
                'rel' => 'self'
              }
            ]
          }
        ]
      end
    end
  end

  let(:glance_france) do
    double.tap do |glance|
      glance.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v2.1',
            'links' => [
              {
                'href' => 'http://france.glance/v2.0',
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
      env[:openstack_client].stub(:glance) { glance }
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
      it 'read service catalog and stores endpoints URL in session', :focus do
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
          },
          {
            'endpoints' => [
              {
                'publicURL' => 'http://cinder/v2/projectId',
                'id' => '2'
              }
            ],
            'type' => 'volume',
            'name' => 'cinder'
          },
          {
            'endpoints' => [
              {
                'publicURL' => 'http://glance',
                'id' => '2'
              }
            ],
            'type' => 'image',
            'name' => 'glance'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:openstack_client].stub(:keystone) { keystone }
        end
        env[:openstack_client].stub(:neutron)  { neutron }
        env[:openstack_client].stub(:glance)   { glance }

        @action.call(env)

        expect(env[:openstack_client].session.endpoints)
          .to eq(compute: 'http://nova/v2/projectId',
                 network: 'http://neutron/v2.0',
                 volume:  'http://cinder/v2/projectId',
                 image:   'http://glance/v2.0')
      end
    end

    context 'with multiple regions' do
      it 'read service catalog and stores endpoints URL for desired regions in session' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://france.nova/v2/projectId',
                'id' => '1',
                'region' => 'france'
              },
              {
                'publicURL' => 'http://us.nova/v2/projectId',
                'id' => '4',
                'region' => 'us'
              }
            ],
            'type' => 'compute',
            'name' => 'nova'
          },
          {
            'endpoints' => [
              {
                'publicURL' => 'http://france.neutron',
                'id' => '2',
                'region' => 'france'
              },
              {
                'publicURL' => 'http://us.neutron',
                'id' => '5',
                'region' => 'us'
              }
            ],
            'type' => 'network',
            'name' => 'neutron'
          },
          {
            'endpoints' => [
              {
                'publicURL' => 'http://france.glance',
                'id' => '3',
                'region' => 'france'
              },
              {
                'publicURL' => 'http://us.glance',
                'id' => '6',
                'region' => 'us'
              }
            ],
            'type' => 'image',
            'name' => 'glance'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:openstack_client].stub(:keystone) { keystone }
        end

        env[:openstack_client].stub(:neutron)  { neutron_france }
        env[:openstack_client].stub(:glance)   { glance_france }
        config.stub(:region) { 'france' }

        @action.call(env)

        expect(env[:openstack_client].session.endpoints)
        .to eq(compute: 'http://france.nova/v2/projectId',
               network: 'http://france.neutron/v2.0',
               image:   'http://france.glance/v2.0')
      end
    end

    context 'with multiple endpoints for a service' do
      it 'takes the first one' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://nova',
                'id' => '1'
              }
            ],
            'type' => 'compute',
            'name' => 'nova'
          },
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

        expect(env[:openstack_client].session.endpoints).to eq(compute: 'http://nova', network: 'http://neutron/v2.0')
      end
    end

    describe 'endpoint_type' do
      context 'with adminURL specified' do
        it 'read service catalog and stores endpoints URL in session' do
          catalog = [
            {
              'endpoints' => [
                {
                  'publicURL' => 'http://nova/v2/projectId',
                  'adminURL' => 'http://nova/v2/projectId/admin',
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
                  'adminURL' => 'http://neutron/admin',
                  'id' => '2'
                }
              ],
              'type' => 'network',
              'name' => 'neutron'
            },
            {
              'endpoints' => [
                {
                  'publicURL' => 'http://cinder/v2/projectId',
                  'adminURL' => 'http://cinder/v2/projectId/admin',
                  'id' => '2'
                }
              ],
              'type' => 'volume',
              'name' => 'cinder'
            },
            {
              'endpoints' => [
                {
                  'publicURL' => 'http://glance',
                  'adminURL' => 'http://glance/admin',
                  'id' => '2'
                }
              ],
              'type' => 'image',
              'name' => 'glance'
            }
          ]

          double.tap do |keystone|
            keystone.stub(:authenticate).with(anything) { catalog }
            env[:openstack_client].stub(:keystone) { keystone }
          end
          env[:openstack_client].stub(:neutron)  { neutron_admin_url }
          env[:openstack_client].stub(:glance)   { glance_admin_url }
          config.stub(:endpoint_type) { 'adminURL' }

          @action.call(env)

          expect(env[:openstack_client].session.endpoints)
          .to eq(compute: 'http://nova/v2/projectId/admin',
                 network: 'http://neutron/v2.0/admin',
                 volume:  'http://cinder/v2/projectId/admin',
                 image:   'http://glance/v2.0/admin')
        end
      end
    end

    describe 'endpoint_type' do
      context 'with internalURL specified' do
        it 'read service catalog and stores endpoints URL in session' do
          catalog = [
            {
              'endpoints' => [
                {
                  'publicURL' => 'http://nova/v2/projectId',
                  'adminURL' => 'http://nova/v2/projectId/admin',
                  'internalURL' => 'http://nova/v2/projectId/internal',
                  'id' => '1'
                }
              ],
              'type' => 'compute',
              'name' => 'nova'
            },
            {
              'endpoints' => [
                {
                  'publicURL' => 'http://cinder/v2/projectId',
                  'adminURL' => 'http://cinder/v2/projectId/admin',
                  'internalURL' => 'http://cinder/v2/projectId/internal',
                  'id' => '2'
                }
              ],
              'type' => 'volume',
              'name' => 'cinder'
            }
          ]

          double.tap do |keystone|
            keystone.stub(:authenticate).with(anything) { catalog }
            env[:openstack_client].stub(:keystone) { keystone }
          end
          config.stub(:endpoint_type) { 'internalURL' }

          @action.call(env)

          expect(env[:openstack_client].session.endpoints)
          .to eq(compute: 'http://nova/v2/projectId/internal',
                 volume:  'http://cinder/v2/projectId/internal')
        end
      end
    end

    describe 'endpoint_type' do
      context 'with publicURL specified' do
        it 'read service catalog and stores endpoints URL in session' do
          catalog = [
            {
              'endpoints' => [
                {
                  'publicURL' => 'http://nova/v2/projectId',
                  'adminURL' => 'http://nova/v2/projectId/admin',
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
                  'adminURL' => 'http://neutron/admin',
                  'id' => '2'
                }
              ],
              'type' => 'network',
              'name' => 'neutron'
            },
            {
              'endpoints' => [
                {
                  'publicURL' => 'http://cinder/v2/projectId',
                  'adminURL' => 'http://cinder/v2/projectId/admin',
                  'id' => '2'
                }
              ],
              'type' => 'volume',
              'name' => 'cinder'
            },
            {
              'endpoints' => [
                {
                  'publicURL' => 'http://glance',
                  'adminURL' => 'http://glance/admin',
                  'id' => '2'
                }
              ],
              'type' => 'image',
              'name' => 'glance'
            }
          ]

          double.tap do |keystone|
            keystone.stub(:authenticate).with(anything) { catalog }
            env[:openstack_client].stub(:keystone) { keystone }
          end
          env[:openstack_client].stub(:neutron)  { neutron }
          env[:openstack_client].stub(:glance)   { glance }
          config.stub(:endpoint_type) { 'publicURL' }

          @action.call(env)

          expect(env[:openstack_client].session.endpoints)
          .to eq(compute: 'http://nova/v2/projectId',
                 network: 'http://neutron/v2.0',
                 volume:  'http://cinder/v2/projectId',
                 image:   'http://glance/v2.0')
        end
      end
    end

    context 'with glance v1 only' do
      it 'read service catalog and stores endpoints URL in session', :focus do
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
                'publicURL' => 'http://glance',
                'id' => '2'
              }
            ],
            'type' => 'image',
            'name' => 'glance'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:openstack_client].stub(:keystone) { keystone }
        end
        env[:openstack_client].stub(:glance) { glance_v1 }

        @action.call(env)

        expect(env[:openstack_client].session.endpoints)
        .to eq(compute: 'http://nova/v2/projectId',
               image:   'http://glance/v1')
      end
    end

    context 'with nova endpoint missing' do
      it 'raise an error' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://keystone',
                'id' => '1'
              }
            ],
            'type' => 'identity',
            'name' => 'keystone'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:openstack_client].stub(:keystone) { keystone }
        end

        expect { @action.call(env) }.to raise_error Errors::MissingNovaEndpoint
      end
    end

    context 'with no matching versions for network service' do

      let(:neutron) do
        double.tap do |neutron|
          neutron.stub(:get_api_version_list).with(anything) do
            [
              {
                'status' => 'CURRENT',
                'id' => 'v1.1',
                'links' => [
                  {
                    'href' => 'http://neutron/v1.1',
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

      it 'raise an error' do
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

        expect { @action.call(env) }.to raise_error(Errors::NoMatchingApiVersion)
      end
    end

    context 'with only keystone and nova' do
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
                'publicURL' => 'http://keystone/v2.0',
                'id' => '2'
              }
            ],
            'type' => 'identity',
            'name' => 'keystone'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:openstack_client].stub(:keystone) { keystone }
        end

        @action.call(env)

        expect(env[:openstack_client].session.endpoints)
        .to eq(compute: 'http://nova/v2/projectId', identity: 'http://keystone/v2.0')
      end
    end
  end
end
