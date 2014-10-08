$:.push File.expand_path("../lib", __FILE__)
require "orel/version"

Gem::Specification.new do |s|
  s.name        = "orel"
  s.version     = Orel::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ryan Carver"]
  s.email       = "ryan@ryancarver.com"
  s.homepage    = "http://github.com/rcarver/orel"
  s.summary     = "orel"
  s.description = "orel combines orm and relational"

  s.rubygems_version   = "1.3.7"

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = [ "README.md" ]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  s.add_dependency 'activerecord', '~>3.1'
  s.add_dependency 'activesupport', '~>3.1'
  s.add_dependency 'activemodel', '~>3.1'
  s.add_dependency 'mysql2', '~>0.3.0'
  s.add_dependency 'arel'
  s.add_dependency 'sourcify'

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "aruba"
  s.add_development_dependency 'database_cleaner'

end

