# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'excel_form/version'

Gem::Specification.new do |spec|
  spec.name          = "excel_form"
  spec.version       = ExcelForm::VERSION
  spec.authors       = ["chenliang"]
  spec.email         = ["holdstock@yeah.net"]
  spec.description   = %q{simple excel style form gem}
  spec.summary       = %q{personal useage}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
