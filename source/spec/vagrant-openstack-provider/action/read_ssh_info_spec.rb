require 'vagrant-openstack-provider/spec_helper'

include VagrantPlugins::Openstack::Action
include VagrantPlugins::Openstack::HttpUtils
include VagrantPlugins::Openstack::Domain

describe VagrantPlugins::Openstack::Action::ReadSSHInfo do
  let(:config) do
    double('config').tap do |config|
      config.stub(:openstack_auth_url) { 'http://keystoneAuthV2' }
      config.stub(:openstack_compute_url) { nil }
      config.stub(:openstack_network_url) { nil }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
      config.stub(:ssh_username) { 'test_username' }
      config.stub(:floating_ip) { nil }
      config.stub(:floating_ip_pool) { nil }
      config.stub(:keypair_name) { nil }
      config.stub(:public_key_path) { nil }
      config.stub(:ssh_disabled) { false }
      config.stub(:ip_version) { nil }
    end
  end

  let(:nova) do
    double('nova').tap do |nova|
      nova.stub(:get_server_details).with(env, '1234') do
        {
          'addresses' => {
            'net' => [
              {
                'addr' => '80.80.80.80',
                'OS-EXT-IPS:type' => 'floating'
              }
            ]
          }
        }
      end
    end
  end

  let(:ssh_config) do
    double('ssh_config').tap do |config|
      config.stub(:username) { 'sshuser' }
      config.stub(:port) { nil }
      config.stub(:insert_key) { true }
    end
  end

  let(:machine_config) do
    double('machine_config').tap do |config|
      config.stub(:ssh) { ssh_config }
    end
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:machine].stub(:config) { machine_config }
      env[:machine].stub(:id) { '1234' }
      env[:machine].stub(:data_dir) { '/data/dir' }
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:neutron) { neutron }
      env[:openstack_client].stub(:nova) { nova }
    end
  end

  let(:app) do
    double('app').tap do |app|
      app.stub(:call).with(anything)
    end
  end

  before :each do
    ReadSSHInfo.send(:public, *ReadSSHInfo.private_instance_methods)
    @action = ReadSSHInfo.new(app, env)
  end

  describe 'call' do
    context 'when called three times' do
      it 'read ssh info only once' do
        config.stub(:keypair_name) { 'my_keypair' }
        @action.stub(:read_ssh_info) { { host: '', port: '', username: '' } }
        expect(@action).to receive(:read_ssh_info).exactly(1).times
        expect(app).to receive(:call)
        (1..3).each { @action.call(env) }
      end
    end
  end

  describe 'read_ssh_info' do
    context 'with deprecated ssh_username specified' do
      context 'with ssh.username specified' do
        it 'returns ssh.username' do
          ssh_config.stub(:username) { 'sshuser' }
          config.stub(:ssh_username) { 'test_username' }
          config.stub(:floating_ip) { '80.80.80.80' }
          config.stub(:keypair_name) { 'my_keypair' }
          @action.read_ssh_info(env).should eq(host: '80.80.80.80', port: 22, username: 'sshuser', log_level: 'ERROR')
        end
      end
      context 'without ssh.username specified' do
        it 'returns ssh.username' do
          ssh_config.stub(:username) { nil }
          config.stub(:ssh_username) { 'test_username' }
          config.stub(:floating_ip) { '80.80.80.80' }
          config.stub(:keypair_name) { 'my_keypair' }
          @action.read_ssh_info(env).should eq(host: '80.80.80.80', port: 22, username: 'test_username', log_level: 'ERROR')
        end
      end
    end

    context 'with ssh.port overriden' do
      it 'returns ssh.port' do
        ssh_config.stub(:port) { 33 }
        config.stub(:floating_ip) { '80.80.80.80' }
        config.stub(:keypair_name) { 'my_keypair' }
        @action.read_ssh_info(env).should eq(host: '80.80.80.80', port: 33, username: 'sshuser', log_level: 'ERROR')
      end
    end

    context 'with config.floating_ip specified' do
      context 'with keypair_name specified' do
        it 'returns the specified floating ip' do
          config.stub(:floating_ip) { '80.80.80.80' }
          config.stub(:keypair_name) { 'my_keypair' }
          @action.read_ssh_info(env).should eq(host: '80.80.80.80', port: 22, username: 'sshuser', log_level: 'ERROR')
        end
      end

      context 'with public_key_path specified' do
        it 'returns the specified floating ip' do
          config.stub(:floating_ip) { '80.80.80.80' }
          config.stub(:keypair_name) { nil }
          config.stub(:public_key_path) { '/public/key/path' }
          @action.read_ssh_info(env).should eq(host: '80.80.80.80', port: 22, username: 'sshuser', log_level: 'ERROR')
        end
      end

      context 'with neither keypair_name nor public_key_path specified' do
        it 'returns the specified floating ip ' do
          config.stub(:floating_ip) { '80.80.80.80' }
          config.stub(:keypair_name) { nil }
          config.stub(:public_key_path) { nil }
          nova.stub(:get_server_details) do
            {
              'key_name' => 'my_keypair_name',
              'addresses' => {
                'net' => [
                  {
                    'addr' => '80.80.80.80',
                    'OS-EXT-IPS:type' => 'floating'
                  }
                ]
              }
            }
          end
          expect(nova).to receive(:get_server_details).with(env, '1234')
          @action.read_ssh_info(env).should eq(
            host: '80.80.80.80',
            port: 22,
            username: 'sshuser',
            private_key_path: '/data/dir/my_keypair_name',
            log_level: 'ERROR')
        end
      end

      context 'with neither keypair_name nor public_key_path specified and ssh.insert_key is false' do
        it 'does not return private_key_path' do
          ssh_config.stub(:insert_key) { false }
          config.stub(:floating_ip) { '80.80.80.80' }
          config.stub(:keypair_name) { nil }
          config.stub(:public_key_path) { nil }
          @action.read_ssh_info(env).should eq(host: '80.80.80.80', port: 22, username: 'sshuser', log_level: 'ERROR')
        end
      end
    end

    context 'without config.floating_ip specified' do
      it 'return the a floating_ip found by querying server details' do
        nova.stub(:get_server_details).with(env, '1234') do
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
        config.stub(:keypair_name) { 'my_keypair' }
        @action.read_ssh_info(env).should eq(host: '12.12.12.12', port: 22, username: 'sshuser', log_level: 'ERROR')
      end
    end
  end
end
