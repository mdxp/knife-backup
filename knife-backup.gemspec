# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-backup/version"

Gem::Specification.new do |s|
  s.name        = "knife-backup"
  s.version     = Knife::Backup::VERSION
  s.authors     = ["Marius Ducea"]
  s.email       = ["marius.ducea@gmail.com"]
  s.homepage    = "https://github.com/mdxp/knife-backup"
  s.summary     = %q{Chef knife plugins to help backup and restore chef servers}
  s.description = s.summary
  s.license     = "Apache 2.0"

  s.rubyforge_project = "knife-backup"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "chef", ">= 0.10.10"
  s.add_dependency "chef-dk"
end
