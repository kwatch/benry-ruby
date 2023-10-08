# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "benry-config"
  spec.version       = '$Release: 0.0.0 $'.split()[1]
  spec.authors       = ["kwatch"]
  spec.email         = ["kwatch@gmail.com"]

  spec.summary       = "useful configuration class"
  spec.description   = <<'END'
See https://github.com/kwatch/benry/tree/ruby/benry-config for details.
END
  spec.homepage      = "https://github.com/kwatch/benry/tree/ruby/benry-config"
  spec.license       = "MIT"

  spec.files         = Dir[*%w[
                         README.md MIT-LICENSE.txt Rakefile.rb benry-config.gemspec
                         lib/**/*.rb
                         test/**/*_test.rb
                         task/**/*.rb
                       ]]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3'
  spec.add_development_dependency 'oktest'          , '=> 1.2'
end
