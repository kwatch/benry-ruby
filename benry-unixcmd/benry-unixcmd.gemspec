# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = "benry-unixcmd"
  spec.version         = "$Release: 0.0.0 $".split()[1]
  spec.author          = "kwatch"
  spec.email           = "kwatch@gmail.com"
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = "https://kwatch.github.io/benry-ruby/benry-unixcmd.html"
  spec.summary         = "Unix commands implementation like 'fileutils.rb'"
  spec.description     = <<-"END"
Unix commnads implementation. Similar to `fileutils.rb`, but better than it.

See #{spec.homepage} for details.
END
  spec.license         = "MIT"
  spec.files           = Dir[
                           "README.md", "MIT-LICENSE", "CHANGES.md",
                           "#{spec.name}.gemspec",
                           "lib/**/*.rb", "test/**/*.rb", #"bin/*", "examples/**/*",
                           "doc/*.html", "doc/css/*.css",
                         ]
  #spec.executables     = []
  spec.bindir          = "bin"
  spec.require_path    = "lib"
  spec.test_files      = ["test/run_all.rb"]   # or: Dir["test/**/*_test.rb"]
  #spec.extra_rdoc_files = ["README.md", "CHANGES.md"]

  spec.required_ruby_version = ">= 2.3"
  spec.add_development_dependency "oktest"          , "~> 1"
end
