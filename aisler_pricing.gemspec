
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "aisler_pricing/version"

Gem::Specification.new do |spec|
  spec.name          = "aisler_pricing"
  spec.version       = AislerPricing::VERSION
  spec.authors       = ["Patrick Franken"]
  spec.email         = ["p.franken@aisler.net"]

  spec.summary       = %q{Want to know how AISLER calculates its prices? Look no further!}
  spec.description   = %q{This gem is used to calculate all prices}
  spec.homepage      = "https://github.com/aislerhq/aisler_pricing"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "geminabox"

  spec.add_dependency "money", "~> 6.10"
  spec.add_dependency "eu_central_bank", "~> 1.4.2"
end
