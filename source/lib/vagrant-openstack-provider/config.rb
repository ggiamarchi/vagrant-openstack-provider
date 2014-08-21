require 'vagrant'

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

      # The authentication endpoint. This defaults to Openstack's global authentication endpoint.
      attr_accessor :openstack_auth_url

      # The flavor of server to launch, either the ID or name. This
      # can also be a regular expression to partially match a name.
      attr_accessor :flavor

      # The name or ID of the image to use. This can also be a regular
      # expression to partially match a name.
      attr_accessor :image

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

      # Sync folder method. Can be either "rsync" or "none"
      #
      # @return [String]
      attr_accessor :sync_method

      # Network list the VM will be connected to
      #
      # @return [Array]
      attr_accessor :networks

      # Public key path to create OpenStack keypair
      #
      # @return [Array]
      attr_accessor :public_key_path

      def initialize
        @password = UNSET_VALUE
        @openstack_compute_url = UNSET_VALUE
        @openstack_network_url = UNSET_VALUE
        @openstack_auth_url = UNSET_VALUE
        @flavor = UNSET_VALUE
        @image = UNSET_VALUE
        @tenant_name = UNSET_VALUE
        @server_name = UNSET_VALUE
        @username = UNSET_VALUE
        @rsync_includes = []
        @keypair_name = UNSET_VALUE
        @ssh_username = UNSET_VALUE
        @ssh_timeout = UNSET_VALUE
        @floating_ip = UNSET_VALUE
        @floating_ip_pool = UNSET_VALUE
        @sync_method = UNSET_VALUE
        @networks = []
        @public_key_path = UNSET_VALUE
      end

      # rubocop:disable Style/CyclomaticComplexity
      def finalize!
        @password = nil if @password == UNSET_VALUE
        @openstack_compute_url = nil if @openstack_compute_url == UNSET_VALUE
        @openstack_network_url = nil if @openstack_network_url == UNSET_VALUE
        @openstack_auth_url = nil if @openstack_auth_url == UNSET_VALUE
        @flavor = nil if @flavor == UNSET_VALUE
        @image = nil if @image == UNSET_VALUE
        @tenant_name = nil if @tenant_name == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @rsync_includes = nil if @rsync_includes.empty?
        @floating_ip = nil if @floating_ip == UNSET_VALUE
        @floating_ip_pool = nil if @floating_ip_pool == UNSET_VALUE
        @sync_method = 'rsync' if @sync_method == UNSET_VALUE
        @keypair_name = nil if @keypair_name == UNSET_VALUE
        @public_key_path = nil if @public_key_path == UNSET_VALUE

        # The SSH values by default are nil, and the top-level config
        # `config.ssh` values are used.
        @ssh_username = nil if @ssh_username == UNSET_VALUE
        @ssh_timeout = 180 if @ssh_timeout == UNSET_VALUE
        @networks = nil if @networks.empty?
      end
      # rubocop:enable Style/CyclomaticComplexity

      def rsync_include(inc)
        @rsync_includes << inc
      end

      def validate(_machine)
        errors = _detected_errors

        errors << I18n.t('vagrant_openstack.config.password_required') unless @password
        errors << I18n.t('vagrant_openstack.config.username_required') unless @username
        errors << I18n.t('vagrant_openstack.config.keypair_name_required') unless @keypair_name || @public_key_path

        {
          openstack_compute_url: @openstack_compute_url,
          openstack_network_url: @openstack_network_url,
          openstack_auth_url: @openstack_auth_url
        }.each_pair do |key, value|
          errors << I18n.t('vagrant_openstack.config.invalid_uri', key: key, uri: value) unless value.nil? || valid_uri?(value)
        end

        { 'Openstack Provider' => errors }
      end

      private

      def valid_uri?(value)
        uri = URI.parse value
        uri.kind_of?(URI::HTTP)
      end
    end
  end
end
