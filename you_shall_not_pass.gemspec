# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'you_shall_not_pass/version'

Gem::Specification.new do |spec|
  spec.name          = "you_shall_not_pass"
  spec.version       = YouShallNotPass::VERSION
  spec.authors       = ["Federico Iachetti"]
  spec.email         = ["iachetti.federico@gmail.com"]
  spec.summary       = %q{Simple authorization library.}
  spec.description   = %q{Embrace authorization with this simple library.}
  spec.homepage      = "https://github.com/iachettifederico/you_shall_not_pass"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "matest", "~> 1.7.2"
  
  spec.add_dependency "callable", "~> 0.0.5"
  spec.add_dependency "fattr", "~> 2.2.2"
end
