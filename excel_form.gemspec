$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'excel_form/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'excel_form'
  s.version     = ExcelForm::VERSION
  s.authors     = %w{hayatecn}
  s.email       = %w{holdstock@yeah.net}
  s.homepage    = ''
  s.summary     = 'learn how to generate gem.'
  s.description = 'test.'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']

  s.add_dependency 'rails', '~> 4.0.0'

  s.add_development_dependency 'sqlite3'
end
