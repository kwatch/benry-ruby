# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = 'benry-recorder'
  spec.version         = '$Release: 0.0.0 $'.split()[1]
  spec.author          = 'kwatch'
  spec.email           = 'kwatch@gmail.com'
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = 'https://github.com/kwatch/benry-ruby/tree/ruby/benry-recorder'
  spec.summary         = "Record method calls, or define fake methods."
  spec.description     = <<-'END'
Benry-recorder is a tiny utility that can:

* Record method calls of target object.
* Define fake methods on target object.
* Create fake object which has fake methods.
END
  spec.license         = 'MIT'
  spec.files           = Dir[
                           'README.md', 'MIT-LICENSE', 'CHANGES.md'
                           'Rakefile.rb', 'benry-recorder.gemspec',
                           #'bin/*',
                           'lib/**/*.rb',
                           'test/**/*.rb',
                           'task/**/*.rb',
                         ]
  #spec.executables     = ['benry-recorder']
  #spec.bindir          = 'bin'
  spec.require_path    = 'lib'
  #spec.test_files      = Dir['test/run_all.rb']
  spec.test_files      = Dir['test/**/*_test.rb']
  #spec.extra_rdoc_files = ['README.md', 'CHANGES.md']

  spec.add_development_dependency 'minitest'    , '~> 0'
  spec.add_development_dependency 'minitest-ok' , '~> 0'
end
