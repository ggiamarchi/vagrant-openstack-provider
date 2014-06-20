require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::Provider do
  before :each do
    @provider = VagrantPlugins::Openstack::Provider.new :machine
  end

  describe 'to string' do
    it 'should give the provider name' do
      @provider.to_s.should eq('Openstack Cloud')
    end
  end
end
