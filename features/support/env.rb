require 'fog'
require 'aruba/cucumber'

Fog.mock! if ENV['RAX_MOCK'] == 'true'

Before do | scenario |
    @aruba_timeout_seconds = 600
    @scenario = File.basename(scenario.file)
    ENV['CASSETTE'] = @scenario

    proxy_options = {
      :connection_options => {
        :proxy => ENV['https_proxy'],
        :ssl_verify_peer => false
      }
    }

    connect_options = {
        :provider             => 'rackspace',
        :rackspace_username   => ENV['RAX_USERNAME'],
        :rackspace_api_key    => ENV['RAX_API_KEY'],
        :version => :v2, # Use Next Gen Cloud Servers
        :rackspace_region => ENV['RAX_REGION'].downcase.to_sym
    }
    connect_options.merge!(proxy_options) unless ENV['https_proxy'].nil?
    @compute = Fog::Compute.new(connect_options)
end

Around do | scenario, block |
    Bundler.with_clean_env do
        block.call
    end
end

After('@creates_server') do
    @compute.servers.delete @server_id
end
