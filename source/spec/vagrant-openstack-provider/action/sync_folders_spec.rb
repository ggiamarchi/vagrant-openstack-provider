require 'vagrant-openstack-provider/spec_helper'
require 'log4r'
require 'rbconfig'
require 'vagrant/util/subprocess'

include VagrantPlugins::Openstack::Action

describe VagrantPlugins::Openstack::Action::RsyncFolders do

  before :each do
    RsyncFolders.send(:public, *RsyncFolders.private_instance_methods)
    app = double('app')
    app.stub(:call).with(anything)
    @action = RsyncFolders.new(app, nil)
  end

  describe 'convert_path_to_windows_format' do
    context 'hostpath in starting with C:/ ' do
      it 'returns hostpath starting with /cygdrive/c/ and in downcase' do
        expect(@action.add_cygdrive_prefix_to_path('C:/Directory')).to eq '/cygdrive/c/directory'
      end
    end
  end
end
