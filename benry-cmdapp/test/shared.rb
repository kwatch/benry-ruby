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
  category "git:"

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


class DeepPrefixAction < Benry::CmdApp::Action
  category "giit:", "gitt commands" do

    #@action.("show current status in compact format")
    #def status()
    #  sys "git status -sb"
    #end

    category "staging:" do
      @action.("add changes into staging area")
      def add(); end
      @action.("show changes in staging area")
      def show(); end
      @action.("delete changes in staging area")
      def delete(); end
    end

    category "commit:" do
      @action.("list commits")
      def list(); end
    end

    category "branch:" do
      @action.("list branches")
      def list(); end
      @action.("switch branch")
      def switch(name); end
    end

    category "repo:" do
      @action.("create direcotry, move to it, and init repository")
      def create(); end
      @action.("initialize git repository with initial empty commit")
      def init(); end

      category "config:" do
        @action.("add config of repository")
        def add(); end
        @action.("delete config of repository")
        def delete(); end
        @action.("list config of repository")
        def list(); end
      end

      category "remote:" do
        @action.("list remote repositories")
        def list(); end
        @action.("set remote repo url ('github:<user>/<proj>' available)")
        def set(); end
      end

    end

  end

  category "md:", "markdown actions" do
    @action.("create *.html", hidden: true)
    def html(); end
    @action.("create *.txt", hidden: true)
    def txt(); end
  end

end
