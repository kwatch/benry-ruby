# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = 'benry-cmdapp'
  spec.version         = '$Release: 0.0.0 $'.split()[1]
  spec.author          = 'kwatch'
  spec.email           = 'kwatch@gmail.com'
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = 'https://github.com/kwatch/benry/tree/ruby/benry-cmdapp'
  spec.summary         = "Command-line application framework`"
  spec.description     = <<-'END'
Benry::CmdApp is a framework to create command-line application.
If you want create command-line application which takes sub-commands
like `git`, `docker`, or `npm`, Benry::CmdApp is the solution.
END
  spec.license         = 'MIT'
  spec.files           = Dir[
                           'README.md', 'CHANGES.md', 'MIT-LICENSE',
                           'Rakefile.rb', 'benry-cmdapp.gemspec',
                           #'bin/*',
                           'lib/benry/cmdapp.rb',
                           'test/**/*.rb',
                         ]
  #spec.executables     = ['benry-cmdapp']
  spec.bindir          = 'bin'
  spec.require_path    = 'lib'
  spec.test_files      = Dir['test/**/*_test.rb']
  #spec.extra_rdoc_files = ['README.md', 'CHANGES.md']

  spec.add_development_dependency 'oktest'    , '~> 1.2'
end
