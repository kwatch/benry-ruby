# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = "benry-cmdapp"
  spec.version         = "$Release: 0.0.0 $".split()[1]
  spec.author          = "kwatch"
  spec.email           = "kwatch@gmail.com"
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = "https://kwatch.github.io/benry-ruby/benry-cmdapp.html"
  spec.summary         = "Command-line application framework`"
  spec.description     = <<-"END"
Benry-CmdApp is a framework to create command-line application
like `git`, `docker`, or `npm` commands.

If you want create a command-line application which takes sub-commands,
Benry-CmdApp is the solution.

See #{spec.homepage} for details.
END
  spec.license         = "MIT"
  spec.files           = Dir[
                           "README.md", "MIT-LICENSE", "CHANGES.md",
                           "#{spec.name}.gemspec",
                           #"Rakefile.rb", "task/**/*.rb",,
                           "lib/**/*.rb", "test/**/*.rb",
                           #"bin/*", "examples/**/*",
                           "doc/*.html", "doc/css/*.css",
                         ]
  #spec.executables     = []
  spec.bindir          = "bin"
  spec.require_path    = "lib"
  spec.test_files      = Dir["test/**/*_test.rb"]   # or: ["test/run_all.rb"]
  #spec.extra_rdoc_files = ["README.md", "CHANGES.md"]

  spec.required_ruby_version = ">= 2.3"
  spec.add_runtime_dependency     "benry-cmdopt"    , "~> 2"
  spec.add_development_dependency "oktest"          , "~> 1"
end
