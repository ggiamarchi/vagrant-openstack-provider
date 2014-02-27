if ENV['COVERAGE'] != 'false'
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start
end

require "vagrant-openstack/config"
require 'fog'

describe VagrantPlugins::Openstack::Config do
  describe "defaults" do
    let(:vagrant_public_key) { Vagrant.source_root.join("keys/vagrant.pub") }

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    its(:api_key)  { should be_nil }
    its(:openstack_region) { should be_nil }
    its(:openstack_compute_url) { should be_nil }
    its(:openstack_auth_url) { should be_nil }
    its(:flavor)   { should eq(/m1.tiny/) }
    its(:image)    { should eq(/cirros/) }
    its(:rackconnect) { should be_nil }
    its(:network) { should be_nil }
    its(:server_name) { should be_nil }
    its(:username) { should be_nil }
    its(:disk_config) { should be_nil }
    its(:network) { should be_nil }
    its(:rsync_includes) { should be_nil }
    its(:keypair_name) { should be_nil }
    its(:ssh_username) { should be_nil }
  end

  describe "overriding defaults" do
    [:api_key,
      :openstack_region,
      :openstack_compute_url,
      :openstack_auth_url,
      :flavor,
      :image,
      :rackconnect,
      :server_name,
      :network,
      :disk_config,
      :username,
      :keypair_name,
      :ssh_username].each do |attribute|
      it "should not default #{attribute} if overridden" do
        subject.send("#{attribute}=".to_sym, "foo")
        subject.finalize!
        subject.send(attribute).should == "foo"
      end
    end

    it "should not default networks if overridden" do
      net_id = "deadbeef-0000-0000-0000-000000000000"
      subject.send(:network, net_id)
      subject.finalize!
      subject.send(:networks).should include(net_id)
      subject.send(:networks).should include(VagrantPlugins::Openstack::Config::PUBLIC_NET_ID)
      subject.send(:networks).should include(VagrantPlugins::Openstack::Config::SERVICE_NET_ID)
    end

    it "should not default rsync_includes if overridden" do 
      inc = "core"
      subject.send(:rsync_include, inc)
      subject.finalize!
      subject.send(:rsync_includes).should include(inc)
    end
  end

  describe "validation" do
    let(:machine) { double("machine") }
    let(:validation_errors) { subject.validate(machine)['Openstack Provider'] }
    let(:error_message) { double("error message") }

    before(:each) do
      machine.stub_chain(:env, :root_path).and_return '/'
      subject.username = 'foo'
      subject.api_key = 'bar'
      subject.keypair_name = 'keypair'
    end

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    context "with invalid key" do
      it "should raise an error" do
        subject.nonsense1 = true
        subject.nonsense2 = false
        I18n.should_receive(:t).with('vagrant.config.common.bad_field',
          { :fields => 'nonsense1, nonsense2' })
        .and_return error_message
        validation_errors.first.should == error_message
      end
    end
    context "with good values" do
      it "should validate" do
        validation_errors.should be_empty
      end
    end

    context "the keypair name" do
      it "should error if not given" do
        subject.keypair_name = nil
        I18n.should_receive(:t).with('vagrant_openstack.config.keypair_name required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context "the API key" do
      it "should error if not given" do
        subject.api_key = nil
        I18n.should_receive(:t).with('vagrant_openstack.config.api_key required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context "the username" do
      it "should error if not given" do
        subject.username = nil
        I18n.should_receive(:t).with('vagrant_openstack.config.username required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    [:openstack_compute_url, :openstack_auth_url].each do |url|
      context "the #{url}" do
        it "should not validate if the URL is invalid" do
          subject.send "#{url}=", 'baz'
          I18n.should_receive(:t).with('vagrant_openstack.config.invalid_uri', {:key => url, :uri => 'baz'}).and_return error_message
          validation_errors.first.should == error_message
        end
      end
    end
  end

  describe "openstack_auth_url" do
    it "should return UNSET_VALUE if openstack_auth_url and openstack_region are UNSET" do
      subject.openstack_auth_url.should == VagrantPlugins::Openstack::Config::UNSET_VALUE
    end
    it "should return UNSET_VALUE if openstack_auth_url is UNSET and openstack_region is :ord" do
      subject.openstack_region = :ord
      subject.openstack_auth_url.should == VagrantPlugins::Openstack::Config::UNSET_VALUE
    end
    it "should return custom endpoint if supplied and openstack_region is :lon" do
      my_endpoint = 'http://custom-endpoint.com'
      subject.openstack_region = :lon
      subject.openstack_auth_url = my_endpoint
      subject.openstack_auth_url.should == my_endpoint
    end
    it "should return custom endpoint if supplied and openstack_region is UNSET" do
      my_endpoint = 'http://custom-endpoint.com'
      subject.openstack_auth_url = my_endpoint
      subject.openstack_auth_url.should == my_endpoint
    end
  end


  describe "lon_region?" do
    it "should return false if openstack_region is UNSET_VALUE" do
      subject.openstack_region = VagrantPlugins::Openstack::Config::UNSET_VALUE
      subject.send(:lon_region?).should be_false
    end
    it "should return false if openstack_region is nil" do
      subject.openstack_region = nil
      subject.send(:lon_region?).should be_false
    end
    it "should return false if openstack_region is :ord" do
      subject.openstack_region = :ord
      subject.send(:lon_region?).should be_false
    end
    it "should return true if openstack_region is 'lon'" do
      subject.openstack_region = 'lon'
      subject.send(:lon_region?).should be_true
    end
    it "should return true if openstack_Region is :lon" do
      subject.openstack_region = :lon
      subject.send(:lon_region?).should be_true
    end
  end

  describe "network" do
    it "should remove SERVICE_NET_ID if :service_net is detached" do
      subject.send(:network, :service_net, :attached => false)
      subject.send(:networks).should_not include(VagrantPlugins::Openstack::Config::SERVICE_NET_ID)
    end

    it "should not allow duplicate networks" do
      net_id = "deadbeef-0000-0000-0000-000000000000"
      subject.send(:network, net_id)
      subject.send(:network, net_id)
      subject.send(:networks).count(net_id).should == 1
    end
  end
end
