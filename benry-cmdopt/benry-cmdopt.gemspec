# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = 'benry-cmdopt'
  spec.version         = '$Release: 0.0.0 $'.split()[1]
  spec.author          = 'kwatch'
  spec.email           = 'kwatch@gmail.com'
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = 'https://github.com/kwatch/benry/tree/ruby/benry-cmdopt'
  spec.summary         = "Command option parser, like `optparse.rb`"
  spec.description     = <<-'END'
Command option parser, much simpler and better than `optparse.rb`.
END
  spec.license         = 'MIT'
  spec.files           = Dir[
                           'README.md', 'CHANGES.md', 'MIT-LICENSE',
                           'Rakefile.rb', 'benry-cmdopt.gemspec',
                           'bin/*',
                           'lib/**/*.rb',
                           'test/**/*.rb',
                         ]
  #spec.executables     = ['benry-cmdopt']
  spec.bindir          = 'bin'
  spec.require_path    = 'lib'
  spec.test_files      = Dir['test/**/*_test.rb']
  #spec.extra_rdoc_files = ['README.md', 'CHANGES.md']

  spec.add_development_dependency 'minitest'    , '~> 5.8'
  spec.add_development_dependency 'minitest-ok' , '~> 0.3'
end
