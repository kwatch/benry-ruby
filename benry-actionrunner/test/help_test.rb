# -*- coding: utf-8 -*-
# frozen_string_literal: true


require_relative './shared'


Oktest.scope do

  before_all do
    TestHelperModule.setup_all()
  end

  after_all do
    TestHelperModule.teardown_all()
  end


  topic Benry::ActionRunner::ApplicationHelpBuilderModule do

    topic('#section_options()') {
      topic "option '-h, '--help'" do
        spec "[!xsfzi] adds '--<name>=<value>' to help message." do
          sout = arun "-h"
          ok {sout} =~ /^  --<name>=<value>   : set a global variable \(value can be in JSON format\)$/
        end
      end
    }

  end


end
