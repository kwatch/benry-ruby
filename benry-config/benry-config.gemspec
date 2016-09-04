# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "benry-config"
  spec.version       = '$Release: 0.0.0 $'.split()[1]
  spec.authors       = ["makoto kuwata"]
  spec.email         = ["kwa(at)kuwata-lab.com"]

  spec.summary       = "useful configuration class"
  spec.description   = <<'END'
See https://github.com/kwatch/benry/tree/ruby/benry-config for details.
END
  spec.homepage      = "https://github.com/kwatch/benry/tree/ruby/benry-config"
  spec.license       = "MIT"

  spec.files         = Dir[*%w[
                         README.md MIT-LICENSE.txt Rakefile
                         lib/**/*.rb
                         test/**/*_test.rb
                       ]]
  spec.require_paths = ["lib"]

  #spec.required_ruby_version = '>= 2.0'
  spec.add_development_dependency "minitest"     , '~> 0'
  spec.add_development_dependency "minitest-ok"  , '~> 0'
end
