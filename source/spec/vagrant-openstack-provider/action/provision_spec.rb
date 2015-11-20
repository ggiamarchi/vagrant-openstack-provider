require 'vagrant-openstack-provider/spec_helper'

#
# Stubing all the interactions using the real
# provisioner classes is somehow complicated...
#
class FakeProvisioner
  def provision
  end
end

class FakeShellProvisioner < FakeProvisioner
  attr_accessor :config

  def initialize(config)
    @config = config
  end
end

describe VagrantPlugins::Openstack::Action::ProvisionWrapper do
  let(:app) do
    double
  end

  let(:internal_provision_wrapper) do
    double
  end

  before :each do
    # Stub lookup for provisioners and return a hash containing the test mock.
    allow(Vagrant.plugin('2').manager).to receive(:provisioners).and_return(shell: FakeShellProvisioner)
    @action = ProvisionWrapper.new(app, nil)
  end

  describe 'execute' do
    it 'call InternalProvisionWrapper and conitnue the middleware chain' do
      expect(internal_provision_wrapper).to receive(:call)
      InternalProvisionWrapper.stub(:new) { internal_provision_wrapper }
      app.stub(:call) {}
      @action.execute nil
    end
  end
end

describe VagrantPlugins::Openstack::Action::InternalProvisionWrapper do
  let(:env) do
    {}
  end

  before :each do
    # Stub lookup for provisioners and return a hash containing the test mock.
    allow(Vagrant.plugin('2').manager).to receive(:provisioners).and_return(shell: FakeShellProvisioner)
    @action = InternalProvisionWrapper.new(nil, env)
  end

  describe 'run_provisioner' do
    context 'when running a shell provisioner' do
      context 'without meta-arg' do
        it 'does not change the provisioner config' do
          env[:provisioner] = FakeShellProvisioner.new(OpenStruct.new.tap do |c|
            c.args = %w(arg1 arg2)
          end)

          expect(env[:provisioner]).to receive(:provision)
          expect(@action).to receive(:handle_shell_meta_args)

          @action.run_provisioner(env)
          expect(env[:provisioner].config.args).to eq(%w(arg1 arg2))
        end
      end

      context 'with @@ssh_ip@@ meta-arg' do
        it 'replace the meta-args in the provisioner config' do
          env[:provisioner] = FakeShellProvisioner.new(OpenStruct.new.tap do |c|
            c.args = ['arg1', '@@ssh_ip@@', 'arg3']
          end)

          VagrantPlugins::Openstack::Action.stub(:get_ssh_info).and_return host: '192.168.0.1'
          expect(env[:provisioner]).to receive(:provision)

          @action.run_provisioner(env)
          expect(env[:provisioner].config.args).to eq(%w(arg1 192.168.0.1 arg3))
        end
      end
    end

    context 'when running a provisioner other that the shell provisioner' do
      it 'does not call handle_shell_meta_args' do
        env[:provisioner] = FakeProvisioner.new
        expect(@action).should_not_receive(:handle_shell_meta_args)
        expect(env[:provisioner]).to receive(:provision)

        @action.run_provisioner(env)
      end
    end
  end
end
