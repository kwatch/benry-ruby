# -*- coding: utf-8 -*-


Dir.glob(File.dirname(__FILE__) + '/**/*.rb').each do |filename|
  if filename != __FILE__
    require_relative File.basename(filename)
  end
end
