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
  spec.description   = %q{OpenStack Object Storage Simple Client}
  spec.homepage      = "http://akb428.hatenablog.com/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency('httpclient','~> 2.1.5')
  spec.add_dependency 'mime-types'
  spec.add_dependency 'rabbit_file_split'
end
