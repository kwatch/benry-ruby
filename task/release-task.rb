# -*- coding: utf-8 -*-


defined? PROJECT    or abort "PROJECT required."
defined? RELEASE    or abort "RELEASE required."


desc "show release operations"
task :'release:guide' do
  do_release_guide()
end

def do_release_guide()
  RELEASE != '0.0.0'  or abort "** ERROR: 'RELEASE=X.X.X' required."
  puts guide_message(PROJECT, RELEASE)
end

def guide_message(project, release)
  target = "#{project}-#{release}"
  tag    = "#{project}-#{release}"
  return <<END
How to release:

  $ git diff .
  $ git status .
  $ which ruby
  $ rake test
  $ rake test:all
  $ specid diff lib test
  $ chkruby lib test
  $ rake doc
  $ rake doc:export RELEASE=#{release}
  $ rake readme:execute			# optional
  $ rake readme:toc			# optional
  $ rake package RELEASE=#{release}
  $ rake package:extract		# confirm files in gem file
  $ (cd #{target}/data; find . -type f)
  $ (cd #{target}/data; ag '(Release|Copyright|License):')
  $ gem install #{target}.gem	# confirm gem package
  $ gem uninstall #{project}
  $ gem push #{target}.gem	# publish gem to rubygems.org
  $ git tag #{tag}		# or: git tag ruby-#{tag}
  $ git push --tags
  $ rake clean
  $ mv #{target}.gem archive/
  $ cd ../docs/
  $ git add #{project}.html
  $ git commit -m "[main] docs: update '#{project}.html'"
  $ git push
END
end
