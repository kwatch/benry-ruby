# -*- coding: utf-8 -*-


Dir.glob(File.dirname(__FILE__) + '/**/*_test.rb').each do |filename|
  require File.absolute_path(filename)
end
