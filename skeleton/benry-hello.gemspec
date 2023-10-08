# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = "benry-hello"
  spec.version         = "$Release: 0.0.0 $".split()[1]
  spec.author          = "kwatch"
  spec.email           = "kwatch@gmail.com"
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = "https://github.com/kwatch/benry-ruby/tree/main/benry-hello"
  spec.summary         = "Hello world"
  spec.description     = <<-"END"
Hello world.

See #{spec.homepage}#readme for details.
END
  spec.license         = "MIT"
  spec.files           = Dir[
                           "README.md", "MIT-LICENSE", "CHANGES.md",
                           "Rakefile.rb", "#{spec.name}.gemspec",
                           "lib/**/*.rb", "test/**/*.rb", "task/**/*.rb",
                           #"bin/*", "doc/**/*", "examples/**/*",
                         ]
  #spec.executables     = ["benry-hello"]
  spec.bindir          = "bin"
  spec.require_path    = "lib"
  spec.test_files      = Dir["test/**/*_test.rb"]
  #spec.extra_rdoc_files = ["README.md", "CHANGES.md"]

  spec.required_ruby_version = ">= 2.3"
  #spec.add_development_dependency "minitest"     , "~> 5"
  #spec.add_development_dependency "minitest-ok"  , "~> 0"
  spec.add_development_dependency "oktest"       , "~> 1"
end
