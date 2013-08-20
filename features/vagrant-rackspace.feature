@announce
@vagrant-rackspace
Feature: vagrant-rackspace fog tests
  As a Fog developer
  I want to smoke (or "fog") test vagrant-rackspace.
  So I am confident my upstream changes did not create downstream problems.

  Background:
    Given I have Rackspace credentials available
    # Will likely inject Fog.mock! configuration here in the future

  Scenario: Create a single server
    Given a file named "Vagrantfile" with:
    """
    # Testing options
    require File.expand_path '../fog_mock', __FILE__

    Vagrant.configure("2") do |config|
      # dev/test method of loading plugin, normally would be 'vagrant plugin install vagrant-rackspace'
      Vagrant.require_plugin "vagrant-rackspace"

      config.vm.box = "dummy"
      config.ssh.username = "vagrant" if Fog.mock?
      config.ssh.private_key_path = "~/.ssh/id_rsa" unless Fog.mock?
      config.ssh.max_tries     = 1
      config.ssh.timeout       = 10

      config.vm.provider :rackspace do |rs|
        rs.server_name = 'vagrant-single-server'
        rs.username = ENV['RAX_USERNAME']
        rs.api_key  = ENV['RAX_API_KEY']
        rs.region   = ENV['RAX_REGION']
        rs.flavor   = /512MB/
        rs.image    = /Ubuntu/
        rs.public_key_path = "~/.ssh/id_rsa.pub" unless Fog.mock?
      end
    end
    """
    When I successfully run `bundle exec vagrant up --provider rackspace`
    # I want to capture the ID like I do in tests for other tools, but Vagrant doesn't print it!
    # And I get the server from "Instance ID:"
    Then the server "vagrant-single-server" should be active
