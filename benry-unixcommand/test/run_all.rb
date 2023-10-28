# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2021 kwatch@gmail.com $
### $License: MIT License $
###

here = File.dirname(File.expand_path(__FILE__))
lib  = File.join(File.dirname(here), 'lib')
$LOAD_PATH << lib unless $LOAD_PATH.include?(lib)
Dir.glob(here + '/**/*_test.rb').each do |fpath|
  require fpath
end
