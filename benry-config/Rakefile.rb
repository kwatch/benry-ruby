# -*- coding: utf-8 -*-


PROJECT   = "benry-config"
RELEASE   = ENV['RELEASE'] || "0.0.0"
COPYRIGHT = "copyright(c) 2016 kuwata-lab.com all rights reserved"
LICENSE   = "MIT License"

RUBY_VERSIONS = ["3.2", "3.1", "3.0", "2.7", "2.6", "2.5", "2.4", "2.3"]

Dir.glob('./task/*-task.rb').each {|x| require x }

def run_test(ruby=nil, &b)
  argstr = "-r oktest -e Oktest.main -- test -sp"
  if ruby
    sh "#{ruby} #{argstr}", &b
  else
    ruby argstr, &b
  end
end


desc "retrieve example code from README"
task :examples do
  dir = "examples"
  rm_rf dir
  mkdir dir
  mkdir "#{dir}/config"
  #
  text = File.read("README.md", encoding: 'utf-8')
  rexp = /^File: `(.*?)`.*\n\n```.*\n((?:.|\n)*?)```/
  text.scan(rexp) do |filename, content|
    File.write("#{dir}/#{filename}", content, encoding: 'utf-8')
    puts "[create] #{dir}/#{filename}"
  end
end
