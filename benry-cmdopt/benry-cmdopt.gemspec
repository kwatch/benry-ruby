# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = "benry-cmdopt"
  spec.version         = "$Release: 0.0.0 $".split()[1]
  spec.author          = "kwatch"
  spec.email           = "kwatch@gmail.com"
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = "https://kwatch.github.io/benry-ruby/benry-cmdopt.html"
  spec.summary         = "Command option parser, much better than `optparse.rb`"
  spec.description     = <<-"END"
Command option parser, much simpler and better than `optparse.rb`.

Why not `optparse.rb`? See #{spec.homepage}#why-not-optparserb for details.
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
  spec.test_files      = Dir["test/**/*_test.rb"]   # or: ["test/run_all.rb"]
  #spec.extra_rdoc_files = ["README.md", "CHANGES.md"]

  spec.required_ruby_version = ">= 2.3"
  spec.add_development_dependency "oktest"          , "~> 1"
end
