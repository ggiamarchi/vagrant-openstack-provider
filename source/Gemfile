source 'https://rubygems.org'

gemspec

group :development do
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant.git', tag: 'v1.6.5'
  gem 'appraisal', '1.0.0'
  gem 'rubocop', '0.23.0', require: false
  gem 'coveralls', require: false
end

group :debug do
  gem 'debugger'
end

group :plugins do
  gem "vagrant-openstack-provider", path: "."
end
