$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "rack-stream"
  s.version     = "0.0.6"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jerry Cheung"]
  s.email       = ["jerry@intridea.com"]
  s.homepage    = "https://github.com/jch/rack-stream"
  s.summary     = %q{Rack middleware for building multi-protocol streaming rack endpoints}
  s.description = %q{Rack middleware for building multi-protocol streaming rack endpoints}
  s.license     = "BSD"
  s.required_ruby_version = '>= 1.9.3'

  s.rubyforge_project = "rack-stream"

  s.add_runtime_dependency 'rack'
  s.add_runtime_dependency 'eventmachine'
  s.add_runtime_dependency 'faye-websocket'
  s.add_runtime_dependency 'em-synchrony'

  s.files         = `git ls-files`.split("\n").select {|f| f !~ /^example/}
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
