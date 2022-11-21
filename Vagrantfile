# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  config.vm.provider 'virtualbox' do |vb|
    vb.memory = 8192
  end

  config.vm.box = "ubuntu/focal64"

  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provision "shell", path: "dev/provisioning/main.sh", privileged: false
end
