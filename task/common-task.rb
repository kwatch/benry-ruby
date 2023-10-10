# -*- coding: utf-8 -*-


defined? PROJECT    or abort "PROJECT required."
defined? RELEASE    or abort "RELEASE required."
defined? COPYRIGHT  or abort "COPYRIGHT required."
defined? LICENSE    or abort "LICENSE required."

RELEASE =~ /\A\d+\.\d+\.\d+/  or abort "RELEASE=#{RELEASE}: invalid release number."


require 'rake/clean'
CLEAN << "build"
CLEAN.concat Dir.glob("#{PROJECT}-*.gem").collect {|x| x.sub(/\.gem$/, '') }
CLOBBER.concat Dir.glob("#{PROJECT}-*.gem")


task :default do
  sh "rake -T"
end unless Rake::Task.task_defined?(:default)


desc "show release guide"
task :guide do
  do_guide()
end

def do_guide()
  RELEASE != '0.0.0'  or abort "** ERROR: 'RELEASE=X.X.X' required."
  puts guide_message(PROJECT, RELEASE)
end

def guide_message(project, release)
  target = "#{project}-#{release}"
  tag    = "#{project}-#{release}"
  puts <<END
How to release:

  $ git diff .
  $ git status .
  $ which ruby
  $ rake test
  $ rake test:all
  $ rake readme:execute			# optional
  $ rake readme:toc			# optional
  $ rake package RELEASE=#{release}
  $ rake package:extract		# confirm files in gem file
  $ (cd #{target}/data; find . -type f)
  $ gem install #{target}.gem	# confirm gem package
  $ gem uninstall #{project}
  $ gem push #{target}.gem	# publish gem to rubygems.org
  $ git tag #{tag}		# or: git tag ruby-#{tag}
  $ git push
  $ git push --tags
  $ rake clean
END
end


desc "create 'README.md' and 'doc/*.html'"
task :doc do
  x = PROJECT
  cd "doc" do
    sh "../../docs/md2 --md #{x}.mdx > ../README.md"
    sh "../../docs/md2 #{x}.mdx > #{x}.html"
  end
end

desc "copy 'doc/*.html' to '../docs/'"
task 'doc:export' do
  RELEASE != '0.0.0'  or abort "** ERROR: 'RELEASE=X.X.X' required."
  x = PROJECT
  cp "doc/#{x}.html", "../docs/"
  edit_file!("../docs/#{x}.html")
end


desc "edit metadata in files"
task :edit do
  do_edit()
end

def do_edit()
  target_files().each do |fname|
    edit_file!(fname)
  end
end

def target_files()
  $_target_files ||= begin
    spec_src = File.read("#{PROJECT}.gemspec", encoding: 'utf-8')
    spec = eval spec_src
    spec.name == PROJECT  or
      abort "** ERROR: '#{PROJECT}' != '#{spec.name}' (project name in gemspec file)"
    spec.files
  end
  return $_target_files
end

def edit_file!(filename, verbose: true)
  changed = edit_file(filename) do |s|
    s = s.gsub(/\$Release[:].*?\$/,   "$"+"Release: #{RELEASE} $")
    s = s.gsub(/\$Copyright[:].*?\$/, "$"+"Copyright: #{COPYRIGHT} $")
    s = s.gsub(/\$License[:].*?\$/,   "$"+"License: #{LICENSE} $")
    s
  end
  if verbose
    puts "[C] #{fname}"     if changed
    puts "[U] #{fname}" unless changed
  end
  return changed
end

def edit_file(filename)
  File.open(filename, 'rb+') do |f|
    s1 = f.read()
    s2 = yield s1
    if s1 != s2
      f.rewind()
      f.truncate(0)
      f.write(s2)
      true
    else
      false
    end
  end
end


desc "create package (*.gem)"
task :package do
  do_package()
end

def do_package()
  RELEASE != '0.0.0'  or abort "** ERROR: 'RELEASE=X.X.X' required."
  ## copy
  dir = "build"
  rm_rf dir if File.exist?(dir)
  mkdir dir
  target_files().each do |file|
    dest = File.join(dir, File.dirname(file))
    mkdir_p dest, :verbose=>false unless File.exist?(dest)
    cp file, "#{dir}/#{file}"
  end
  ## edit
  Dir.glob("#{dir}/**/*").each do |file|
    next unless File.file?(file)
    edit_file!(file, verbose: false)
  end
  ## build
  chdir dir do
    sh "gem build #{PROJECT}.gemspec"
  end
  mv "#{dir}/#{PROJECT}-#{RELEASE}.gem", "."
  rm_rf dir
end


desc "extract latest gem file"
task :'package:extract' do
  do_package_extract()
end

def do_package_extract()
  gemfile = Dir.glob("#{PROJECT}-*.gem").sort_by {|x| File.mtime(x) }.last
  dir = gemfile.sub(/\.gem$/, '')
  rm_rf dir if File.exist?(dir)
  mkdir dir
  mkdir "#{dir}/data"
  cd dir do
    sh "tar xvf ../#{gemfile}"
    sh "gunzip *.gz"
    cd "data" do
      sh "tar xvf ../data.tar"
    end
  end
end


desc "upload gem file to rubygems.org"
task :publish do
  do_publish()
end

def do_publish()
  RELEASE != '0.0.0'  or abort "** ERROR: 'RELEASE=X.X.X' required."
  gemfile = "#{PROJECT}-#{RELEASE}.gem"
  print "** Are you sure to publish #{gemfile}? [y/N]: "
  answer = $stdin.gets().strip()
  if answer.downcase == "y"
    sh "gem push #{gemfile}"
    #sh "git tag ruby-#{PROJECT}-#{RELEASE}"
    sh "git tag #{PROJECT}-#{RELEASE}"
    sh "#git push"
    sh "#git push --tags"
  end
end


desc nil
task :'relink' do
  Dir.glob("task/*.rb").each do |x|
    src = "../" + x
    next if File.identical?(src, x)
    rm x
    ln src, x
  end
end
