require 'vagrant-openstack-provider/spec_helper'
require 'log4r'
require 'rbconfig'
require 'vagrant/util/subprocess'

include VagrantPlugins::Openstack::Action

describe VagrantPlugins::Openstack::Action::SyncFolders do
  let(:app) do
    double('app').tap do |app|
      app.stub(:call).with(anything)
    end
  end

  let(:vm) do
    double('vm').tap do |vm|
      vm.stub(:synced_folders) { { '/vagrant' => { hostpath: '/home/john/vagrant', guestpath: '/vagrant' } } }
    end
  end

  let(:provider_config) do
    double('provider_config').tap do |c|
      c.stub(:rsync_includes) { nil }
      c.stub(:ssh_disabled) { false }
      c.stub(:rsync_ignore_files) { ['.gitignore'] }
    end
  end

  let(:communicate) do
    double('communicate').tap do |c|
      c.stub(:sudo)
    end
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui').tap do |ui|
        ui.stub(:info).with(anything)
        ui.stub(:error).with(anything)
      end
      env[:openstack_client] = double('openstack_client').tap do |os|
        os.stub(:nova) { nova }
      end
      env[:machine] = OpenStruct.new.tap do |m|
        m.ssh_info = {
          username: 'user',
          port: '23',
          host: '1.2.3.4',
          private_key_path: '/tmp/key.pem'
        }
        m.provider_config = provider_config
        m.config = double('config').tap do |c|
          c.stub(:vm) { vm }
        end
        m.communicate = communicate
      end
      env[:root_path] = '.'
    end
  end

  before :each do
    @action = SyncFolders.new(app, nil)
  end

  describe 'call' do
    context 'sync method is set to none and ssh_disabled is false' do
      it 'does not sync folders' do
        Vagrant::Util::Subprocess.stub(:execute)
        provider_config.stub(:sync_method) { 'none' }
        provider_config.stub(:ssh_disabled) { false }
        expect(Vagrant::Util::Subprocess).to_not receive :execute
        @action.call(env)
      end
    end
    context 'sync method is set to none and ssh_disabled is true' do
      it 'does not sync folders' do
        Vagrant::Util::Subprocess.stub(:execute)
        provider_config.stub(:sync_method) { 'none' }
        provider_config.stub(:ssh_disabled) { true }
        expect(Vagrant::Util::Subprocess).to_not receive :execute
        @action.call(env)
      end
    end
    context 'sync method is set to rsync and ssh_disabled is true' do
      it 'does not sync folders' do
        Vagrant::Util::Subprocess.stub(:execute)
        provider_config.stub(:sync_method) { 'rsync' }
        provider_config.stub(:ssh_disabled) { true }
        expect(Vagrant::Util::Subprocess).to_not receive :execute
        @action.call(env)
      end
    end
    context 'sync method is set to rsync and ssh_disabled is false' do
      it 'runs a rsync command' do
        provider_config.stub(:sync_method) { 'rsync' }
        Vagrant::Util::Subprocess.stub(:execute) do
          OpenStruct.new.tap do |r|
            r.exit_code = 0
            r.stderr = nil
          end
        end
        expected_command = ['rsync',
                            '--verbose',
                            '--archive',
                            '-z',
                            '--cvs-exclude',
                            '--exclude',
                            '.hg/',
                            '--exclude',
                            '.git/',
                            '--chmod',
                            'ugo=rwX',
                            '-e',
                            "ssh -p 23 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i '/tmp/key.pem' ",
                            '/home/john/vagrant/',
                            'user@1.2.3.4:/vagrant',
                            '--exclude-from',
                            './.gitignore']
        expect(communicate).to receive(:sudo).with "mkdir -p '/vagrant'"
        expect(communicate).to receive(:sudo).with "chown -R user '/vagrant'"
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(*expected_command)
        @action.call(env)
      end
    end
    context 'rsync command returns a non zero status code' do
      it 'raise an error' do
        provider_config.stub(:sync_method) { 'rsync' }
        Vagrant::Util::Subprocess.stub(:execute) do
          OpenStruct.new.tap do |r|
            r.exit_code = 1
            r.stderr = 'Fatal error'
          end
        end
        expect(Vagrant::Util::Subprocess).to receive(:execute)
        expect { @action.call(env) }.to raise_error Errors::RsyncError
      end
    end
    context 'sync method value is not valid' do
      it 'raise an error' do
        provider_config.stub(:sync_method) { 'nfs' }
        expect { @action.call(env) }.to raise_error Errors::SyncMethodError
      end
    end
  end

  describe 'convert_path_to_windows_format' do
    context 'hostpath in starting with C:/ ' do
      it 'returns hostpath starting with /cygdrive/c/ and in downcase' do
        RsyncFolders.send(:public, *RsyncFolders.private_instance_methods)
        action = RsyncFolders.new(app, nil)
        expect(action.add_cygdrive_prefix_to_path('C:/Directory')).to eq '/cygdrive/c/directory'
      end
    end
  end
end
