# -*- coding: utf-8 -*-


PROJECT   = "benry-cmdapp"
RELEASE   = ENV['RELEASE'] || "0.0.0"
COPYRIGHT = "copyright(c) 2023 kwatch@gmail.com"
LICENSE   = "MIT License"

#RUBY_VERSIONS = ["3.2", "3.1", "3.0", "2.7", "2.6", "2.5", "2.4", "2.3"]

Dir.glob('./task/*-task.rb').each {|x| require x }
