# -*- coding: utf-8 -*-
# frozen_string_literal: true


require 'oktest'

require 'benry/cmdapp'


class MyAction < Benry::CmdApp::Action

  @action.("greeting message")
  @option.(:lang, "-l, --lang=<lang>", "language name (en/fr/it)")
  def hello(name="world", lang: "en")
    case lang
    when "en"  ; puts "Hello, #{name}!"
    when "fr"  ; puts "Bonjour, #{name}!"
    when "it"  ; puts "Chao, #{name}!"
    else
      raise "#{lang}: unkown language"
    end
  end

  @action.("hidden action", hidden: true)
  @option.(:val, "--val=<val>", "something value", hidden: true)
  def debuginfo(val: nil)
    puts "val: #{val.inspect}"
  end

  @action.("raises ZeroDivisionError")
  def testerr1()
    1/0
  end

  @action.("looped action")
  def testerr2()
    run_once "testerr3"
  end

  @action.("looped action")
  def testerr3()
    run_action "testerr2"
  end

end


class GitAction < Benry::CmdApp::Action
  prefix "git:"

  @action.("same as `git add -p`")
  def stage(*file)
    puts "git add -p #{file.join(' ')}"
  end

  @action.("same as `git diff --cached`")
  def staged()
    puts "git diff --cached"
  end

  @action.("same as `git reset HEAD`")
  def unstage()
    puts "git reset HEAD"
  end

  private

  @action.("same as `git commit --amend`")
  def correct()
    puts "git commit --amend"
  end

end
