require "vagrant-rackspace/config"

describe VagrantPlugins::Rackspace::Config do
  describe "defaults" do
    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    its(:api_key)  { should be_nil }
    its(:endpoint) { should be_nil }
    its(:flavor)   { should be_nil }
    its(:image)    { should be_nil }
    its(:username) { should be_nil }
  end

  describe "overriding defaults" do
    [:api_key,
      :endpoint,
      :flavor,
      :image,
      :username].each do |attribute|
      it "should not default #{attribute} if overridden" do
        subject.send("#{attribute}=".to_sym, "foo")
        subject.finalize!
        subject.send(attribute).should == "foo"
      end
    end
  end
end
