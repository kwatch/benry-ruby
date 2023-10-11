# coding: utf-8

Gem::Specification.new do |spec|
  spec.name            = "benry-config"
  spec.version         = "$Release: 0.0.0 $".split()[1]
  spec.author          = "kwatch"
  spec.email           = "kwatch@gmail.com"
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = "https://kwatch.github.io/benry-ruby/benry-config.html"
  spec.summary         = "Application configuration library"
  spec.description     = <<"END"
Small library for configuration of application.

See #{spec.homepage} for details.
END
  spec.license         = "MIT"
  spec.files           = Dir[
                           "README.md", "MIT-LICENSE", #"CHANGES.md",
                           "Rakefile.rb", "#{spec.name}.gemspec",
                           "lib/**/*.rb", "test/**/*_test.rb", "task/**/*.rb",
                           #"bin/*", "doc/**/*", "examples/**/*",
                         ]
  #spec.executables     = []
  spec.bindir          = "bin"
  spec.require_path    = "lib"
  spec.test_files      = Dir["test/**/*_test.rb"]   # or: ["test/run_all.rb"]
  #spec.extra_rdoc_files = ["README.md", "CHANGES.md"]

  spec.required_ruby_version = ">= 2.3"
  spec.add_development_dependency "oktest"          , "~> 1"
end
