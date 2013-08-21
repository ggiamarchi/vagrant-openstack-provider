Given(/^I have Rackspace credentials available$/) do
  fail unless ENV['RAX_USERNAME'] && ENV['RAX_API_KEY']
end

Given(/^I have a "fog_mock.rb" file$/) do
  script = File.open("features/support/fog_mock.rb").read
  steps %Q{
    Given a file named "fog_mock.rb" with:
    """
    #{script}
    """
  }
end