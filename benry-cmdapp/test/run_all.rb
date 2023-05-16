# -*- coding: utf-8 -*-


Dir.glob(File.dirname(__FILE__) + '/*.rb').each do |filename|
#$stderr.puts "\033[0;31m*** debug: filename=#{filename.inspect}\033[0m"
  require_relative File.basename(filename)
end
