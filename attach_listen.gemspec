# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "attach_listen/version"

Gem::Specification.new do |s|
  s.name        = "attach_listen"
  s.version     = AttachListen::VERSION
  s.authors     = ["Thomas Stratmann"]
  s.email       = ["thomas.stratmann@9elements.com"]
  s.homepage    = ""
  s.summary     = %q{Listen to attribute changes, bundle state requirements and trigger met/unmet actions}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "debugger"
  s.add_development_dependency "rspec", "~> 2.0"
  s.add_development_dependency "growl"
  s.add_development_dependency "guard-rspec"
end
