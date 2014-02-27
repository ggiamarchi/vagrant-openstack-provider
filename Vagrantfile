require 'vagrant-openstack'

Vagrant.configure("2") do |config|

  config.vm.box = "dummy-openstack"
  config.vm.box_url = "https://github.com/cloudbau/vagrant-openstack-plugin/raw/master/dummy.box"

  config.ssh.private_key_path = "/home/guillaume/Documents/aptanawks/vagrant-rackspace/key-vagrant.pem"
  config.ssh.shell = "sh"

  config.vm.provider :openstack do |os|

    os.server_name = "vagrant-os-plugin-test"
    os.username = "admin"
    os.floating_ip = "172.24.4.5"
    os.api_key = "password"
    os.network = "private"
    os.flavor = /m1.tiny/
    os.image = /test/
    os.openstack_auth_url = "http://192.168.27.100:5000/v2.0/tokens"
    os.openstack_compute_url = "http://192.168.27.100:8774/v2/"
    os.availability_zone = "nova"
    os.tenant_name = "demo"
    os.keypair_name = "key-vagrant"
    os.ssh_username = "cirros"

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
