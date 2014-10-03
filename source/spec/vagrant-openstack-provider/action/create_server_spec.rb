require 'vagrant-openstack-provider/spec_helper'
require 'sshkey'

include VagrantPlugins::Openstack::Action
include VagrantPlugins::Openstack::HttpUtils
include VagrantPlugins::Openstack::Domain

describe VagrantPlugins::Openstack::Action::CreateServer do
  include FakeFS::SpecHelpers

  let(:config) do
    double('config').tap do |config|
      config.stub(:openstack_auth_url) { 'http://keystoneAuthV2' }
      config.stub(:openstack_compute_url) { nil }
      config.stub(:openstack_network_url) { nil }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
      config.stub(:server_name) { 'testName' }
      config.stub(:availability_zone) { 'AZ-01' }
      config.stub(:floating_ip) { nil }
      config.stub(:floating_ip_pool) { nil }
      config.stub(:keypair_name) { nil }
      config.stub(:public_key_path) { nil }
      config.stub(:networks) { nil }
    end
  end

  let(:image) do
    double('image').tap do |image|
      image.stub(:name) { 'image_name' }
      image.stub(:id) { 'image123' }
    end
  end

  let(:ssh_key) do
    double('ssh_key').tap do |key|
      key.stub(:ssh_public_key) { 'ssh public key' }
      key.stub(:private_key) { 'private key' }
    end
  end

  let(:flavor) do
    double('flavor').tap do |flavor|
      flavor.stub(:name) { 'flavor_name'  }
      flavor.stub(:id) { 'flavor123' }
    end
  end

  let(:neutron) do
    double('neutron').tap do |neutron|
      neutron.stub(:get_private_networks).with(anything) do
        [Item.new('net-id-1', 'net-1'), Item.new('net-id-2', 'net-2')]
      end
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
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:machine].stub(:data_dir) { '/data/dir' }
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:neutron) { neutron }
      env[:openstack_client].stub(:nova) { nova }
    end
  end

  before :each do
    CreateServer.send(:public, *CreateServer.private_instance_methods)
    @action = CreateServer.new(nil, nil)
  end

  describe 'create_server' do
    context 'with all options specified' do
      it 'calls nova with all the options' do
        nova.stub(:create_server).with(
        env,
        name: 'testName',
        flavor_ref: flavor.id,
        image_ref: image.id,
        networks: ['test-networks'],
        keypair: 'test-keypair',
        availability_zone: 'test-az') do '1234'
        end

        options = {
          flavor: flavor,
          image: image,
          networks: ['test-networks'],
          keypair_name: 'test-keypair',
          availability_zone: 'test-az'
        }
        expect(@action.create_server(env, options)).to eq '1234'
      end
    end
  end

  describe 'resolve_floating_ip' do
    context 'with config.floating_ip specified' do
      it 'return the specified floating ip' do
        config.stub(:floating_ip) { '80.80.80.80' }
        @action.resolve_floating_ip(env).should eq('80.80.80.80')
      end
    end

    context 'with config.floating_pool specified' do
      context 'if any ip in the same pool is available' do
        it 'return one of the available ips' do
          nova.stub(:get_all_floating_ips).with(anything) do
            [FloatingIP.new('80.81.82.84', 'pool-1', '1234'),
             FloatingIP.new('80.81.82.83', 'pool-1', nil)]
          end
          config.stub(:floating_ip_pool) { 'pool-1' }
          @action.resolve_floating_ip(env).should eq('80.81.82.83')
        end
      end

      context 'if no ip in the same pool is available' do
        it 'allocate a new floating_ip from the pool' do
          nova.stub(:get_all_floating_ips).with(anything) do
            [FloatingIP.new('80.81.82.83', 'pool-1', '1234')]
          end
          nova.stub(:allocate_floating_ip).with(env, 'pool-1') do
            FloatingIP.new('80.81.82.84', 'pool-1', nil)
          end
          config.stub(:floating_ip_pool) { 'pool-1' }
          @action.resolve_floating_ip(env).should eq('80.81.82.84')
        end
      end
    end

    context 'with neither floating_ip nor floating_ip_pool' do
      context 'if any ip is not associated with an instance' do
        it 'return the available ip in the list of floating ips' do
          nova.stub(:get_all_floating_ips).with(anything) do
            [FloatingIP.new('80.81.82.84', 'pool-1', '1234'), FloatingIP.new('80.81.82.83', 'pool-1', nil)]
          end
          @action.resolve_floating_ip(env).should eq('80.81.82.83')
        end
      end

      context 'if all ips are already associated with an instance' do
        it 'fails with an UnableToResolveFloatingIP error' do
          nova.stub(:get_all_floating_ips).with(anything) do
            [FloatingIP.new('80.81.82.84', 'pool-1', '1234'), FloatingIP.new('80.81.82.83', 'pool-1', '2345')]
          end
          expect { @action.resolve_floating_ip(env) }.to raise_error(Errors::UnableToResolveFloatingIP)
        end
      end
    end
  end

  describe 'resolve_keypair' do
    context 'with keypair_name provided' do
      it 'return the provided keypair_name' do
        config.stub(:keypair_name) { 'my-keypair' }
        @action.resolve_keypair(env).should eq('my-keypair')
      end
    end

    context 'with keypair_name and public_key_path provided' do
      it 'return the provided keypair_name' do
        config.stub(:keypair_name) { 'my-keypair' }
        config.stub(:public_key_path) { '/path/to/key' }
        @action.resolve_keypair(env).should eq('my-keypair')
      end
    end

    context 'with public_key_path provided' do
      it 'return the keypair_name created into nova' do
        config.stub(:public_key_path) { '/path/to/key' }
        nova.stub(:import_keypair_from_file).with(env, '/path/to/key') { 'my-keypair-imported' }
        @action.resolve_keypair(env).should eq('my-keypair-imported')
      end
    end

    context 'with no keypair_name and no public_key_path provided' do
      it 'generates a new keypair and return the keypair name imported into nova' do
        config.stub(:keypair_name) { nil }
        config.stub(:public_key_path) { nil }
        @action.stub(:generate_keypair) { 'my-keypair-imported' }
        @action.resolve_keypair(env).should eq('my-keypair-imported')
      end
    end
  end

  describe 'generate_keypair' do
    it 'returns a generated keypair name imported into nova' do
      nova.stub(:import_keypair) { 'my-keypair-imported' }
      SSHKey.stub(:generate) { ssh_key }
      File.should_receive(:write).with('/data/dir/my-keypair-imported', 'private key')
      File.should_receive(:chmod).with(0600, '/data/dir/my-keypair-imported')
      @action.generate_keypair(env).should eq('my-keypair-imported')
    end
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
