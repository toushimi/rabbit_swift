# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rabbit_swift/version'

Gem::Specification.new do |spec|
  spec.name          = "rabbit_swift"
  spec.version       = RabbitSwift::VERSION
  spec.authors       = ["AKB428"]
  spec.email         = ["otoraru@gmail.com"]
  spec.summary       = %q{OpenStack Swift Simple Client}
  spec.description   = %q{OpenStack Swift Simple Client. main target for "ConoHa VPS"}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency 'httpclient'
end
