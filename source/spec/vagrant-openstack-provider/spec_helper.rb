
if ENV['COVERAGE'] != 'false'
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter 'spec'
  end
end


Dir[
  "lib/vagrant-openstack-provider/openstack_client.rb",
  "lib/vagrant-openstack-provider/config.rb",
  "lib/vagrant-openstack-provider/errors.rb",
  "lib/vagrant-openstack-provider/provider.rb",
  "lib/vagrant-openstack-provider/action/*.rb"].each { |file| require file[4, file.length-1] }

require 'webmock/rspec'
