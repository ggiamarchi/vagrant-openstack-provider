# 0.1.3 (September 6, 2013)


IMPROVEMENTS:

  - Adds ability to specify authentication endpoint; Support for UK Cloud! [GH-32]
  - Adds ability to specify disk configuration (disk_conf) [GH-33]

# 0.1.2 (August 22, 2013)

FEATURES:

- Add provision support [GH-16]
  
IMPROVEMENTS:
  
  - Adds option to allow provisioning after RackConnect scripts complete. [GH-18]
  - Remove Fog deprecation warnings [GH-11]
  - Bypass rsync's StrictHostKeyCheck [GH-5]
  - Make chown'ing of synced folder perms recursive (for ssh user) [GH-24]
  - Use /cygdrive when rsyncing on Windows [GH-17]
  
  
# 0.1.1 (March 18, 2013)

* Up fog dependency for Vagrant 1.1.1

# 0.1.0 (March 14, 2013)

* Initial release.
