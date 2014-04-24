When(/^I get the server from "(.*?)"$/) do |label|
  @server_id = all_output.match(/#{label}\s([\w-]*)/)[1]
  puts "Server: #{@server_id}"
end

When(/^I load the server$/) do
  @server_id = all_output.strip.lines.to_a.last
  puts "Server: #{@server_id}"
end

Then(/^the server should be active$/) do
  unless Fog.mock? # unfortunately we can't assert this with Fog.mock!, since mocked objects do not persist from the subprocess
    assert_active @server_id
  end
end

Then(/^the server "(.+)" should be active$/) do |server_name|
  server = @compute.servers.all.find{|s| s.name == server_name}
  assert_active server.id
end

def assert_active server_id
  server = @compute.servers.get server_id
  server.state.should == 'ACTIVE'
end