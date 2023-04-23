# -*- coding: utf-8 -*-


defined? PROJECT    or abort "PROJECT required."
defined? RELEASE    or abort "RELEASE required."
defined? COPYRIGHT  or abort "COPYRIGHT required."
defined? LICENSE    or abort "LICENSE required."

RELEASE =~ /\A\d+\.\d+\.\d+/  or abort "RELEASE=#{RELEASE}: invalid release number."

$ruby_versions ||= %w[2.4 2.5 2.6 2.7 3.0]


require 'rake/clean'
CLEAN << "build"
CLEAN.concat Dir.glob("#{PROJECT}-*.gem").collect {|x| x.sub(/\.gem$/, '') }
CLOBBER.concat Dir.glob("#{PROJECT}-*.gem")


task :default do
  sh "rake -T"
end unless Rake::Task.task_defined?(:default)


desc "show release guide"
task :guide do
  RELEASE != '0.0.0'  or abort "rake guide: 'RELEASE=X.X.X' required."
  rel, proj = RELEASE, PROJECT
  rel =~ /(\d+\.\d+)/
  branch = "#{proj}_rel-#{$1}"
  puts <<END
How to release:

  $ git diff .
  $ git status .
  $ which ruby
  $ rake test
  $ rake test:all
  $ rake readme:execute             # optional
  $ rake readme:toc                 # optional
  $ rake package RELEASE=#{rel}
  $ rake package:extract            # confirm files in gem file
  $ (cd #{proj}-#{rel}/data; find . -type f)
  $ gem install #{proj}-#{rel}.gem  # confirm gem package
  $ gem uninstall #{proj}
  $ gem push #{proj}-#{rel}.gem     # publish gem to rubygems.org
  $ git tag #{proj}-#{rel}          # or: git tag ruby-#{proj}-#{rel}
  $ git push
  $ git push --tags
  $ rake clean
END
end unless Rake::Task.task_defined?(:guide)


unless respond_to?(:run_test, true)
  def run_test(ruby=nil, &b)
    files = File.exist?("test/run_all.rb") \
          ? ["test/run_all.rb"] \
          : Dir.glob("test/**/*_test.rb")
    if ruby
      sh(ruby, *files, &b)
    else
      ruby(*files, &b)
    end
  end
end


desc "do test"
task :test do
  run_test()
end unless Rake::Task.task_defined?(:test)


unless Rake::Task.task_defined?(:'test:all')
  desc "do test for different ruby versions"
  task :'test:all' do
    ENV['VS_HOME']  or
      abort "[ERROR] rake test:all: $VS_HOME required."
    defined?(RUBY_VERSIONS)  or
      abort "[ERROR] rake test:all: RUBY_VERSIONS required."
    vs_home = ENV['VS_HOME'].split(/[:;]/).first
    ENV['TC_QUIET'] = "Y" if File.exist?("test/tc.rb")
    header = proc {|s| "\033[0;36m=============== #{s} ===============\033[0m" }
    error  = proc {|s| "\033[0;31m** #{s}\033[0m" }
    comp = proc {|x, y| x.to_s.split('.').map(&:to_i) <=> y.to_s.split('.').map(&:to_i) }
    RUBY_VERSIONS.each do |ver|
      dir = Dir.glob("#{vs_home}/ruby/#{ver}.*").sort_by(&comp).last
      puts ""
      unless dir
        puts header.(ver)
        $stderr.puts error.("ruby #{ver} not found")
        next
      end
      puts header.("#{ver} (#{dir})")
      run_test("#{dir}/bin/ruby") do |ok, res|
        $stderr.puts error.("test failed") unless ok
      end
    end
  end
end


def target_files()
  $_target_files ||= begin
    spec_src = File.read("#{PROJECT}.gemspec", encoding: 'utf-8')
    spec = eval spec_src
    spec.name == PROJECT  or
      abort "'#{PROJECT}' != '#{spec.name}' (project name in gemspec file)"
    spec.files
  end
  return $_target_files
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


desc "edit metadata in files"
task :edit do
  target_files().each do |fname|
    changed = edit_file(fname) do |s|
      s = s.gsub(/\$Release[:].*?\$/,   "$"+"Release: #{RELEASE} $") if RELE ASE != '0.0.0'
      s = s.gsub(/\$Copyright[:].*?\$/, "$"+"Copyright: #{COPYRIGHT} $")
      s = s.gsub(/\$License[:].*?\$/,   "$"+"License: #{LICENSE} $")
      s
    end
    puts "[C] #{fname}"     if changed
    puts "[U] #{fname}" unless changed
  end
end unless Rake::Task.task_defined?(:edit)


desc "create package (*.gem)"
task :package do
  RELEASE != '0.0.0'  or abort "rake package: 'RELEASE=X.X.X' required."
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
    edit_file(file) do |s|
      s = s.gsub(/\$Release[:].*?\$/,   "$"+"Release: #{RELEASE} $")
      s = s.gsub(/\$Copyright[:].*?\$/, "$"+"Copyright: #{COPYRIGHT} $")
      s = s.gsub(/\$License[:].*?\$/,   "$"+"License: #{LICENSE} $")
      s
    end
  end
  ## build
  chdir dir do
    sh "gem build #{PROJECT}.gemspec"
  end
  mv "#{dir}/#{PROJECT}-#{RELEASE}.gem", "."
  rm_rf dir
end unless Rake::Task.task_defined?(:package)


desc "extract latest gem file"
task :'package:extract' do
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
end unless Rake::Task.task_defined?(:'package:extract')


desc "upload gem file to rubygems.org"
task :publish do
  RELEASE != '0.0.0'  or abort "rake publish: 'RELEASE=X.X.X' required."
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
end unless Rake::Task.task_defined?(:publish)


desc nil
task :'relink' do
  Dir.glob("task/*.rb").each do |x|
    src = "../" + x
    next if File.identical?(src, x)
    rm x
    ln src, x
  end
end
