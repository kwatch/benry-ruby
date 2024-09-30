# -*- coding: utf-8 -*-

require_relative './shared'


Oktest.scope do


  topic Benry::MicroRake do


    topic '.main()' do

      spec "[!23nxr] command name will be set automatically." do
        bkup = $0
        $0 = "/usr/bin/urake7"
        at_end { $0 = bkup }
        sout = capture_sout { Benry::MicroRake.main([]) }
        ok {sout} =~ /^Usage: urake7 \[<options>\] <task>$/
      end

      spec "[!61tgk] returns 0 if command finished successfully." do
        exit_code = nil
        capture_sout { exit_code = Benry::MicroRake.main(["hello"]) }
        ok {exit_code} == 0
      end

      spec "[!9u4mu] returns 1 if command finished unsuccessfully." do
        exit_code = nil
        sout, serr = capture_sio { exit_code = Benry::MicroRake.main(["hi-yo"]) }
        ok {exit_code} == 1
        ok {sout} == ""
        ok {serr} == "[ERROR] hi-yo: Task not defined.\n"
      end

    end


  end


end
