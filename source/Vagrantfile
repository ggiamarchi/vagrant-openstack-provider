require 'vagrant-openstack-provider'

Vagrant.configure("2") do |config|

  config.vm.box = "dummy-openstack"
  config.vm.box_url = "https://github.com/ggiamarchi/vagrant-openstack/raw/master/source/dummy.box"

  config.ssh.private_key_path = "/home/vagrant/.ssh/id_rsa"
  config.ssh.shell = "sh"

  config.vm.provider :openstack do |os|

    os.server_name = "vagrant-os-plugin-test"
    os.username = ENV['OS_USERNAME']
    os.floating_ip = "185.39.216.118"
    os.api_key = ENV['OS_PASSWORD']
    #os.network = "private"
    os.flavor = /Linux-XL.2plus-4vCpu-32G/
    os.image = /ubuntu-12.04_x86_64_LVM/
    os.openstack_auth_url = ENV['OS_AUTH_URL']
    os.openstack_compute_url = ENV['OS_COMPUTE_URL']
    os.availability_zone = "nova"
    os.tenant_name = ENV['OS_TENANT_NAME']
    os.keypair_name = "julien-vagrant"
    os.ssh_username = "stack"

#    os.metadata  = {"key" => "value"}                      # optional
#    os.user_data = "#cloud-config\nmanage_etc_hosts: True" # optional
#    os.networks           = [ "internal", "external" ]     # optional, overrides os.network
#    os.address_id         = "YOUR ADDRESS ID"              # optional (`network` above has higher precedence)
#    os.scheduler_hints    = {
#        :cell => 'australia'
#    }                                          # optional
#    os.security_groups    = ['ssh', 'http']    # optional

  end
end
