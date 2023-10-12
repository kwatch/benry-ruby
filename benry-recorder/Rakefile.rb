# -*- coding: utf-8 -*-


PROJECT   = "benry-recorder"
RELEASE   = ENV['RELEASE'] || "0.0.0"
COPYRIGHT = "copyright(c) 2011 kwatch@gmail.com"
LICENSE   = "MIT License"

README_EXTRACT  = /^file: (.*\.rb)/

Dir.glob("./task/*.rb").sort.each {|x| require_relative x }

def run_test(ruby=nil, &b)
  ## benry-recorder is depended by Oktest, therefore benry-recorder
  ## should NOT adopt Oktest. Use MiniTest instead.
  run_minitest(ruby, &b)
end

def readme_extract_callback(filename, str)
  if filename == 'example1.rb'
    str =~ /class Calc\n(.*?)^end\n/m
    $_classdef = $1
  elsif filename == 'example2.rb'
    str = str.sub(/^ *\.\.\.+\(snip\)\.\.\.+ *\n/, $_classdef)
  end
  return str
end
