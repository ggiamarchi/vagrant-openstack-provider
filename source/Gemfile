source 'https://rubygems.org'

gemspec

gem "appraisal", "1.0.0"
gem "restclient", "0.10.0"
gem 'webmock', '~> 1.18.0', :group => [:test]
gem "rubocop", '0.23.0', require: false
gem "vagrant", :git => "git://github.com/mitchellh/vagrant.git", :tag => "v1.4.3"
gem 'fakefs', '~> 0.5.2', :group => [:test]


group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem 'coveralls', require: false
  gem 'debugger'
end
