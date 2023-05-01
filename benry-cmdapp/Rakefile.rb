# -*- coding: utf-8 -*-


PROJECT   = "benry-cmdapp"
RELEASE   = ENV['RELEASE'] || "0.0.0"
COPYRIGHT = "copyright(c) 2023 kuwata-lab.com all rights reserved"
LICENSE   = "MIT License"


def run_test(ruby=nil, &b)
  if ruby
    #sh "#{ruby} test/cmdapp_test.rb", &b      # for MiniTest
    sh "#{ruby} test/cmdapp_test.rb -sc", &b   # for Oktest
  else
    #ruby "test/cmdapp_test.rb", &b            # for MiniTest
    sh "oktest test/cmdapp_test.rb -sc", &b    # for Oktest
  end
end

RUBY_VERSIONS = ["3.2", "3.1", "3.0", "2.7", "2.6", "2.5", "2.4", "2.3"]

Dir.glob('./task/*-task.rb').each {|x| require x }
