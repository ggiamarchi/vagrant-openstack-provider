require "vagrant"
require "fog"

module VagrantPlugins
  module Rackspace
    class Config < Vagrant.plugin("2", :config)
      # The API key to access RackSpace.
      #
      # @return [String]
      attr_accessor :api_key

      # The region to access RackSpace. If nil, it will default
      # to DFW.
      # (formerly know as 'endpoint')
      #
      # expected to be a symbol - :dfw (default), :ord, :lon
      #
      # Users should preference the rackspace_region setting over rackspace_compute_url
      attr_accessor :rackspace_region

      # The compute_url to access RackSpace. If nil, it will default
      # to DFW.
      # (formerly know as 'endpoint')
      #
      # expected to be a string url - 
      # 'https://dfw.servers.api.rackspacecloud.com/v2'
      # 'https://ord.servers.api.rackspacecloud.com/v2'
      # 'https://lon.servers.api.rackspacecloud.com/v2'
      #
      # alternatively, can use constants if you require 'fog/rackspace' in your Vagrantfile
      # Fog::Compute::RackspaceV2::DFW_ENDPOINT
      # Fog::Compute::RackspaceV2::ORD_ENDPOINT
      # Fog::Compute::RackspaceV2::LON_ENDPOINT
      #
      # Users should preference the rackspace_region setting over rackspace_compute_url
      attr_accessor :rackspace_compute_url

      # The authenication endpoint. This defaults to Rackspace's global authentication endpoint.
      # Users of the London data center should specify the following:
      # https://lon.identity.api.rackspacecloud.com/v2.0
      attr_writer :rackspace_auth_url

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

       # The disk configuration value.
       #   * AUTO -   The server is built with a single partition the size of the target flavor disk. The file system is automatically adjusted to fit the entire partition.
       #              This keeps things simple and automated. AUTO is valid only for images and servers with a single partition that use the EXT3 file system.
       #              This is the default setting for applicable Rackspace base images.
       #
       #   * MANUAL - The server is built using whatever partition scheme and file system is in the source image. If the target flavor disk is larger,
       #              the remaining disk space is left unpartitioned. This enables images to have non-EXT3 file systems, multiple partitions,
       #              and so on, and enables you to manage the disk configuration.
       #
       # This defaults to MANUAL
      attr_accessor :disk_config

      def initialize
        @api_key  = UNSET_VALUE
        @rackspace_region = UNSET_VALUE
        @rackspace_compute_url = UNSET_VALUE
        @rackspace_auth_url = UNSET_VALUE
        @flavor   = UNSET_VALUE
        @image    = UNSET_VALUE
        @public_key_path = UNSET_VALUE
        @rackconnect = UNSET_VALUE
        @server_name = UNSET_VALUE
        @username = UNSET_VALUE
        @disk_config = UNSET_VALUE
      end

      def finalize!
        @api_key  = nil if @api_key == UNSET_VALUE
        @rackspace_region = nil if @rackspace_region == UNSET_VALUE
        @rackspace_compute_url = nil if @rackspace_compute_url == UNSET_VALUE
        @rackspace_auth_url = nil if @rackspace_auth_url == UNSET_VALUE
        @flavor   = /512MB/ if @flavor == UNSET_VALUE
        @image    = /Ubuntu/ if @image == UNSET_VALUE
        @rackconnect = nil if @rackconnect == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @disk_config = nil if @disk_config == UNSET_VALUE

        if @public_key_path == UNSET_VALUE
          @public_key_path = Vagrant.source_root.join("keys/vagrant.pub")
        end
      end

      # @note Currently, you must authenticate against the UK authenication endpoint to access the London Data center.
      #     Hopefully this method makes the experience more seemless for users of the UK cloud.
      def rackspace_auth_url
        if (@rackspace_auth_url.nil? || @rackspace_auth_url == UNSET_VALUE) && lon_region?
          Fog::Rackspace::UK_AUTH_ENDPOINT
        else
          @rackspace_auth_url
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

      private

      def lon_region?
        rackspace_region && rackspace_region != UNSET_VALUE && rackspace_region.to_sym == :lon
      end
    end
  end
end
