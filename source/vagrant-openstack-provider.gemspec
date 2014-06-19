lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-openstack-provider/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-openstack-provider"
  gem.version       = VagrantPlugins::Openstack::VERSION
  gem.authors       = ["Guillaume Giamarchi", "Julien Vey"]
  gem.email         = ["guillaume.giamarchi@gmail.com", "vey.julien@gmail.com"]
  gem.description   = "Enables Vagrant to manage machines in Openstack Cloud."
  gem.summary       = "Enables Vagrant to manage machines in Openstack Cloud."
  gem.homepage      = "https://github.com/ggiamarchi/vagrant-openstack"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 2.13.0"
  gem.add_development_dependency "aruba"

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(/^bin\//).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/^(test|spec|features)\//)
  gem.require_paths = ["lib"]
end
