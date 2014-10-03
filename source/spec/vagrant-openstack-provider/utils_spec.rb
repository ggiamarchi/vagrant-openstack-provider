require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Utils do

  let(:config) do
    double('config').tap do |config|
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:server_name) { 'testName' }
      config.stub(:floating_ip) { nil }
    end
  end

  let(:nova) do
    double('nova').tap do |nova|
      nova.stub(:get_all_floating_ips).with(anything) do
        [FloatingIP.new('80.81.82.83', 'pool-1', nil), FloatingIP.new('30.31.32.33', 'pool-2', '1234')]
      end
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:machine].stub(:id) { '1234id' }
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:nova) { nova }
    end
  end

  before :each do
    Utils.send(:public, *Utils.private_instance_methods)
    @action = Utils.new
  end

  describe 'get_ip_address' do
    context 'without config.floating_ip' do
      context 'with floating ip in nova details' do
        it 'returns floating_ip from nova details' do
          config.stub(:floating_ip) { nil }
          nova.stub(:get_server_details).with(env, '1234id') do
            {
              'addresses' => {
                'toto' => [{
                  'addr' => '13.13.13.13'
                }, {
                  'addr' => '12.12.12.12',
                  'OS-EXT-IPS:type' => 'floating'
                }]
              }
            }
          end
          @action.get_ip_address(env).should eq('12.12.12.12')
        end
      end

      context 'without floating ip in nova details' do
        it 'fails' do
          config.stub(:floating_ip) { nil }
          nova.stub(:get_server_details).with(env, '1234id') do
            {
              'addresses' => {
                'toto' => [{
                  'addr' => '13.13.13.13'
                }, {
                  'addr' => '12.12.12.12',
                  'OS-EXT-IPS:type' => 'private'
                }]
              }
            }
          end
          expect { @action.get_ip_address(env) }.to raise_error(Errors::UnableToResolveIP)
        end
      end
    end

    context 'with config.floating_ip' do
      it 'returns floating_ip' do
        config.stub(:floating_ip) { '1.2.3.4' }
        @action.get_ip_address(env).should eq('1.2.3.4')
      end
    end
  end
end
