# -*- coding: utf-8 -*-

require 'oktest'

require 'benry/hello'


Oktest.scope do


  topic Benry::Hello do


    topic '.hello()' do

      spec "returns greeting message." do
        msg = Benry::Hello.hello()
        ok {msg} == "Hello, world!"
      end

      spec "accepts user name." do
        msg = Benry::Hello.hello("John")
        ok {msg} == "Hello, John!"
      end

    end


  end


end
