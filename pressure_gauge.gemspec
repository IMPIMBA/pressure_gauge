# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pressure_gauge/version"

Gem::Specification.new do |spec|
  spec.name        = "pressure_gauge"
  spec.version     = PressureGauge::VERSION
  spec.authors     = ["Georg Rath"]
  spec.email       = ["georg.rath@imba.oeaw.ac.at"]
  spec.homepage    = ""
  spec.summary     = %q{TODO: Write a gem summary}
  spec.description = %q{TODO: Write a gem description}

  spec.rubyforge_project = "pressure_gauge"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'colorize'

  spec.add_development_dependency 'rake'
end
