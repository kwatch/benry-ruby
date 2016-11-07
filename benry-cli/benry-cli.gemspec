# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = 'benry-cli'
  spec.version         = '$Release: 0.0.0 $'.split()[1]
  spec.author          = 'kwatch'
  spec.email           = 'kwatch@gmail.com'
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = 'https://github.com/kwatch/benry/tree/ruby/benry-cli'
  spec.summary         = "MVC-like framework for command-line application"
  spec.description     = <<-'END'
MVC-like framework for command-line application such as Git or SVN.
END
  spec.license         = 'MIT'
  spec.files           = Dir[
                           'README.md', 'CHANGES.md', 'MIT-LICENSE',
			   'Rakefile', 'benry-cli.gemspec',
			   'bin/*',
                           'lib/**/*.rb',
                           'test/**/*.rb',
                         ]
  #spec.executables     = ['benry-cli']
  spec.bindir          = 'bin'
  spec.require_path    = 'lib'
  spec.test_files      = Dir['test/**/*_test.rb']
  #spec.extra_rdoc_files = ['README.rdoc', 'CHANGES.md']

  spec.add_development_dependency 'minitest'    , '~> 5.8'
  spec.add_development_dependency 'minitest-ok' , '~> 0.2'
end
