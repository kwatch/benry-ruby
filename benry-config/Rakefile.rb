# -*- coding: utf-8 -*-


PROJECT   = "benry-config"
RELEASE   = ENV['RELEASE'] || "0.0.0"
COPYRIGHT = "copyright(c) 2016 kwatch@gmail.com"
LICENSE   = "MIT License"

README_DESTDIR   = "examples"

Dir.glob('./task/*-task.rb').each {|x| require x }

desc "retrieve example code from README"
task :examples => "readme:retrieve"
