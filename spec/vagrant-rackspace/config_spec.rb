require "vagrant-rackspace/config"
require 'fog'

describe VagrantPlugins::Rackspace::Config do
  describe "defaults" do
    let(:vagrant_public_key) { Vagrant.source_root.join("keys/vagrant.pub") }

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    its(:api_key)  { should be_nil }
    its(:rackspace_region) { should be_nil }
    its(:rackspace_compute_url) { should be_nil }
    its(:rackspace_auth_url) { should be_nil }
    its(:flavor)   { should eq(/512MB/) }
    its(:image)    { should eq(/Ubuntu/) }
    its(:public_key_path) { should eql(vagrant_public_key) }
    its(:rackconnect) { should be_nil }
    its(:server_name) { should be_nil }
    its(:username) { should be_nil }
    its(:disk_config) { should be_nil }
    its(:networks) { should be_nil }
  end

  describe "overriding defaults" do
    [:api_key,
      :rackspace_region,
      :rackspace_compute_url,
      :rackspace_auth_url,
      :flavor,
      :image,
      :public_key_path,
      :rackconnect,
      :server_name,
      :disk_config,
      :username].each do |attribute|
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
      subject.send(:networks).should include(VagrantPlugins::Rackspace::Config::PUBLIC_NET_ID)
      subject.send(:networks).should include(VagrantPlugins::Rackspace::Config::SERVICE_NET_ID)
    end
  end

  describe "validation" do
    let(:machine) { double("machine") }
    let(:validation_errors) { subject.validate(machine)['RackSpace Provider'] }
    let(:error_message) { double("error message") }

    before(:each) do
      machine.stub_chain(:env, :root_path).and_return '/'
      subject.username = 'foo'
      subject.api_key = 'bar'
    end

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    context "with good values" do
      it "should validate" do
        validation_errors.should be_empty
      end
    end

    context "the API key" do
      it "should error if not given" do
        subject.api_key = nil
        I18n.should_receive(:t).with('vagrant_rackspace.config.api_key_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context "the public key path" do
      it "should have errors if the key doesn't exist" do
        subject.public_key_path = 'missing'
        I18n.should_receive(:t).with('vagrant_rackspace.config.public_key_not_found').and_return error_message
        validation_errors.first.should == error_message
      end
      it "should not have errors if the key exists with an absolute path" do
        subject.public_key_path = File.expand_path 'locales/en.yml', Dir.pwd
        validation_errors.should be_empty
      end
      it "should not have errors if the key exists with a relative path" do
        machine.stub_chain(:env, :root_path).and_return '.'
        subject.public_key_path = 'locales/en.yml'
        validation_errors.should be_empty
      end
    end

    context "the username" do
      it "should error if not given" do
        subject.username = nil
        I18n.should_receive(:t).with('vagrant_rackspace.config.username_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    [:rackspace_compute_url, :rackspace_auth_url].each do |url|
      context "the #{url}" do
        it "should not validate if the URL is invalid" do
          subject.send "#{url}=", 'baz'
          I18n.should_receive(:t).with('vagrant_rackspace.config.invalid_uri', {:key => url, :uri => 'baz'}).and_return error_message
          validation_errors.first.should == error_message
        end
      end
    end
  end

  describe "rackspace_auth_url" do
    it "should return UNSET_VALUE if rackspace_auth_url and rackspace_region are UNSET" do
      subject.rackspace_auth_url.should == VagrantPlugins::Rackspace::Config::UNSET_VALUE
    end
    it "should return UNSET_VALUE if rackspace_auth_url is UNSET and rackspace_region is :ord" do
      subject.rackspace_region = :ord
      subject.rackspace_auth_url.should == VagrantPlugins::Rackspace::Config::UNSET_VALUE
    end
    it "should return UK Authentication endpoint if rackspace_auth_url is UNSET and rackspace_region is :lon" do
      subject.rackspace_region = :lon
      subject.rackspace_auth_url.should == Fog::Rackspace::UK_AUTH_ENDPOINT
    end
    it "should return custom endpoint if supplied and rackspace_region is :lon" do
      my_endpoint = 'http://custom-endpoint.com'
      subject.rackspace_region = :lon
      subject.rackspace_auth_url = my_endpoint
      subject.rackspace_auth_url.should == my_endpoint
    end
    it "should return custom endpoint if supplied and rackspace_region is UNSET" do
      my_endpoint = 'http://custom-endpoint.com'
      subject.rackspace_auth_url = my_endpoint
      subject.rackspace_auth_url.should == my_endpoint
    end
  end


  describe "lon_region?" do
    it "should return false if rackspace_region is UNSET_VALUE" do
      subject.rackspace_region = VagrantPlugins::Rackspace::Config::UNSET_VALUE
      subject.send(:lon_region?).should be_false
    end
    it "should return false if rackspace_region is nil" do
      subject.rackspace_region = nil
      subject.send(:lon_region?).should be_false
    end
    it "should return false if rackspace_region is :ord" do
      subject.rackspace_region = :ord
      subject.send(:lon_region?).should be_false
    end
    it "should return true if rackspace_region is 'lon'" do
      subject.rackspace_region = 'lon'
      subject.send(:lon_region?).should be_true
    end
    it "should return true if rackspace_Region is :lon" do
      subject.rackspace_region = :lon
      subject.send(:lon_region?).should be_true
    end
  end

  describe "network" do
    it "should remove SERVICE_NET_ID if :service_net is detached" do
      subject.send(:network, :service_net, :attach => false)
      subject.send(:networks).should_not include(VagrantPlugins::Rackspace::Config::SERVICE_NET_ID)
    end

    it "should not allow duplicate networks" do
      net_id = "deadbeef-0000-0000-0000-000000000000"
      subject.send(:network, net_id)
      subject.send(:network, net_id)
      subject.send(:networks).count(net_id).should == 1
    end
  end
end
