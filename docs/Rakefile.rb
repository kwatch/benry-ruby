# -*- coding: utf-8 -*-

#task :default => :all
task :default do
  sh "rake -T", verbose: false
end

desc "generate all"
task :all => [:index]

desc "generate 'index.html'"
task :index do
  x = "index"
  sh "ruby ./md2 #{x}.mdx > #{x}.html"
end
