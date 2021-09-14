# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = 'benry-unixcmd'
  spec.version         = '$Release: 0.0.0 $'.split()[1]
  spec.author          = 'kwatch'
  spec.email           = 'kwatch@gmail.com'
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = 'https://github.com/kwatch/benry-ruby/tree/ruby/benry-unixcmd'
  spec.summary         = "Unix commands implementation like 'fileutils.rb'"
  spec.description     = <<-'END'
Unix commnads implementation, like `fileutils.rb`.

Features compared to `fileutils.rb`:

* supports file patterns (`*`, `.`, `{}`) directly.
* provides `cp :r`, `mv :p`, `rm :rf`, ... instead of `cp_r`, `mv_p`, `rm_rf`, ...
* prints command prompt `$ ` before command echoback.
* provides `pushd` which is similar to `cd` but supports nested calls naturally.
* implements `capture2`, `capture2e`, and `capture3` which calls
  `Popen3.capture2`, `Popen3.capture2`, and `Popen3.capture3` respectively.
* supports `touch -r reffile`.
* provides `sys` command which is similar to `sh` in Rake but different in details.
* provides `zip` and `unzip` commands (requires `rubyzip` gem).
* provides `store` command which copies files recursively into target directory, keeping file path.
* provides `atomic_symlink!` command which switches symlink atomically.

```
cp Dir['*.rb'], 'tmpdir'     ## fileutils.rb
cp '*.rb', 'tmpdir'          ## benry-unixcmd
```

Benry-unixcmd provides `cp_p` and `cp_pr` which are equivarent to `cp -p` and `cp -pr` respectively and not provided by `fileutiles.rb`.
END
  spec.license         = 'MIT'
  spec.files           = Dir[
                           'README.md', 'CHANGES.md', 'MIT-LICENSE',
                           'Rakefile.rb', 'benry-unixcmd.gemspec',
                           #'bin/*',
                           'lib/**/*.rb',
                           'test/**/*.rb',
                           'task/*.rb',
                         ]
  #spec.executables     = ['benry-unixcmd']
  #spec.bindir          = 'bin'
  spec.require_path    = 'lib'
  spec.test_files      = Dir['test/run_all.rb']
  #spec.test_files      = Dir['test/**/*_test.rb']
  #spec.extra_rdoc_files = ['README.md', 'CHANGES.md']

  spec.add_development_dependency 'oktest'    , '~> 1'
end
