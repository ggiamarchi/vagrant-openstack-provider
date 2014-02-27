require "vagrant"
require "fog"

module VagrantPlugins
  module Openstack
    class Config < Vagrant.plugin("2", :config)
      # The API key to access Openstack.
      #
      # @return [String]
      attr_accessor :api_key

      # The region to access Openstack. If nil, it will default
      # to DFW.
      # (formerly know as 'endpoint')
      #
      # expected to be a symbol - :dfw (default), :ord, :lon
      #
      # Users should preference the openstack_region setting over openstack_compute_url
      attr_accessor :openstack_region

      # The compute_url to access Openstack. If nil, it will default
      # to DFW.
      # (formerly know as 'endpoint')
      #
      # expected to be a string url -
      # 'https://dfw.servers.api.openstackcloud.com/v2'
      # 'https://ord.servers.api.openstackcloud.com/v2'
      # 'https://lon.servers.api.openstackcloud.com/v2'
      #
      # alternatively, can use constants if you require 'fog/openstack' in your Vagrantfile
      # Fog::Compute::OpenstackV2::DFW_ENDPOINT
      # Fog::Compute::OpenstackV2::ORD_ENDPOINT
      # Fog::Compute::OpenstackV2::LON_ENDPOINT
      #
      # Users should preference the openstack_region setting over openstack_compute_url
      attr_accessor :openstack_compute_url

      # The authenication endpoint. This defaults to Openstack's global authentication endpoint.
      # Users of the London data center should specify the following:
      # https://lon.identity.api.openstackcloud.com/v2.0
      attr_writer :openstack_auth_url

      # Network configurations for the instance
      #
      # @return [String]
      attr_accessor :network

      # The flavor of server to launch, either the ID or name. This
      # can also be a regular expression to partially match a name.
      attr_accessor :flavor

      # The name or ID of the image to use. This can also be a regular
      # expression to partially match a name.
      attr_accessor :image

      # Alternately, if a keypair were already uploaded to Openstack,
      # the key name could be provided.
      #
      # @return [String]
      attr_accessor :key_name

      # A Hash of metadata that will be sent to the instance for configuration
      #
      # @return [Hash]
      attr_accessor :metadata

      # The option that indicates RackConnect usage or not.
      #
      # @return [Boolean]
      attr_accessor :rackconnect

      #
      # The name of the openstack project on witch the vm will be created.
      #
      attr_accessor :tenant_name

      # The name of the server. This defaults to the name of the machine
      # defined by Vagrant (via `config.vm.define`), but can be overriden
      # here.
      attr_accessor :server_name

      # Specify the availability zone in which to create the instance
      attr_accessor :availability_zone

      # The username to access Openstack.
      #
      # @return [String]
      attr_accessor :username

      # The name of the keypair to use.
      #
      # @return [String]
      attr_accessor :keypair_name

      # The SSH username to use with this OpenStack instance. This overrides
      # the `config.ssh.username` variable.
      #
      # @return [String]
      attr_accessor :ssh_username

      # The disk configuration value.
      #   * AUTO -   The server is built with a single partition the size of the target flavor disk. The file system is automatically adjusted to fit the entire partition.
      #              This keeps things simple and automated. AUTO is valid only for images and servers with a single partition that use the EXT3 file system.
      #              This is the default setting for applicable Openstack base images.
      #
      #   * MANUAL - The server is built using whatever partition scheme and file system is in the source image. If the target flavor disk is larger,
      #              the remaining disk space is left unpartitioned. This enables images to have non-EXT3 file systems, multiple partitions,
      #              and so on, and enables you to manage the disk configuration.
      #
      # This defaults to MANUAL
      attr_accessor :disk_config

      # Opt files/directories in to the rsync operation performed by this provider
      #
      # @return [Array]
      attr_accessor :rsync_includes

      # The floating IP address from the IP pool which will be assigned to the instance.
      #
      # @return [String]
      attr_accessor :floating_ip

      def initialize
        @api_key = UNSET_VALUE
        @openstack_region = UNSET_VALUE
        @openstack_compute_url = UNSET_VALUE
        @openstack_auth_url = UNSET_VALUE
        @flavor = UNSET_VALUE
        @image = UNSET_VALUE
        @rackconnect = UNSET_VALUE
        @availability_zone = UNSET_VALUE
        @tenant_name = UNSET_VALUE
        @server_name = UNSET_VALUE
        @username = UNSET_VALUE
        @disk_config = UNSET_VALUE
        @network = UNSET_VALUE
        @rsync_includes = []
        @keypair_name = UNSET_VALUE
        @ssh_username = UNSET_VALUE
        @floating_ip = UNSET_VALUE
      end

      def finalize!
        @api_key = nil if @api_key == UNSET_VALUE
        @openstack_region = nil if @openstack_region == UNSET_VALUE
        @openstack_compute_url = nil if @openstack_compute_url == UNSET_VALUE
        @openstack_auth_url = nil if @openstack_auth_url == UNSET_VALUE
        @flavor = /m1.tiny/ if @flavor == UNSET_VALUE # TODO No default value
        @image = /cirros/ if @image == UNSET_VALUE    # TODO No default value
        @rackconnect = nil if @rackconnect == UNSET_VALUE
        @availability_zone = nil if @availability_zone == UNSET_VALUE
        @tenant_name = nil if @tenant_name == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @metadata = nil if @metadata == UNSET_VALUE
        @network = nil if @network == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @disk_config = nil if @disk_config == UNSET_VALUE
        @rsync_includes = nil if @rsync_includes.empty?
        @floating_ip = nil if @floating_ip == UNSET_VALUE

        # Keypair defaults to nil
        @keypair_name = nil if @keypair_name == UNSET_VALUE

        # The SSH values by default are nil, and the top-level config
        # `config.ssh` values are used.
        @ssh_username = nil if @ssh_username == UNSET_VALUE
      end

      # @note Currently, you must authenticate against the UK authenication endpoint to access the London Data center.
      #     Hopefully this method makes the experience more seemless for users of the UK cloud.
      def openstack_auth_url
        if (@openstack_auth_url.nil? || @openstack_auth_url == UNSET_VALUE) && lon_region?
          Fog::Openstack::UK_AUTH_ENDPOINT
        else
          @openstack_auth_url
        end
      end

      def rsync_include(inc)
        @rsync_includes << inc
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t("vagrant_openstack.config.api_key required") if !@api_key
        errors << I18n.t("vagrant_openstack.config.username required") if !@username
        errors << I18n.t("vagrant_openstack.config.keypair_name required") if !@keypair_name

        {
          :openstack_compute_url => @openstack_compute_url,
          :openstack_auth_url => @openstack_auth_url
        }.each_pair do |key, value|
          errors << I18n.t("vagrant_openstack.config.invalid_uri", :key => key, :uri => value) unless value.nil? || valid_uri?(value)
        end

        { "Openstack Provider" => errors }
      end

      private

      def lon_region?
        openstack_region && openstack_region != UNSET_VALUE && openstack_region.to_sym == :lon
      end

      private

      def valid_uri? value
        uri = URI.parse value
        uri.kind_of?(URI::HTTP)
      end
    end
  end
end
