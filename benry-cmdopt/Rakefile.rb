# -*- coding: utf-8 -*-


PROJECT   = "benry-cmdopt"
RELEASE   = ENV['RELEASE'] || "0.0.0"
COPYRIGHT = "copyright(c) 2021-2023 kuwata-lab.com all rights reserved"
LICENSE   = "MIT License"

RUBY_VERSIONS = ["3.2", "3.1", "3.0", "2.7", "2.6", "2.5", "2.4", "2.3"]

Dir.glob('./task/*-task.rb').each {|x| require x }


## override
def run_test(ruby=nil, &b)
  args = %w[-r oktest -e Oktest.main -- test -sc]
  file = "test/run_all.rb"
  args = [file] if File.exist?(file)
  if ruby
    sh(ruby, *args, &b)
  else
    ruby(*args, &b)
  end
end
