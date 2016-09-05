require 'vagrant'
require 'colorize'
require 'vagrant-openstack-provider/config/http'

module VagrantPlugins
  module Openstack
    class Config < Vagrant.plugin('2', :config)
      # The API key to access Openstack.
      #
      attr_accessor :password

      # The compute service url to access Openstack. If nil, it will read from hypermedia catalog form REST API
      #
      attr_accessor :openstack_compute_url

      # The network service url to access Openstack. If nil, it will read from hypermedia catalog form REST API
      #
      attr_accessor :openstack_network_url

      # The block storage service url to access Openstack. If nil, it will read from hypermedia catalog form REST API
      #
      attr_accessor :openstack_volume_url

      # The orchestration service url to access Openstack. If nil, it will read from hypermedia catalog form REST API
      #
      attr_accessor :openstack_orchestration_url

      # The image service url to access Openstack. If nil, it will read from hypermedia catalog form REST API
      #
      attr_accessor :openstack_image_url

      # The authentication endpoint. This defaults to Openstack's global authentication endpoint.
      attr_accessor :openstack_auth_url

      # Openstack region
      attr_accessor :region

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

      # The SSH timeout use after server creation.
      #
      # Deprecated. Use config.vm.boot_timeout instead.
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

      # Sync folder ignore files. A list of files containing exclude patterns to ignore in the rsync operation
      #  performed by this provider
      #
      # @return [Array]
      attr_accessor :rsync_ignore_files

      # Sync folder ignore paths. A list of paths to ignore in the rsync operation performed by this provider
      #
      # @return [Array]
      attr_accessor :rsync_exclude_paths

      # Sync folder ignore CVS excludes. A boolean flag to control the --cvs-exclude option for rsync. Default: true.
      #
      # @return [Boolean]
      attr_accessor :rsync_cvs_exclude

      # Network list the VM will be connected to
      #
      # @return [Array]
      attr_accessor :networks

      # Volumes list that will be attached to the VM
      #
      # @return [Array]
      attr_accessor :volumes

      # Stack that will be created and associated to the instances
      #
      # @return [Array]
      attr_accessor :stacks

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

      # Specify the endpoint_type to use : publicURL, adminURL, or internalURL (default is publicURL)
      #
      # @return [String]
      attr_accessor :endpoint_type

      #
      # @return [Integer]
      attr_accessor :server_create_timeout

      #
      # @return [Integer]
      attr_accessor :server_active_timeout

      #
      # @return [Integer]
      attr_accessor :server_stop_timeout

      #
      # @return [Integer]
      attr_accessor :server_delete_timeout

      #
      # @return [Integer]
      attr_accessor :stack_create_timeout

      #
      # @return [Integer]
      attr_accessor :stack_delete_timeout

      #
      # @return [HttpConfig]
      attr_accessor :http

      #
      # @return [Boolean]
      attr_accessor :meta_args_support

      def initialize
        @password = UNSET_VALUE
        @openstack_compute_url = UNSET_VALUE
        @openstack_network_url = UNSET_VALUE
        @openstack_volume_url = UNSET_VALUE
        @openstack_orchestration_url = UNSET_VALUE
        @openstack_image_url = UNSET_VALUE
        @openstack_auth_url = UNSET_VALUE
        @endpoint_type = UNSET_VALUE
        @region = UNSET_VALUE
        @flavor = UNSET_VALUE
        @image = UNSET_VALUE
        @volume_boot = UNSET_VALUE
        @tenant_name = UNSET_VALUE
        @server_name = UNSET_VALUE
        @username = UNSET_VALUE
        @rsync_includes = []
        @rsync_ignore_files = []
        @rsync_exclude_paths = []
        @rsync_cvs_exclude = UNSET_VALUE
        @keypair_name = UNSET_VALUE
        @ssh_username = UNSET_VALUE
        @ssh_timeout = UNSET_VALUE
        @floating_ip = UNSET_VALUE
        @floating_ip_pool = []
        @floating_ip_pool_always_allocate = UNSET_VALUE
        @sync_method = UNSET_VALUE
        @availability_zone = UNSET_VALUE
        @networks = []
        @stacks = []
        @volumes = []
        @public_key_path = UNSET_VALUE
        @scheduler_hints = UNSET_VALUE
        @security_groups = UNSET_VALUE
        @user_data = UNSET_VALUE
        @metadata = UNSET_VALUE
        @ssh_disabled = UNSET_VALUE
        @server_create_timeout = UNSET_VALUE
        @server_active_timeout = UNSET_VALUE
        @server_stop_timeout = UNSET_VALUE
        @server_delete_timeout = UNSET_VALUE
        @stack_create_timeout = UNSET_VALUE
        @stack_delete_timeout = UNSET_VALUE
        @meta_args_support = UNSET_VALUE
        @http = HttpConfig.new
      end

      def merge(other)
        result = self.class.new

        # Set all of our instance variables on the new class
        [self, other].each do |obj|
          obj.instance_variables.each do |key|
            # Ignore keys that start with a double underscore. This allows
            # configuration classes to still hold around internal state
            # that isn't propagated.
            next if key.to_s.start_with?('@__')

            # Let user inputs a string or an array for floating ip pool attribute
            obj.floating_ip_pool = [obj.floating_ip_pool].flatten if key.eql?(:@floating_ip_pool) && !obj.floating_ip_pool.nil?

            # Let user inputs a string or an array for networks attribute
            obj.networks = [obj.networks].flatten if key.eql?(:@networks) && !obj.networks.nil?

            # Don't set the value if it is the unset value, either.
            value = obj.instance_variable_get(key)

            if [:@networks, :@volumes, :@rsync_includes, :@rsync_ignore_files, :@rsync_exclude_paths, :@floating_ip_pool, :@stacks].include? key
              result.instance_variable_set(key, value) unless value.empty?
            elsif [:@http].include? key
              result.instance_variable_set(key, instance_variable_get(key).merge(other.instance_variable_get(key))) if value != UNSET_VALUE
            else
              result.instance_variable_set(key, value) if value != UNSET_VALUE
            end
          end
        end

        # Persist through the set of invalid methods
        this_invalid  = @__invalid_methods || Set.new
        other_invalid = other.instance_variable_get(:"@__invalid_methods") || Set.new
        result.instance_variable_set(:"@__invalid_methods", this_invalid + other_invalid)

        result
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def finalize!
        @password = nil if @password == UNSET_VALUE
        @openstack_compute_url = nil if @openstack_compute_url == UNSET_VALUE
        @openstack_network_url = nil if @openstack_network_url == UNSET_VALUE
        @openstack_orchestration_url = nil if @openstack_orchestration_url == UNSET_VALUE
        @openstack_volume_url = nil if @openstack_volume_url == UNSET_VALUE
        @openstack_image_url = nil if @openstack_image_url == UNSET_VALUE
        @openstack_auth_url = nil if @openstack_auth_url == UNSET_VALUE
        @endpoint_type = 'publicURL' if @endpoint_type == UNSET_VALUE
        @region = nil if @region == UNSET_VALUE
        @flavor = nil if @flavor == UNSET_VALUE
        @image = nil if @image == UNSET_VALUE
        @volume_boot = nil if @volume_boot == UNSET_VALUE
        @tenant_name = nil if @tenant_name == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @rsync_includes = nil if @rsync_includes.empty?
        @rsync_ignore_files = nil if @rsync_ignore_files.empty?
        @rsync_exclude_paths = nil if @rsync_exclude_paths == UNSET_VALUE
        @rsync_cvs_exclude = true if @rsync_exclude_paths == UNSET_VALUE
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
        # `config.ssh` and `config.vm.boot_timeout` values are used.
        @ssh_username = nil if @ssh_username == UNSET_VALUE
        @ssh_timeout = nil if @ssh_timeout == UNSET_VALUE

        @server_create_timeout = 200 if @server_create_timeout == UNSET_VALUE
        @server_active_timeout = 200 if @server_active_timeout == UNSET_VALUE
        @server_stop_timeout = 200 if @server_stop_timeout == UNSET_VALUE
        @server_delete_timeout = 200 if @server_delete_timeout == UNSET_VALUE
        @stack_create_timeout = 200 if @stack_create_timeout == UNSET_VALUE
        @stack_delete_timeout = 200 if @stack_delete_timeout == UNSET_VALUE
        @meta_args_support = false if @meta_args_support == UNSET_VALUE
        @networks = nil if @networks.empty?
        @volumes = nil if @volumes.empty?
        @stacks = nil if @stacks.empty?
        @http.finalize!
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def rsync_include(inc)
        @rsync_includes << inc
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t('vagrant_openstack.config.password_required') if @password.nil? || @password.empty?
        errors << I18n.t('vagrant_openstack.config.username_required') if @username.nil? || @username.empty?
        errors << I18n.t('vagrant_openstack.config.tenant_name_required') if @tenant_name.nil? || @tenant_name.empty?
        errors << I18n.t('vagrant_openstack.config.invalid_endpoint_type') unless  %w(publicURL adminURL internalURL).include?(@endpoint_type)

        validate_ssh_username(machine, errors)
        validate_stack_config(errors)
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
          openstack_orchestration_url: @openstack_orchestration_url,
          openstack_image_url: @openstack_image_url,
          openstack_auth_url: @openstack_auth_url
        }.each_pair do |key, value|
          errors << I18n.t('vagrant_openstack.config.invalid_uri', key: key, uri: value) unless value.nil? || valid_uri?(value)
        end

        { 'Openstack Provider' => errors }
      end

      private

      def validate_stack_config(errors)
        @stacks.each do |stack|
          errors << I18n.t('vagrant_openstack.config.invalid_stack') unless stack[:name] && stack[:template]
        end unless @stacks.nil?
      end

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
