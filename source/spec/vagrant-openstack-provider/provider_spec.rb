if ENV['COVERAGE'] != 'false'
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start
end

require "vagrant-openstack-provider/provider"

describe VagrantPlugins::Openstack::Provider do
  before :each do
    @provider = VagrantPlugins::Openstack::Provider.new :machine
  end

  describe "to string" do
    it "should give the provider name" do
      @provider.to_s.should eq('Openstack Cloud')
    end
  end
end
