# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = "benry-actionrunner"
  spec.version         = "$Release: 0.0.0 $".split()[1]
  spec.author          = "kwatch"
  spec.email           = "kwatch@gmail.com"
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = "https://kwatch.github.io/benry-ruby/benry-actionrunner.html"
  spec.summary         = "Action runner or Task runner, like Rake or Gulp."
  spec.description     = <<-"END"
Benry-ActionRunner is a Action runner or Task runner, like Rake or Gulp.

Compared to Rake, actions of Benry-ActionRunner can take their own options and arguments.
For example, `arun hello --lang=fr Alice` runs `hello` action with an option `--lang=fr` and an argument `Alice`.

Benry-ActionRunner is also an example application of Benry-CmdApp framework.

See #{spec.homepage} for details.
END
  spec.license         = "MIT"
  spec.files           = Dir[
                           "README.md", "MIT-LICENSE", "CHANGES.md",
                           "#{spec.name}.gemspec",
                           "lib/**/*.rb", "test/**/*.rb", "bin/*", # "examples/**/*",
                           "doc/*.html", "doc/css/*.css",
                         ]
  #spec.executables     = []
  spec.bindir          = "bin"
  spec.require_path    = "lib"
  spec.test_file       = "test/run_all.rb"
  #spec.extra_rdoc_files = ["README.md", "CHANGES.md"]

  spec.required_ruby_version = ">= 2.3"
  spec.add_runtime_dependency     "benry-cmdapp"    , "~> 0", "=> 0.3"
  spec.add_development_dependency "oktest"          , "~> 1"
end
