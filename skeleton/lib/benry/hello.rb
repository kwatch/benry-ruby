# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2020 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


module Benry
end


module Benry::Hello


  VERSION = '$Release: 0.0.0 $'.split()[1]


  def self.hello(user="world")
    return "Hello, #{user}!"
  end


end
