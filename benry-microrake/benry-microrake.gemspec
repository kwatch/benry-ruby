# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = "benry-microrake"
  spec.version         = "$Release: 0.0.0 $".split()[1]
  spec.author          = "kwatch"
  spec.email           = "kwatch@gmail.com"
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = "https://kwatch.github.io/benry-ruby/benry-microrake/"
  spec.summary         = "Small Rake, accepting arguments and options for each task."
  spec.description     = <<-"END"
Benry-MicroRake is a subset of Rake.

The main difference between Benry-MicroRake and Rake is that
the former can accept arguments and options for each task
very easily. You can use short and long options in Rake tasks.

See #{spec.homepage} for details.
END
  spec.license         = "MIT"
  spec.files           = Dir[
                           "README.md", "MIT-LICENSE", "CHANGES.md",
                           "#{spec.name}.gemspec",
                           "lib/**/*.rb", "test/**/*.rb", "bin/*", # "examples/**/*",
                           "doc/*.html", "doc/css/*.css",
                         ]
  spec.executables     = ["urake"]
  spec.bindir          = "bin"
  spec.require_path    = "lib"
  spec.test_files      = Dir["test/**/*_test.rb"]   # or: ["test/run_all.rb"]
  #spec.extra_rdoc_files = ["README.md", "CHANGES.md"]

  spec.required_ruby_version = ">= 2.3"
  #spec.add_development_dependency "minitest"        , "~> 5"
  #spec.add_development_dependency "minitest-ok"     , "~> 0"
  spec.add_development_dependency "oktest"          , "~> 1"
end
