source 'https://rubygems.org'

gemspec

group :development do
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant.git', tag: 'v1.8.1'
  gem 'appraisal', '1.0.0'
  gem 'rubocop', '0.29.0', require: false
  gem 'coveralls', require: false
  gem 'rspec-its'
end

group :debug do
  gem 'byebug'
end

group :plugins do
  gem 'vagrant-openstack-provider', path: '.'
end
