# -*- coding: utf-8 -*-


PROJECT   = "benry-config"
RELEASE   = ENV['RELEASE'] || "0.0.0"
COPYRIGHT = "copyright(c) 2016 kuwata-lab.com all rights reserved"
LICENSE   = "MIT License"

RUBY_VERSIONS = ["3.2", "3.1", "3.0", "2.7", "2.6", "2.5", "2.4", "2.3"]

Dir.glob('./task/*-task.rb').each {|x| require x }

def run_test(ruby=nil, &b)
  if ruby
    sh "#{ruby} test/config_test.rb", &b
  else
    ruby "test/config_test.rb", &b
  end
end
