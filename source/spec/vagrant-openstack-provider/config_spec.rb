require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Config do
  describe 'defaults' do
    let(:vagrant_public_key) { Vagrant.source_root.join('keys/vagrant.pub') }

    subject do
      super().tap(&:finalize!)
    end

    its(:password)  { should be_nil }
    its(:openstack_compute_url) { should be_nil }
    its(:openstack_auth_url) { should be_nil }
    its(:openstack_orchestration_url) { should be_nil }
    its(:flavor)   { should be_nil }
    its(:image)    { should be_nil }
    its(:server_name) { should be_nil }
    its(:username) { should be_nil }
    its(:use_legacy_synced_folders) { should eq(false) }
    its(:rsync_includes) { should be_nil }
    its(:rsync_ignore_files) { should be_nil }
    its(:sync_method) { should be_nil }
    its(:keypair_name) { should be_nil }
    its(:public_key_path) { should be_nil }
    its(:availability_zone) { should be_nil }
    its(:ssh_username) { should be_nil }
    its(:floating_ip_pool_always_allocate) { should eq(false) }
    its(:scheduler_hints) { should be_nil }
    its(:security_groups) { should be_nil }
    its(:user_data) { should be_nil }
    its(:metadata) { should be_nil }
    its(:ssl_ca_file) { should eq nil }
    its(:ip_version) { should be_nil }
  end

  describe 'overriding defaults' do
    [
      :password,
      :openstack_compute_url,
      :openstack_auth_url,
      :flavor,
      :image,
      :server_name,
      :username,
      :keypair_name,
      :ssh_username,
      :floating_ip_pool_always_allocate,
      :scheduler_hints,
      :security_groups,
      :openstack_orchestration_url,
      :stacks,
      :user_data,
      :metadata,
      :availability_zone,
      :public_key_path,
      :ssl_ca_file,
      :ip_version].each do |attribute|
      it "should not default #{attribute} if overridden" do
        subject.send("#{attribute}=".to_sym, 'foo')
        subject.finalize!
        subject.send(attribute).should == 'foo'
      end
    end

    describe 'use_legacy_synced_folders' do
      it 'should default to true if sync_method is set' do
        subject.sync_method = 'rsync'
        subject.finalize!

        expect(subject.use_legacy_synced_folders).to eq(true)
      end

      it 'should default to true if rsync_includes is non-empty' do
        subject.rsync_includes = ['some/file']
        subject.finalize!

        expect(subject.use_legacy_synced_folders).to eq(true)
      end

      it 'should default to true if rsync_ignore_files is non-empty' do
        subject.rsync_ignore_files = ['some/file']
        subject.finalize!

        expect(subject.use_legacy_synced_folders).to eq(true)
      end
    end

    it 'should not default rsync_includes if overridden' do
      inc = 'core'
      subject.send(:rsync_include, inc)
      subject.finalize!

      expect(subject.rsync_includes).to include(inc)
      expect(subject.use_legacy_synced_folders).to eq(true)
    end
  end

  describe 'merge' do
    let(:foo_class) do
      Class.new(described_class) do
        attr_accessor :networks
        attr_accessor :floating_ip_pool
      end
    end

    subject { foo_class.new }

    context 'with original network not empty array' do
      it 'should overidde the config' do
        one = foo_class.new
        one.networks = ['foo']

        two = foo_class.new
        two.networks = ['bar']

        result = one.merge(two)
        result.networks.should =~ ['bar']
      end
    end

    context 'with original network empty array' do
      it 'should add the network to the existing list' do
        one = foo_class.new
        one.networks = []

        two = foo_class.new
        two.networks = ['bar']

        result = one.merge(two)
        result.networks.should =~ ['bar']
      end
    end

    context 'with original network not empty array and new empty array' do
      it 'should keep the original network' do
        one = foo_class.new
        one.networks = ['foo']

        two = foo_class.new
        two.networks = []

        result = one.merge(two)
        result.networks.should =~ ['foo']
      end
    end

    context 'with original network is a string and new empty array' do
      it 'should keep the original network and wrap it into an array' do
        one = foo_class.new
        one.networks = 'foo'

        two = foo_class.new
        two.networks = []

        result = one.merge(two)
        result.networks.should =~ ['foo']
      end
    end

    context 'with original network is a string and new is a string' do
      it 'should overidde the config and wrap it into an array' do
        one = foo_class.new
        one.networks = 'foo'

        two = foo_class.new
        two.networks = 'bar'

        result = one.merge(two)
        result.networks.should =~ ['bar']
      end
    end

    context 'with original floating_ip_pool as string' do
      context 'and new as empty array' do
        it 'should put original string in a single entry array' do
          one = foo_class.new
          one.floating_ip_pool = 'pool'

          two = foo_class.new
          two.floating_ip_pool = []

          result = one.merge(two)
          result.floating_ip_pool.should =~ ['pool']
        end
      end
      context 'and new as empty string' do
        it 'should put original string in a single entry array' do
          one = foo_class.new
          one.floating_ip_pool = 'pool'

          two = foo_class.new
          two.floating_ip_pool = ''

          result = one.merge(two)
          result.floating_ip_pool.should =~ ['']
        end
      end
      context 'and new as string' do
        it 'should put new string in a single entry array' do
          one = foo_class.new
          one.floating_ip_pool = 'pool'

          two = foo_class.new
          two.floating_ip_pool = 'new-pool'

          result = one.merge(two)
          result.floating_ip_pool.should =~ ['new-pool']
        end
      end
      context 'and new as array' do
        it 'should put new array' do
          one = foo_class.new
          one.floating_ip_pool = 'pool'

          two = foo_class.new
          two.floating_ip_pool = %w(pool-1 pool-2)

          result = one.merge(two)
          result.floating_ip_pool.should =~ %w(pool-1 pool-2)
        end
      end
    end

    context 'with original floating_ip_pool as array' do
      context 'and new empty' do
        it 'should put original array' do
          one = foo_class.new
          one.floating_ip_pool = %w(pool-1 pool-2)

          two = foo_class.new
          two.floating_ip_pool = []

          result = one.merge(two)
          result.floating_ip_pool.should =~ %w(pool-1 pool-2)
        end
      end
      context 'and new as string' do
        it 'should put new string in a single entry array' do
          one = foo_class.new
          one.floating_ip_pool = %w(pool-1 pool-2)

          two = foo_class.new
          two.floating_ip_pool = 'pool'

          result = one.merge(two)
          result.floating_ip_pool.should =~ ['pool']
        end
      end
      context 'and new as array' do
        it 'should put new array' do
          one = foo_class.new
          one.floating_ip_pool = %w(pool-1 pool-2)

          two = foo_class.new
          two.floating_ip_pool = %w(new-pool-1 new-pool-2)

          result = one.merge(two)
          result.floating_ip_pool.should =~ %w(new-pool-1 new-pool-2)
        end
      end
    end

    it 'should merge volume_boot hashes' do
      global_config = foo_class.new
      global_config.volume_boot = { delete_on_destroy: true,
                                    size: 8 }

      vm_config = foo_class.new
      vm_config.volume_boot = { image: 'big_windows_vm',
                                size: 32 }

      result = foo_class.new
      result.volume_boot = {}

      result = result.merge(global_config)
      result = result.merge(vm_config)

      expect(result.volume_boot).to eq(delete_on_destroy: true,
                                       image: 'big_windows_vm',
                                       size: 32)
    end
  end

  describe 'validation' do
    let(:machine) { double('machine') }
    let(:validation_errors) { subject.validate(machine)['Openstack Provider'] }
    let(:error_message) { double('error message') }

    let(:config) { double('config') }
    let(:ssh) { double('ssh') }

    before(:each) do
      error_message.stub(:yellow) { 'Yellowed Error message ' }
      machine.stub_chain(:env, :root_path).and_return '/'
      ssh.stub(:private_key_path) { 'private key path' }
      ssh.stub(:username) { 'ssh username' }
      ssh.stub(:insert_key) { true }
      config.stub(:ssh) { ssh }
      machine.stub(:config) { config }
      subject.username = 'foo'
      subject.password = 'bar'
      subject.tenant_name = 'tenant'
      subject.keypair_name = 'keypair'
    end

    subject do
      super().tap(&:finalize!)
    end

    context 'with invalid stack' do
      it 'should raise an error' do
        subject.stacks = [
          {
            name: 'test1'
          }
        ]
        I18n.should_receive(:t).with('vagrant_openstack.config.invalid_stack').and_return error_message
        validation_errors.first.should == error_message
      end

      it 'should raise an error' do
        subject.stacks = [
          {
            name: 'test1',
            tempslate: 'tes1'
          }
        ]
        I18n.should_receive(:t).with('vagrant_openstack.config.invalid_stack').and_return error_message
        validation_errors.first.should == error_message
      end

      it 'should not raise an error' do
        subject.stacks = [
          {
            name: 'test1',
            template: 'tes1'
          }
        ]
        expect(validation_errors).to be_empty
      end
    end

    context 'with invalid key' do
      it 'should raise an error' do
        subject.nonsense1 = true
        subject.nonsense2 = false
        I18n.should_receive(:t).with('vagrant.config.common.bad_field', fields: 'nonsense1, nonsense2').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'with no ssh username provider' do
      it 'should raise an error' do
        ssh.stub(:username) { nil }
        subject.ssh_username = nil
        I18n.should_receive(:t).with('vagrant_openstack.config.ssh_username_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'with good values' do
      it 'should validate' do
        validation_errors.should be_empty
      end
    end

    context 'private_key_path is not set' do
      context 'keypair_name or public_key_path is set' do
        it 'should error if not given' do
          ssh.stub(:private_key_path) { nil }
          subject.public_key_path = 'public_key'
          I18n.should_receive(:t).with('vagrant_openstack.config.private_key_missing').and_return error_message
          validation_errors.first.should == error_message
        end
      end

      context 'keypair_name or public_key_path is set and ssh.insert_key is false' do
        it 'should not error' do
          ssh.stub(:private_key_path) { nil }
          ssh.stub(:insert_key) { false }
          subject.public_key_path = 'public_key'
          I18n.should_not_receive(:t)
          validation_errors.should be_empty
        end
      end
    end

    context 'the password' do
      it 'should error if not given' do
        subject.password = nil
        I18n.should_receive(:t).with('vagrant_openstack.config.password_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'the username' do
      it 'should error if not given' do
        subject.username = nil
        I18n.should_receive(:t).with('vagrant_openstack.config.username_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'the tenant name' do
      it 'should error if not given' do
        subject.tenant_name = nil
        I18n.should_receive(:t).with('vagrant_openstack.config.tenant_name_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'the ssh_timeout' do
      it 'should error if do not represent an integer' do
        subject.ssh_timeout = 'timeout'
        I18n.should_receive(:t).with('vagrant_openstack.config.invalid_value_for_parameter',
                                     parameter: 'ssh_timeout', value: 'timeout').and_return error_message
        validation_errors.first.should == error_message
      end
      it 'should be parsed as integer if is a string that represent an integer' do
        subject.ssh_timeout = '100'
        validation_errors.size.should eq(0)
        expect(subject.ssh_timeout).to eq(100)
      end
    end

    [:openstack_compute_url, :openstack_auth_url, :openstack_orchestration_url].each do |url|
      context "the #{url}" do
        it 'should not validate if the URL is invalid' do
          subject.send "#{url}=", 'baz'
          I18n.should_receive(:t).with('vagrant_openstack.config.invalid_uri', key: url, uri: 'baz').and_return error_message
          validation_errors.first.should == error_message
        end
      end
    end
  end
end
