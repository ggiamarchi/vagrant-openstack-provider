require "vagrant-rackspace/config"

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
    its(:flavor)   { should eq(/512MB/) }
    its(:image)    { should eq(/Ubuntu/) }
    its(:public_key_path) { should eql(vagrant_public_key) }
    its(:server_name) { should be_nil }
    its(:username) { should be_nil }
  end

  describe "overriding defaults" do
    [:api_key,
      :rackspace_region,
      :rackspace_compute_url,
      :flavor,
      :image,
      :public_key_path,
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
end
