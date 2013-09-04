Knife-Backup
===

Knife-Backup is a [Knife](http://wiki.opscode.com/display/chef/Knife) plugin that can help you backup and restore a chef server. It is based on the great work of [Steven Danna][stevendanna] and [Joshua Timberman][jtimberman] on the [BackupExport][backup_export] and [BackupRestore][backup_restore] plugins. Currently knife-backup has support for the following objects:

  * clients
  * users (chef >= 11)
  * nodes
  * roles
  * environments
  * data bags
  * cookbooks and all their versions.

knife-backup will backup all cookbook versions available on the chef server. Cookbooks are normally available in a repository and should be easy to upload like that, but if you are using various cookbook versions in each environment then it might not be so trivial to find and upload them back to the server; downloading them and having them available to upload like that is simple and clean. If you have too many cookbook [versions](http://www.ducea.com/2013/02/26/knife-cleanup/) then you might want to cleanup them first using something like [knife-cleanup][knifecleanup]

Users are a bit tricky, knife-backup can't gather the crypted passwords via the chef server so it's forced to reset them to a random string on restore. Be sure to copy them from the restore output or reset them.

*Known limitation*: currently it is not possible to overwritte a client object already available on the target server and these will be skipped. 

## Installation

You will need chef installed and a working knife config; it should work with chef versions newer than 0.10.10

```bash
gem install knife-backup
```

## Usage

For a list of commands:

```bash
knife backup --help
```

Currently the available commands are:

```bash
knife backup export [component component ...] [-D DIR]
knife backup restore [component component ...] [-D DIR]

#Example:
knife backup export cookbooks roles environments -D ~/my_chef_backup
```

Note: you should treat this as beta software; I'm using it with success for my needs and hopefully you will find it useful too.

## Todo/Ideas
  
  * Timestamp for the backup folder
  * Track the failed downloads and report them at the end
  * Find out if there is a way to overwrite a client object.

## Development

* Source hosted at [GitHub][repo]
* Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Ideally create a topic branch for every separate change you make. For example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

Created and maintained by [Marius Ducea][mdxp] (<marius.ducea@gmail.com>)

Based on the original plugins by [Steven Danna][stevendanna] and [Joshua Timberman][jtimberman]

## License

Apache License, Version 2.0 (see [LICENSE][license])

[license]:      https://github.com/mdxp/knife-backup/blob/master/LICENSE
[mdxp]:         https://github.com/mdxp
[repo]:         https://github.com/mdxp/knife-backup
[issues]:       https://github.com/mdxp/knife-backup/issues
[knifecleanup]:  https://github.com/mdxp/knife-cleanup
[chefjenkins]:  https://github.com/mdxp/chef-jenkins

[backup_export]:            https://github.com/stevendanna/knife-hacks/blob/master/plugins/backup_export.rb
[backup_restore]:           https://github.com/stevendanna/knife-hacks/blob/master/plugins/backup_restore.rb
[jtimberman]:               https://github.com/jtimberman
[stevendanna]:              https://github.com/stevendanna
