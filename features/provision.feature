@announce
@vagrant-rackspace
Feature: vagrant-rackspace fog tests

  Background:
    Given I have Rackspace credentials available
    And I have a "fog_mock.rb" file

  Scenario: Create a single server (with provisioning)
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure("2") do |config|
      Vagrant.require_plugin "vagrant-rackspace"

      config.vm.box = "dummy"
      config.ssh.private_key_path = "~/.ssh/id_rsa"


      config.vm.provider :rackspace do |rs|
        rs.server_name = 'vagrant-provisioned-server'
        rs.username = ENV['RAX_USERNAME']
        rs.api_key  = ENV['RAX_API_KEY']
        rs.rackspace_region   = ENV['RAX_REGION'].downcase.to_sym
        rs.flavor   = /1 GB Performance/
        rs.image    = /Ubuntu/
        rs.public_key_path = "~/.ssh/id_rsa.pub"
      end

      config.vm.provision :shell, :inline => "echo Hello, World"
    end
    """
    When I successfully run `bundle exec vagrant up --provider rackspace`
    # I want to capture the ID like I do in tests for other tools, but Vagrant doesn't print it!
    # And I get the server from "Instance ID:"
    Then the server "vagrant-provisioned-server" should be active