# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = "benry-recorder"
  spec.version         = "$Release: 0.0.0 $".split()[1]
  spec.author          = "kwatch"
  spec.email           = "kwatch@gmail.com"
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = "https://kwatch.github.io/benry-ruby/benry-recorder.html"
  spec.summary         = "Record method calls, or define fake methods."
  spec.description     = <<-"END"
Benry-Recorder is a small tool that can:

* Record method calls of target object.
* Define fake methods on target object.
* Create fake objects which have fake methods.

Benry-Recorder can be a test double tool (spy, stub, or mock) for unit test.

See #{spec.homepage}#readme for details.
END
  spec.license         = "MIT"
  spec.files           = Dir[
                           "README.md", "MIT-LICENSE", "CHANGES.md",
                           "Rakefile.rb", "#{spec.name}.gemspec",
                           "lib/**/*.rb", "test/**/*.rb", "task/**/*.rb",
                           #"bin/*", "examples/**/*",
                           "doc/*.html", "doc/css/*",
                         ]
  #spec.executables     = []
  spec.bindir          = "bin"
  spec.require_path    = "lib"
  spec.test_files      = Dir["test/**/*_test.rb"]   # or: ["test/run_all.rb"]
  #spec.extra_rdoc_files = ["README.md", "CHANGES.md"]

  spec.required_ruby_version = ">= 2.3"
  spec.add_development_dependency "minitest"        , "~> 5"
  spec.add_development_dependency "minitest-ok"     , "~> 0"
  #spec.add_development_dependency "oktest"          , "~> 1"
end
