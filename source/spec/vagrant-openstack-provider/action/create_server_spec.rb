require 'vagrant-openstack-provider/spec_helper'
require 'sshkey'

include VagrantPlugins::Openstack::Action
include VagrantPlugins::Openstack::HttpUtils
include VagrantPlugins::Openstack::Domain

describe VagrantPlugins::Openstack::Action::CreateServer do

  let(:config) do
    double('config').tap do |config|
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:server_name) { 'testName' }
    end
  end

  let(:image) do
    double('image').tap do |image|
      image.stub(:name) { 'image_name' }
      image.stub(:id) { 'image123' }
    end
  end

  let(:flavor) do
    double('flavor').tap do |flavor|
      flavor.stub(:name) { 'flavor_name'  }
      flavor.stub(:id) { 'flavor123' }
    end
  end

  let(:nova) do
    double('nova')
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:nova) { nova }
    end
  end

  before :each do
    CreateServer.send(:public, *CreateServer.private_instance_methods)
    @action = CreateServer.new(nil, nil)
  end

  describe 'call' do
    context 'with both image and volume_boot specified' do
      it 'should raise an error' do
        config.stub(:image) { 'linux-image' }
        config.stub(:volume_boot) { 'linux-volume' }
        expect { @action.call(env) }.to raise_error Errors::ConflictBootOption
      end
    end
    context 'with neither image nor volume_boot specified' do
      it 'should raise an error' do
        config.stub(:image) { nil }
        config.stub(:volume_boot) { nil }
        expect { @action.call(env) }.to raise_error Errors::MissingBootOption
      end
    end
  end

  describe 'create_server' do
    context 'with all options specified' do
      it 'calls nova with all the options' do
        nova.stub(:create_server).with(
        env,
        name: 'testName',
        flavor_ref: flavor.id,
        image_ref: image.id,
        volume_boot: nil,
        networks: ['test-networks'],
        keypair: 'test-keypair',
        availability_zone: 'test-az',
        scheduler_hints: 'test-sched-hints',
        security_groups: ['test-sec-groups'],
        user_data: 'test-user_data',
        metadata: 'test-metadata') do '1234'
        end

        options = {
          flavor: flavor,
          image: image,
          networks: ['test-networks'],
          volumes: [{ id: '001', device: :auto }, { id: '002', device: '/dev/vdc' }],
          keypair_name: 'test-keypair',
          availability_zone: 'test-az',
          scheduler_hints: 'test-sched-hints',
          security_groups: ['test-sec-groups'],
          user_data: 'test-user_data',
          metadata: 'test-metadata'
        }

        expect(@action.create_server(env, options)).to eq '1234'
      end
    end
  end

  describe 'attach_volumes' do
    context 'with volume attached in all possible ways' do
      it 'returns normalized volume list' do
        nova.stub(:attach_volume).with(anything, anything, anything, anything) {}
        nova.should_receive(:attach_volume).with(env, 'server-01', '001', nil)
        nova.should_receive(:attach_volume).with(env, 'server-01', '002', '/dev/vdb')

        @action.attach_volumes(env, 'server-01', [{ id: '001', device: nil }, { id: '002', device: '/dev/vdb' }])
      end
    end
  end
end
