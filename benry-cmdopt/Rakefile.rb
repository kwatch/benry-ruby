# -*- coding: utf-8 -*-


PROJECT   = "benry-cmdopt"
RELEASE   = ENV['RELEASE'] || "0.0.0"
COPYRIGHT = "copyright(c) 2021-2023 kuwata-lab.com all rights reserved"
LICENSE   = "MIT License"


desc "do test"
task :test do
  sh "ruby", *Dir.glob("test/*.rb")
end

Dir.glob('./task/*-task.rb').each {|x| require x }
