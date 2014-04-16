# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trafaret/version'

Gem::Specification.new do |spec|
  spec.name          = "trafaret"
  spec.version       = Trafaret::VERSION
  spec.authors       = ["Mikhail Krivushin"]
  spec.email         = ["krivushinme@gmail.com"]
  spec.summary       = %q{Combinatorial data parser}
  spec.description   = %q{The thing to convert entities from one to other.
                          Idea from Python Trafaret lib in Ruby way.}
  spec.homepage      = "https://github.com/Deepwalker/trafaret.rb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
