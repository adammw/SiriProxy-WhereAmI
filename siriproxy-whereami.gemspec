# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "siriproxy-whereami"
  s.version     = "0.0.1" 
  s.authors     = ["adammw111"]
  s.email       = ["adman.com@gmail.com"]
  s.homepage    = "https://github.com/adammw/SiriProxy-WhereAmI"
  s.summary     = %q{A plugin to show you where you are}
  s.description = %q{This plugin shows you a map of your current location when you ask "Where am I?"}

  s.rubyforge_project = "siriproxy-whereami"

  s.files         = `git ls-files 2> /dev/null`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/* 2> /dev/null`.split("\n")
  s.executables   = `git ls-files -- bin/* 2> /dev/null`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "json"
end
