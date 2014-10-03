require 'vagrant-openstack-provider/spec_helper'
require 'ostruct'
require 'sshkey'

include VagrantPlugins::Openstack::Action
include VagrantPlugins::Openstack::HttpUtils
include VagrantPlugins::Openstack::Domain

describe VagrantPlugins::Openstack::Action::CreateServer do

  let(:config) do
    double('config').tap do |config|
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:server_name) { 'testName' }
      config.stub(:image) { 'ubuntu' }
      config.stub(:volume_boot) { nil }
      config.stub(:availability_zone) { nil }
      config.stub(:scheduler_hints) { nil }
      config.stub(:security_groups) { nil }
      config.stub(:user_data) { nil }
      config.stub(:metadata) { nil }
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
      env[:machine] = OpenStruct.new.tap do |m|
        m.provider_config = config
        m.id = nil
      end
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:nova) { nova }
    end
  end

  let(:resolver) do
    double('resolver').tap do |r|
      r.stub(:resolve_flavor).with(anything) do
        Flavor.new('flavor-01', 'small', nil, nil, nil)
      end
      r.stub(:resolve_image).with(anything) do
        Item.new('image-01', 'ubuntu')
      end
      r.stub(:resolve_volume_boot).with(anything) { 'ubuntu-drive' }
      r.stub(:resolve_networks).with(anything) { 'net-001' }
      r.stub(:resolve_volumes).with(anything) do
        [{ id: 'vol-01', device: nil }]
      end
      r.stub(:resolve_keypair).with(anything) { 'key' }
      r.stub(:resolve_floating_ip).with(anything) { '1.2.3.4' }
    end
  end

  let(:utils) do
    double('utils').tap do |u|
      u.stub(:get_ip_address) { '1.2.3.4' }
    end
  end

  before :each do
    CreateServer.send(:public, *CreateServer.private_instance_methods)
    app = double('app')
    app.stub(:call).with(anything)
    @action = CreateServer.new(app, nil, resolver, utils)
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
    context 'with full options' do
      it 'works' do
        allow(@action).to receive(:create_server).and_return('45678')
        allow(@action).to receive(:assign_floating_ip).and_return('1.2.3.4')
        allow(@action).to receive(:waiting_for_server_to_be_build)
        allow(@action).to receive(:attach_volumes)
        allow(@action).to receive(:waiting_for_server_to_be_reachable)

        expect(@action).to receive(:waiting_for_server_to_be_build).with(env, '45678')
        expect(@action).to receive(:assign_floating_ip).with(env, '45678').and_return('1.2.3.4')
        expect(@action).to receive(:attach_volumes).with(env, '45678', [{ id: 'vol-01', device: nil }])
        expect(@action).to receive(:waiting_for_server_to_be_reachable).with(env)

        @action.call(env)
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
