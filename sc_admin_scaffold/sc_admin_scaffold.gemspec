# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sc_admin_scaffold/version'

Gem::Specification.new do |spec|
  spec.name          = "sc_admin_scaffold"
  spec.version       = ScAdminScaffold::VERSION
  spec.authors       = ["shadow-chasing"]
  spec.email         = ["shadowchasing94@gmail.com"]

  spec.summary       = "Scaffold generator for admin"
  spec.description   = %q{This scaffold generates admin namespaced, standard model based controllers or both as well as views that correspond to an already invoked model for each.}
  spec.homepage      = "https://github.com/shadow-chasing/sc_admin_scaffold"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'true'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
end
