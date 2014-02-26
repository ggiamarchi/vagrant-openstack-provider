# Release process

This is vagrant-openstack's current release process, documented so people know what is
currently done.

## Prepare the release

* Update the version in "lib/vagrant-openstack/version.rb"
* Update the version in CHANGELOG.md
* Use "rake release". This will make sure to tag that commit and push it RubyGems.
* Update the version again in both files to a dev version for working again.

The CHANGELOG.md should be maintained in a similar format to Vagrant:

https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md


