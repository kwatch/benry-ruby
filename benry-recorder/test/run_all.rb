# -*- coding: utf-8 -*-

Dir.glob(File.join(File.dirname(__FILE__), '**/*_test.rb')).each do |x|
  #require x
  require File.absolute_path(x)
  #load x
end
