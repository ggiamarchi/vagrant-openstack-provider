require 'vagrant'
require 'colorize'

module VagrantPlugins
  module Openstack
    class Config < Vagrant.plugin('2', :config)
      # The API key to access Openstack.
      #
      attr_accessor :password

      # The compute service url to access Openstack. If nil, it will read from
      # hypermedia catalog form REST API
      #
      attr_accessor :openstack_compute_url

      # The network service url to access Openstack. If nil, it will read from
      # hypermedia catalog form REST API
      #
      attr_accessor :openstack_network_url

      # The block storage service url to access Openstack. If nil, it will read from
      # hypermedia catalog form REST API
      #
      attr_accessor :openstack_volume_url

      # The authentication endpoint. This defaults to Openstack's global authentication endpoint.
      attr_accessor :openstack_auth_url

      # The flavor of server to launch, either the ID or name. This
      # can also be a regular expression to partially match a name.
      attr_accessor :flavor

      # The name or ID of the image to use. This can also be a regular
      # expression to partially match a name.
      attr_accessor :image

      # Volume to boot the vm from
      #
      attr_accessor :volume_boot

      #
      # The name of the openstack project on witch the vm will be created.
      #
      attr_accessor :tenant_name

      # The name of the server. This defaults to the name of the machine
      # defined by Vagrant (via `config.vm.define`), but can be overriden
      # here.
      attr_accessor :server_name

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

      # The SSH timeout use after server creation. If server startup is too long
      # the timeout value can be increase with this variable. Default is 60 seconds
      #
      # @return [Integer]
      attr_accessor :ssh_timeout

      # Opt files/directories in to the rsync operation performed by this provider
      #
      # @return [Array]
      attr_accessor :rsync_includes

      # The floating IP address from the IP pool which will be assigned to the instance.
      #
      # @return [String]
      attr_accessor :floating_ip

      # The floating IP pool from where new IPs will be allocated
      #
      # @return [String]
      attr_accessor :floating_ip_pool

      # if set to true, vagrant will always allocate floating ip instead of trying to reuse unassigned ones
      # default to false
      #
      # @return [Boolean]
      attr_accessor :floating_ip_pool_always_allocate

      # Sync folder method. Can be either "rsync" or "none"
      #
      # @return [String]
      attr_accessor :sync_method

      # Network list the VM will be connected to
      #
      # @return [Array]
      attr_accessor :networks

      # Volumes list that will be attached to the VM
      #
      # @return [Array]
      attr_accessor :volumes

      # Public key path to create OpenStack keypair
      #
      # @return [Array]
      attr_accessor :public_key_path

      # Availability Zone
      #
      # @return [String]
      attr_accessor :availability_zone

      # Pass hints to the OpenStack scheduler, e.g. { "cell": "some cell name" }
      attr_accessor :scheduler_hints

      # List of strings representing the security groups to apply.
      # e.g. ['ssh', 'http']
      #
      # @return [Array[String]]
      attr_accessor :security_groups

      # User data to be sent to the newly created OpenStack instance. Use this
      # e.g. to inject a script at boot time.
      #
      # @return [String]
      attr_accessor :user_data

      # A Hash of metadata that will be sent to the instance for configuration
      #
      # @return [Hash]
      attr_accessor :metadata

      # Flag to enable/disable all SSH actions (to use for instance on private networks)
      #
      # @return [Boolean]
      attr_accessor :ssh_disabled

      def initialize
        @password = UNSET_VALUE
        @openstack_compute_url = UNSET_VALUE
        @openstack_network_url = UNSET_VALUE
        @openstack_volume_url = UNSET_VALUE
        @openstack_auth_url = UNSET_VALUE
        @flavor = UNSET_VALUE
        @image = UNSET_VALUE
        @volume_boot = UNSET_VALUE
        @tenant_name = UNSET_VALUE
        @server_name = UNSET_VALUE
        @username = UNSET_VALUE
        @rsync_includes = []
        @keypair_name = UNSET_VALUE
        @ssh_username = UNSET_VALUE
        @ssh_timeout = UNSET_VALUE
        @floating_ip = UNSET_VALUE
        @floating_ip_pool = UNSET_VALUE
        @floating_ip_pool_always_allocate = UNSET_VALUE
        @sync_method = UNSET_VALUE
        @availability_zone = UNSET_VALUE
        @networks = []
        @volumes = []
        @public_key_path = UNSET_VALUE
        @scheduler_hints = UNSET_VALUE
        @security_groups = UNSET_VALUE
        @user_data = UNSET_VALUE
        @metadata = UNSET_VALUE
        @ssh_disabled = UNSET_VALUE
      end

      # rubocop:disable Style/CyclomaticComplexity
      def finalize!
        @password = nil if @password == UNSET_VALUE
        @openstack_compute_url = nil if @openstack_compute_url == UNSET_VALUE
        @openstack_network_url = nil if @openstack_network_url == UNSET_VALUE
        @openstack_volume_url = nil if @openstack_volume_url == UNSET_VALUE
        @openstack_auth_url = nil if @openstack_auth_url == UNSET_VALUE
        @flavor = nil if @flavor == UNSET_VALUE
        @image = nil if @image == UNSET_VALUE
        @volume_boot = nil if @volume_boot == UNSET_VALUE
        @tenant_name = nil if @tenant_name == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @rsync_includes = nil if @rsync_includes.empty?
        @floating_ip = nil if @floating_ip == UNSET_VALUE
        @floating_ip_pool = nil if @floating_ip_pool == UNSET_VALUE
        @floating_ip_pool_always_allocate = false if floating_ip_pool_always_allocate == UNSET_VALUE
        @sync_method = 'rsync' if @sync_method == UNSET_VALUE
        @keypair_name = nil if @keypair_name == UNSET_VALUE
        @public_key_path = nil if @public_key_path == UNSET_VALUE
        @availability_zone = nil if @availability_zone == UNSET_VALUE
        @scheduler_hints = nil if @scheduler_hints == UNSET_VALUE
        @security_groups = nil if @security_groups == UNSET_VALUE
        @user_data = nil if @user_data == UNSET_VALUE
        @metadata = nil if @metadata == UNSET_VALUE
        @ssh_disabled = false if @ssh_disabled == UNSET_VALUE

        # The SSH values by default are nil, and the top-level config
        # `config.ssh` values are used.
        @ssh_username = nil if @ssh_username == UNSET_VALUE
        @ssh_timeout = 180 if @ssh_timeout == UNSET_VALUE
        @networks = nil if @networks.empty?
        @volumes = nil if @volumes.empty?
      end
      # rubocop:enable Style/CyclomaticComplexity

      def rsync_include(inc)
        @rsync_includes << inc
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t('vagrant_openstack.config.password_required') unless @password
        errors << I18n.t('vagrant_openstack.config.username_required') unless @username

        validate_ssh_username(machine, errors)
        validate_ssh_timeout(errors)

        if machine.config.ssh.private_key_path
          puts I18n.t('vagrant_openstack.config.keypair_name_required').yellow unless @keypair_name || @public_key_path
        else
          errors << I18n.t('vagrant_openstack.config.private_key_missing') if @keypair_name || @public_key_path
        end

        {
          openstack_compute_url: @openstack_compute_url,
          openstack_network_url: @openstack_network_url,
          openstack_volume_url: @openstack_volume_url,
          openstack_auth_url: @openstack_auth_url
        }.each_pair do |key, value|
          errors << I18n.t('vagrant_openstack.config.invalid_uri', key: key, uri: value) unless value.nil? || valid_uri?(value)
        end

        { 'Openstack Provider' => errors }
      end

      private

      def validate_ssh_username(machine, errors)
        puts I18n.t('vagrant_openstack.config.ssh_username_deprecated').yellow if @ssh_username
        errors << I18n.t('vagrant_openstack.config.ssh_username_required') unless @ssh_username || machine.config.ssh.username
      end

      def validate_ssh_timeout(errors)
        return if @ssh_timeout.nil? || @ssh_timeout == UNSET_VALUE
        @ssh_timeout = Integer(@ssh_timeout) if @ssh_timeout.is_a? String
      rescue ArgumentError
        errors << I18n.t('vagrant_openstack.config.invalid_value_for_parameter', parameter: 'ssh_timeout', value: @ssh_timeout)
      end

      def valid_uri?(value)
        uri = URI.parse value
        uri.is_a?(URI::HTTP)
      end
    end
  end
end
