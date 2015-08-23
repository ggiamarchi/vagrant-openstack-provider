require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::VersionChecker do
  let(:version) do
    double('version')
  end

  before :each do
    @checker = VersionChecker.instance
    @checker.status = nil
    Gem.should_receive(:latest_spec_for)
      .with('vagrant-openstack-provider')
      .and_return(OpenStruct.new.tap { |v| v.version = version })
  end

  describe 'check' do
    it { assert_version_is :latest, '1.2.3', '1.2.3' }
    it { assert_version_is :latest, '999.999.999', '999.999.999' }
    it { assert_version_is :unstable, '9999.999.999', '9999.999.999' }
    it { assert_version_is :unstable, '999.9999.999', '999.9999.999' }
    it { assert_version_is :unstable, '999.999.9999', '999.999.9999' }
    it { assert_version_is :unstable, '1.2', '1.2' }
    it { assert_version_is :outdated, '1.2.3', '1.2.2' }
    it { assert_version_is :outdated, '1.8.999', '1.8.998' }
    it { assert_version_is :outdated, '1.9.0', '1.8.999' }
    it { assert_version_is :outdated, '2.0.0', '1.999.999' }
  end

  private

  def assert_version_is(expected_status, latest, current)
    stub_const('VagrantPlugins::Openstack::VERSION', current)
    version.stub(:version) { latest }
    @checker.stub(:print)
    expect(@checker).to receive(:print) unless expected_status == :latest
    @checker.check
    expect(@checker.status).to eq(expected_status)
  end
end
