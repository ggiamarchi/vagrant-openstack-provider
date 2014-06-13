require "vagrant"

module VagrantPlugins
  module Openstack
    class Config < Vagrant.plugin("2", :config)
      # The API key to access Openstack.
      #
      # @return [String]
      attr_accessor :password

      # The compute_url to access Openstack. If nil, it will default
      # to DFW.
      # (formerly know as 'endpoint')
      #
      # expected to be a string url -
      # 'https://dfw.servers.api.openstackcloud.com/v2'
      # 'https://ord.servers.api.openstackcloud.com/v2'
      # 'https://lon.servers.api.openstackcloud.com/v2'
      attr_accessor :openstack_compute_url

      # The authenication endpoint. This defaults to Openstack's global authentication endpoint.
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

      # Sync folder method. Can be either "rsync" or "none"
      #
      # @return [String]
      attr_accessor :sync_method

      def initialize
        @password = UNSET_VALUE
        @openstack_compute_url = UNSET_VALUE
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
        @sync_method = UNSET_VALUE
      end

      def finalize!
        @password = nil if @password == UNSET_VALUE
        @openstack_compute_url = nil if @openstack_compute_url == UNSET_VALUE
        @openstack_auth_url = nil if @openstack_auth_url == UNSET_VALUE
        @flavor = nil if @flavor == UNSET_VALUE
        @image = nil if @image == UNSET_VALUE    # TODO No default value
        @tenant_name = nil if @tenant_name == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @rsync_includes = nil if @rsync_includes.empty?
        @floating_ip = nil if @floating_ip == UNSET_VALUE
        @sync_method = "rsync" if @sync_method == UNSET_VALUE

        # Keypair defaults to nil
        @keypair_name = nil if @keypair_name == UNSET_VALUE

        # The SSH values by default are nil, and the top-level config
        # `config.ssh` values are used.
        @ssh_username = nil if @ssh_username == UNSET_VALUE
        @ssh_timeout = 60 if @ssh_timeout == UNSET_VALUE
      end

      def rsync_include(inc)
        @rsync_includes << inc
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t("vagrant_openstack.config.password_required") if !@password
        errors << I18n.t("vagrant_openstack.config.username_required") if !@username
        errors << I18n.t("vagrant_openstack.config.keypair_name_required") if !@keypair_name

        {
          :openstack_compute_url => @openstack_compute_url,
          :openstack_auth_url => @openstack_auth_url
        }.each_pair do |key, value|
          errors << I18n.t("vagrant_openstack.config.invalid_uri", :key => key, :uri => value) unless value.nil? || valid_uri?(value)
        end

        { "Openstack Provider" => errors }
      end

      private

      def valid_uri? value
        uri = URI.parse value
        uri.kind_of?(URI::HTTP)
      end
    end
  end
end
