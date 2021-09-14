# -*- coding: utf-8 -*-

project   = "benry-unixcmd"
release   = ENV['RELEASE'] || "0.0.0"
copyright = "copyright(c) 2021 kuwata-lab.com all rights reserved"
license   = "MIT License"

target_files = Dir[*%W[
  README.md CHANGES.md MIT-LICENSE Rakefile.rb
  lib/**/*.rb
  test/**/*_test.rb test/run_all.rb
  #{project}.gemspec
]]

require 'rake/clean'
CLEAN << "build"
CLOBBER << Dir.glob("#{project}-*.gem")

begin
  require './task/readme-task'
rescue LoadError => exc
end


task :default => :help


desc "show help"
task :help do
  puts "rake help                   # help"
  puts "rake test                   # run test"
  puts "rake package RELEASE=X.X.X  # create gem file"
  puts "rake publish RELEASE=X.X.X  # upload gem file"
  puts "rake clean                  # remove files"
end


desc "do test"
task :test do
  #sh "ruby", *Dir.glob("test/*.rb")
  #sh "ruby", "test/run_all.rb"
  #sh "oktest -ss test"
  sh "ruby -r oktest -e 'puts RUBY_VERSION;Oktest.main' -- test -ss"
end

$ruby_versions = %w[2.4.10 2.5.8 2.6.6 2.7.1 3.0.2]

desc "do test for each Ruby version"
task :'test:all' do
  vs_home = ENV['VS_HOME']
  if vs_home.nil? || vs_home.empty?
    fail "$VS_HOME should be set."
  end
  $ruby_versions.each do |ver|
    puts "======== Ruby #{ver} ========"
    ruby = File.join(vs_home, "ruby/#{ver}/bin/ruby")
    sh "#{ruby} -r oktest -e 'puts RUBY_VERSION;Oktest.main' -- test -sp" do end
  end
end


desc "create package"
task :package do
  release != "0.0.0"  or
    raise "specify $RELEASE"
  ## copy
  dir = "build"
  rm_rf dir if File.exist?(dir)
  mkdir dir
  target_files.each do |file|
    dest = File.join(dir, File.dirname(file))
    mkdir_p dest, :verbose=>false unless File.exist?(dest)
    cp file, "#{dir}/#{file}"
  end
  ## edit
  Dir.glob("#{dir}/**/*").each do |file|
    next unless File.file?(file)
    File.open(file, 'rb+') do |f|
      s1 = f.read()
      s2 = s1
      s2 = s2.gsub(/\$Release[:].*?\$/,   "$"+"Release: #{release} $")
      s2 = s2.gsub(/\$Copyright[:].*?\$/, "$"+"Copyright: #{copyright} $")
      s2 = s2.gsub(/\$License[:].*?\$/,   "$"+"License: #{license} $")
      #
      if s1 != s2
        f.rewind()
        f.truncate(0)
        f.write(s2)
      end
    end
  end
  ## build
  cd dir do
    sh "gem build #{project}.gemspec"
  end
  mv "#{dir}/#{project}-#{release}.gem", "."
end


desc "upload gem file to rubygems.org"
task :publish do
  release != "0.0.0"  or
    raise "specify $RELEASE"
  #
  gemfile = "#{project}-#{release}.gem"
  print "** Are you sure to publish #{gemfile}? [y/N]: "
  answer = $stdin.gets().strip()
  if answer.downcase == "y"
    sh "gem push #{gemfile}"
    sh "git tag ruby-#{project}-#{release}"
    sh "git push --tags"
  end
end
