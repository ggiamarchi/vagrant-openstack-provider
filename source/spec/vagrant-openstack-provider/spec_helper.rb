
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
  'lib/vagrant-openstack-provider/config.rb',
  'lib/vagrant-openstack-provider/config_resolver.rb',
  'lib/vagrant-openstack-provider/utils.rb',
  'lib/vagrant-openstack-provider/errors.rb',
  'lib/vagrant-openstack-provider/provider.rb',
  'lib/vagrant-openstack-provider/client/*.rb',
  'lib/vagrant-openstack-provider/command/*.rb',
  'lib/vagrant-openstack-provider/action/*.rb'].each { |file| require file[4, file.length - 1] }

require 'rspec/its'
require 'webmock/rspec'
require 'fakefs/safe'
require 'fakefs/spec_helpers'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, fakefs: true
end

I18n.load_path << File.expand_path('locales/en.yml', Pathname.new(File.expand_path('../../../', __FILE__)))
