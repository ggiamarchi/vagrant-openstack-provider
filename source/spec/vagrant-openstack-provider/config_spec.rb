require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Config do
  describe 'defaults' do
    let(:vagrant_public_key) { Vagrant.source_root.join('keys/vagrant.pub') }

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    its(:password)  { should be_nil }
    its(:openstack_compute_url) { should be_nil }
    its(:openstack_auth_url) { should be_nil }
    its(:flavor)   { should be_nil }
    its(:image)    { should be_nil }
    its(:server_name) { should be_nil }
    its(:username) { should be_nil }
    its(:rsync_includes) { should be_nil }
    its(:keypair_name) { should be_nil }
    its(:public_key_path) { should be_nil }
    its(:availability_zone) { should be_nil }
    its(:ssh_username) { should be_nil }
    its(:floating_ip_pool_always_allocate) { should be_false }
    its(:scheduler_hints) { should be_nil }
    its(:security_groups) { should be_nil }
    its(:user_data) { should be_nil }
    its(:metadata) { should be_nil }
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
      :user_data,
      :metadata,
      :availability_zone,
      :public_key_path].each do |attribute|
      it "should not default #{attribute} if overridden" do
        subject.send("#{attribute}=".to_sym, 'foo')
        subject.finalize!
        subject.send(attribute).should == 'foo'
      end
    end

    it 'should not default rsync_includes if overridden' do
      inc = 'core'
      subject.send(:rsync_include, inc)
      subject.finalize!
      subject.send(:rsync_includes).should include(inc)
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
      config.stub(:ssh) { ssh }
      machine.stub(:config) { config }
      subject.username = 'foo'
      subject.password = 'bar'
      subject.keypair_name = 'keypair'
    end

    subject do
      super().tap do |o|
        o.finalize!
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
    end

    context 'the API key' do
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

    [:openstack_compute_url, :openstack_auth_url].each do |url|
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
