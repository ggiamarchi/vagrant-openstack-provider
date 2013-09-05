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
      :username].each do |attribute|
      it "should not default #{attribute} if overridden" do
        subject.send("#{attribute}=".to_sym, "foo")
        subject.finalize!
        subject.send(attribute).should == "foo"
      end
    end
  end

  describe "validation" do
    let(:machine) { double("machine") }

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    context "with good values" do
      it "should validate"
    end

    context "the API key" do
      it "should error if not given"
    end

    context "the public key path" do
      it "should have errors if the key doesn't exist"
      it "should not have errors if the key exists with an absolute path"
      it "should not have errors if the key exists with a relative path"
    end

    context "the username" do
      it "should error if not given"
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
end
