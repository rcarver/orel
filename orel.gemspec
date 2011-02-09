
Gem::Specification.new do |s|
  s.name        = "orel"
  s.version     = "0.0.0"
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
end

