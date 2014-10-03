require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::ConfigResolver do

  let(:config) do
    double('config').tap do |config|
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:server_name) { 'testName' }
      config.stub(:floating_ip) { nil }
      config.stub(:floating_ip_pool) { nil }
      config.stub(:floating_ip_pool_always_allocate) { false }
      config.stub(:keypair_name) { nil }
      config.stub(:public_key_path) { nil }
      config.stub(:networks) { nil }
      config.stub(:volumes) { nil }
    end
  end

  let(:ssh_key) do
    double('ssh_key').tap do |key|
      key.stub(:ssh_public_key) { 'ssh public key' }
      key.stub(:private_key) { 'private key' }
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

  let(:cinder) do
    double('cinder').tap do |cinder|
      cinder.stub(:get_all_volumes).with(anything) do
        [Volume.new('001', 'vol-01', '1', 'available', 'true', nil, nil),
         Volume.new('002', 'vol-02', '2', 'available', 'true', nil, nil),
         Volume.new('003', 'vol-03', '3', 'available', 'true', nil, nil),
         Volume.new('004', 'vol-04', '4', 'available', 'false', nil, nil),
         Volume.new('005', 'vol-05', '5', 'available', 'false', nil, nil),
         Volume.new('006', 'vol-06', '6', 'available', 'false', nil, nil),
         Volume.new('007', 'vol-07-08', '6', 'available', 'false', nil, nil),
         Volume.new('008', 'vol-07-08', '6', 'available', 'false', nil, nil)]
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
      env[:machine].stub(:config) { machine_config }
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:neutron) { neutron }
      env[:openstack_client].stub(:nova) { nova }
      env[:openstack_client].stub(:cinder) { cinder }
    end
  end

  let(:ssh_config) do
    double('ssh_config').tap do |config|
      config.stub(:username) { nil }
      config.stub(:port) { nil }
    end
  end

  let(:machine_config) do
    double('machine_config').tap do |config|
      config.stub(:ssh) { ssh_config }
    end
  end

  before :each do
    ConfigResolver.send(:public, *ConfigResolver.private_instance_methods)
    @action = ConfigResolver.new
  end

  describe 'resolve_ssh_username' do
    context 'with machine.ssh.username' do
      it 'returns machine.ssh.username' do
        ssh_config.stub(:username) { 'machine ssh username' }
        config.stub(:ssh_username) { nil }
        expect(@action.resolve_ssh_username(env)).to eq('machine ssh username')
      end
    end
    context 'with machine.ssh.username and config.ssh_username' do
      it 'returns machine.ssh.username' do
        ssh_config.stub(:username) { 'machine ssh username' }
        config.stub(:ssh_username) { 'provider ssh username' }
        expect(@action.resolve_ssh_username(env)).to eq('machine ssh username')
      end
    end
    context 'with config.ssh_username' do
      it 'returns config.ssh_username' do
        ssh_config.stub(:username) { nil }
        config.stub(:ssh_username) { 'provider ssh username' }
        expect(@action.resolve_ssh_username(env)).to eq('provider ssh username')
      end
    end
    context 'with no ssh username config' do
      it 'fails' do
        ssh_config.stub(:username) { nil }
        config.stub(:ssh_username) { nil }
        expect { @action.resolve_ssh_username(env) }.to raise_error(Errors::NoMatchingSshUsername)
      end
    end
  end

  describe 'resolve_flavor' do
    context 'with id' do
      it 'returns the specified flavor' do
        config.stub(:flavor) { 'fl-001' }
        nova.stub(:get_all_flavors).with(anything) do
          [Flavor.new('fl-001', 'flavor-01', 2, 1024, 10),
           Flavor.new('fl-002', 'flavor-02', 4, 2048, 50)]
        end
        @action.resolve_flavor(env).should eq(Flavor.new('fl-001', 'flavor-01', 2, 1024, 10))
      end
    end
    context 'with name' do
      it 'returns the specified flavor' do
        config.stub(:flavor) { 'flavor-02' }
        nova.stub(:get_all_flavors).with(anything) do
          [Flavor.new('fl-001', 'flavor-01', 2, 1024, 10),
           Flavor.new('fl-002', 'flavor-02', 4, 2048, 50)]
        end
        @action.resolve_flavor(env).should eq(Flavor.new('fl-002', 'flavor-02', 4, 2048, 50))
      end
    end
    context 'with invalid identifier' do
      it 'raise an error' do
        config.stub(:flavor) { 'not-existing' }
        nova.stub(:get_all_flavors).with(anything) do
          [Flavor.new('fl-001', 'flavor-01', 2, 1024, 10),
           Flavor.new('fl-002', 'flavor-02', 4, 2048, 50)]
        end
        expect { @action.resolve_flavor(env) }.to raise_error(Errors::NoMatchingFlavor)
      end
    end
  end

  describe 'resolve_image' do
    context 'with id' do
      it 'returns the specified flavor' do
        config.stub(:image) { 'img-001' }
        nova.stub(:get_all_images).with(anything) do
          [Item.new('img-001', 'image-01'),
           Item.new('img-002', 'image-02')]
        end
        @action.resolve_image(env).should eq(Item.new('img-001', 'image-01'))
      end
    end
    context 'with name' do
      it 'returns the specified flavor' do
        config.stub(:image) { 'image-02' }
        nova.stub(:get_all_images).with(anything) do
          [Item.new('img-001', 'image-01'),
           Item.new('img-002', 'image-02')]
        end
        @action.resolve_image(env).should eq(Item.new('img-002', 'image-02'))
      end
    end
    context 'with invalid identifier' do
      it 'raise an error' do
        config.stub(:image) { 'not-existing' }
        nova.stub(:get_all_images).with(anything) do
          [Item.new('img-001', 'image-01'),
           Item.new('img-002', 'image-02')]
        end
        expect { @action.resolve_image(env) }.to raise_error(Errors::NoMatchingImage)
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
        context 'with config.floating_pool_always_allocate true' do
          it 'allocate a new floating_ip from the pool' do
            config.stub(:floating_ip_pool_always_allocate) { true }
            nova.stub(:get_all_floating_ips).with(anything) do
              [FloatingIP.new('80.81.82.84', 'pool-1', '1234'),
               FloatingIP.new('80.81.82.83', 'pool-1', nil)]
            end
            nova.stub(:allocate_floating_ip).with(env, 'pool-1') do
              FloatingIP.new('80.81.82.84', 'pool-1', nil)
            end
            config.stub(:floating_ip_pool) { 'pool-1' }
            @action.resolve_floating_ip(env).should eq('80.81.82.84')
          end
        end

        context 'with config.floating_pool_always_allocate false' do
          it 'return one of the available ips' do
            config.stub(:floating_ip_pool_always_allocate) { false }
            nova.stub(:get_all_floating_ips).with(anything) do
              [FloatingIP.new('80.81.82.84', 'pool-1', '1234'),
               FloatingIP.new('80.81.82.83', 'pool-1', nil)]
            end
            config.stub(:floating_ip_pool) { 'pool-1' }
            @action.resolve_floating_ip(env).should eq('80.81.82.83')
          end
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
      it 'fails with an UnableToResolveFloatingIP error' do
        config.stub(:floating_ip) { nil }
        config.stub(:floating_ip_pool) { nil }
        expect { @action.resolve_floating_ip(env) }.to raise_error(Errors::UnableToResolveFloatingIP)
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

  describe 'resolve_volume_boot' do
    context 'with string volume id' do
      it 'returns normalized volume' do
        config.stub(:volume_boot) { '001' }
        expect(@action.resolve_volume_boot(env)).to eq id: '001', device: 'vda'
      end
    end

    context 'with string volume name' do
      it 'returns normalized volume' do
        config.stub(:volume_boot) { 'vol-01' }
        expect(@action.resolve_volume_boot(env)).to eq id: '001', device: 'vda'
      end
    end

    context 'with hash volume id' do
      it 'returns normalized volume' do
        config.stub(:volume_boot) { { id: '001' } }
        expect(@action.resolve_volume_boot(env)).to eq id: '001', device: 'vda'
      end
    end

    context 'with hash volume name' do
      it 'returns normalized volume' do
        config.stub(:volume_boot) { { name: 'vol-01' } }
        expect(@action.resolve_volume_boot(env)).to eq id: '001', device: 'vda'
      end
    end

    context 'with hash volume id and device' do
      it 'returns normalized volume' do
        config.stub(:volume_boot) { { id: '001', device: 'vdb' } }
        expect(@action.resolve_volume_boot(env)).to eq id: '001', device: 'vdb'
      end
    end

    context 'with hash volume name and device' do
      it 'returns normalized volume' do
        config.stub(:volume_boot) { { name: 'vol-01', device: 'vdb' } }
        expect(@action.resolve_volume_boot(env)).to eq id: '001', device: 'vdb'
      end
    end

    context 'with empty hash' do
      it 'raises an error' do
        config.stub(:volume_boot) { {} }
        expect { @action.resolve_volume_boot(env) }.to raise_error(Errors::ConflictVolumeNameId)
      end
    end

    context 'with invalid volume object' do
      it 'raises an error' do
        config.stub(:volume_boot) { 1 }
        expect { @action.resolve_volume_boot(env) }.to raise_error(Errors::InvalidVolumeObject)
      end
    end

    context 'with hash containing a bad id' do
      it 'raises an error' do
        config.stub(:volume_boot) { { id: 'not-exist' } }
        expect { @action.resolve_volume_boot(env) }.to raise_error(Errors::UnresolvedVolumeId)
      end
    end

    context 'with hash containing a bad name' do
      it 'raises an error' do
        config.stub(:volume_boot) { { name: 'not-exist' } }
        expect { @action.resolve_volume_boot(env) }.to raise_error(Errors::UnresolvedVolumeName)
      end
    end

    context 'with hash containing both id and name' do
      it 'raises an error' do
        config.stub(:volume_boot) { { id: '001', name: 'vol-01' } }
        expect { @action.resolve_volume_boot(env) }.to raise_error(Errors::ConflictVolumeNameId)
      end
    end

    context 'with hash containing a name matching more than one volume' do
      it 'raises an error' do
        config.stub(:volume_boot) { { name: 'vol-07-08' } }
        expect { @action.resolve_volume_boot(env) }.to raise_error(Errors::MultipleVolumeName)
      end
    end
  end

  describe 'resolve_volumes' do
    context 'with volume attached in all possible ways' do
      it 'returns normalized volume list' do

        config.stub(:volumes) do
          ['001',
           'vol-02',
           { id: '003', device: '/dev/vdz' },
           { name: 'vol-04', device: '/dev/vdy' },
           { name: 'vol-05' },
           { id: '006' }]
        end

        expect(@action.resolve_volumes(env)).to eq [{ id: '001', device: nil },
                                                    { id: '002', device: nil },
                                                    { id: '003', device: '/dev/vdz' },
                                                    { id: '004', device: '/dev/vdy' },
                                                    { id: '005', device: nil },
                                                    { id: '006', device: nil }]
      end
    end

    context 'with invalid volume object' do
      it 'raises an error' do
        config.stub(:volumes) { [1] }
        expect { @action.resolve_volumes(env) }.to raise_error(Errors::InvalidVolumeObject)
      end
    end

    context 'with string that is neither an id nor name matching a volume' do
      it 'raises an error' do
        config.stub(:volumes) { ['not-exist'] }
        expect { @action.resolve_volumes(env) }.to raise_error(Errors::UnresolvedVolume)
      end
    end

    context 'with hash containing a bad id' do
      it 'raises an error' do
        config.stub(:volumes) { [{ id: 'not-exist' }] }
        expect { @action.resolve_volumes(env) }.to raise_error(Errors::UnresolvedVolumeId)
      end
    end

    context 'with hash containing a bad name' do
      it 'raises an error' do
        config.stub(:volumes) { [{ name: 'not-exist' }] }
        expect { @action.resolve_volumes(env) }.to raise_error(Errors::UnresolvedVolumeName)
      end
    end

    context 'with empty hash' do
      it 'raises an error' do
        config.stub(:volumes) { [{}] }
        expect { @action.resolve_volumes(env) }.to raise_error(Errors::ConflictVolumeNameId)
      end
    end

    context 'with hash containing both id and name' do
      it 'raises an error' do
        config.stub(:volumes) { [{ id: '001', name: 'vol-01' }] }
        expect { @action.resolve_volumes(env) }.to raise_error(Errors::ConflictVolumeNameId)
      end
    end

    context 'with hash containing both id and name' do
      it 'raises an error' do
        config.stub(:volumes) { [{ id: '001', name: 'vol-01' }] }
        expect { @action.resolve_volumes(env) }.to raise_error(Errors::ConflictVolumeNameId)
      end
    end

    context 'with hash containing a name matching more than one volume' do
      it 'raises an error' do
        config.stub(:volumes) { [{ name: 'vol-07-08' }] }
        expect { @action.resolve_volumes(env) }.to raise_error(Errors::MultipleVolumeName)
      end
    end
  end
end
