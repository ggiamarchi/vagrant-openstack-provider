require 'vagrant-openstack-provider'

Vagrant.configure('2') do |config|

  config.vm.box = 'openstack'

  config.ssh.username = ENV['OS_SSH_USERNAME']

  config.vm.provider :openstack do |os|
    os.endpoint_type         = ENV['OS_ENDPOINT_TYPE']
    os.openstack_auth_url    = ENV['OS_AUTH_URL']
    os.tenant_name           = ENV['OS_TENANT_NAME']
    os.username              = ENV['OS_USERNAME']
    os.password              = ENV['OS_PASSWORD']
    os.floating_ip_pool      = ENV['OS_FLOATING_IP_POOL']
    os.flavor                = ENV['OS_FLAVOR']
    os.image                 = ENV['OS_IMAGE']
  end

  config.vm.provision "shell", inline: "echo 'ok' > ~/provision"
end
