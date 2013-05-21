require "vagrant"

module VagrantPlugins
  module Rackspace
    class Config < Vagrant.plugin("2", :config)
      # The API key to access RackSpace.
      #
      # @return [String]
      attr_accessor :api_key

      # The endpoint to access RackSpace. If nil, it will default
      # to DFW.
      #
      # @return [String]
      attr_accessor :endpoint

      # The flavor of server to launch, either the ID or name. This
      # can also be a regular expression to partially match a name.
      attr_accessor :flavor

      # The name or ID of the image to use. This can also be a regular
      # expression to partially match a name.
      attr_accessor :image

      # The path to the public key to set up on the remote server for SSH.
      # This should match the private key configured with `config.ssh.private_key_path`.
      #
      # @return [String]
      attr_accessor :public_key_path

      # The option that indicates RackConnect usage or not.
      #
      # @return [Boolean]
      attr_accessor :rackconnect

      # The name of the server. This defaults to the name of the machine
      # defined by Vagrant (via `config.vm.define`), but can be overriden
      # here.
      attr_accessor :server_name

      # The username to access RackSpace.
      #
      # @return [String]
      attr_accessor :username

      def initialize
        @api_key  = UNSET_VALUE
        @endpoint = UNSET_VALUE
        @flavor   = UNSET_VALUE
        @image    = UNSET_VALUE
        @public_key_path = UNSET_VALUE
        @rackconnect = UNSET_VALUE
        @server_name = UNSET_VALUE
        @username = UNSET_VALUE
      end

      def finalize!
        @api_key  = nil if @api_key == UNSET_VALUE
        @endpoint = nil if @endpoint == UNSET_VALUE
        @flavor   = /512MB/ if @flavor == UNSET_VALUE
        @image    = /Ubuntu/ if @image == UNSET_VALUE
        @rackconnect = false if @rackconnect == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE

        if @public_key_path == UNSET_VALUE
          @public_key_path = Vagrant.source_root.join("keys/vagrant.pub")
        end
      end

      def validate(machine)
        errors = []

        errors << I18n.t("vagrant_rackspace.config.api_key_required") if !@api_key
        errors << I18n.t("vagrant_rackspace.config.username_required") if !@username

        public_key_path = File.expand_path(@public_key_path, machine.env.root_path)
        if !File.file?(public_key_path)
          errors << I18n.t("vagrant_rackspace.config.public_key_not_found")
        end

        { "RackSpace Provider" => errors }
      end
    end
  end
end
