require 'vagrant-openstack-provider'

Vagrant.configure("2") do |config|

  config.vm.box = "dummy-openstack"
  config.vm.box_url = "https://github.com/ggiamarchi/vagrant-openstack/raw/master/source/dummy.box"

  config.ssh.private_key_path = "/home/vagrant/.ssh/id_rsa"
  config.ssh.shell = "sh"

  config.vm.provider :openstack do |os|

    os.server_name = "vagrant-os-plugin-test"
    os.username = ENV['OS_USERNAME']
    os.floating_ip = "185.39.216.244"
    os.password = ENV['OS_PASSWORD']
    os.flavor = /Linux-L-2vCpu-4G/
    os.image = /ubuntu-12.04_x86_64_LVM/
    os.openstack_auth_url = ENV['OS_AUTH_URL']
    os.openstack_compute_url = ENV['OS_COMPUTE_URL']
    os.tenant_name = ENV['OS_TENANT_NAME']
    os.keypair_name = "julien-vagrant"
    os.ssh_username = "stack"
  end
end
