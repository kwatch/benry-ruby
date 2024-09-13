# -*- coding: utf-8 -*-
# frozen_string_literal: true

##
## Rake compatible tasks
##

CLEAN = ["**/*~", "**/*.bak", "**/core"] \
          .collect {|pat| Dir.glob(pat) }.flatten \
          .select {|x| File.file?(x) }
CLOBBER = []

#desc "delete garbage files"
desc "Remove any temporary products"
task :clean do
  rm_rf CLEAN
end

#desc "delete product files as well as garbage files"
desc "Remove any generated files"
task :clobber => :clean do
  rm_rf CLOBBER
end
