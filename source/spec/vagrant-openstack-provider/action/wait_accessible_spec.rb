require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Action::WaitForServerToBeAccessible do
  let(:config) do
    double('config')
  end

  let(:env) do
    {}.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:ui].stub(:error).with(anything)
      env[:machine] = double('machine').tap do |m|
        m.stub(:provider_config) { config }
      end
    end
  end

  let(:resolver) do
    double('resolver').tap do |r|
      r.stub(:resolve_floating_ip).with(anything) { '1.2.3.4' }
    end
  end

  let(:ssh) do
    double('shh')
  end

  let(:app) do
    double('app').tap do |app|
      app.stub(:call).with(anything)
    end
  end

  class SSHMock
    def initialize(*exit_codes)
      @times = 0
      @exit_codes = exit_codes
    end

    def call(env)
      env[:ssh_run_exit_status] = @exit_codes[@times]
      @times += 1
    end
  end

  describe 'call' do
    context 'when server is not yet reachable' do
      it 'retry until server is reachable' do
        config.stub(:ssh_timeout) { 2 }
        expect(app).to receive(:call)

        @action = WaitForServerToBeAccessible.new(app, nil, resolver, SSHMock.new(1, 0))
        @action.call(env)
      end
    end
    context 'when server is not yet reachable after timeout' do
      it 'raise an error' do
        config.stub(:ssh_timeout) { 1 }
        expect(app).should_not_receive(:call)

        @action = WaitForServerToBeAccessible.new(app, nil, resolver, SSHMock.new(1, 1))
        expect { @action.call(env) }.to raise_error Errors::SshUnavailable
      end
    end
  end
end
