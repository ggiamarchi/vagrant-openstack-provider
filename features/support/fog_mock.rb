require 'fog'
if ENV['RAX_MOCK'] == 'true'
    Fog.mock!
    Fog::Rackspace::MockData.configure do |c|
        c[:image_name_generator] = Proc.new { "Ubuntu" }
        c[:ipv4_generator] = Proc.new { "10.11.12.2"}
    end
    connect_options = {
        :provider             => 'rackspace',
        :rackspace_username   => ENV['RAX_USERNAME'],
        :rackspace_api_key    => ENV['RAX_API_KEY'],
        :version => :v2, # Use Next Gen Cloud Servers
        :rackspace_region => :ord #Use Chicago Region
    } 
    connect_options.merge!(proxy_options) unless ENV['https_proxy'].nil?
    compute = Fog::Compute.new(connect_options)
    # Force creation of Ubuntu image so it will show up in compute.images.list
    compute.images.get(0)
end