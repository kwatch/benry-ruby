# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2011 kwatch@gmail.com $
### $License: MIT License $
###

File.class_eval do
  libpath = join(dirname(dirname(expand_path(__FILE__))), 'lib')
  $LOAD_PATH.unshift(libpath) unless $LOAD_PATH.include?(libpath)
end

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/ok'

require 'benry/recorder'


class Calc4190
  def average(*nums)   # average() calls total()
    return total(*nums) / nums.length
  end
  def total(*nums)
    t = 0
    nums.each {|n| t += n }
    return t   # or return nums.sum
  end
end


describe Benry::Recorder do

  describe '#record_method()' do
    it "[!61z3j] records method calls." do
      rec = Benry::Recorder.new
      calc = Calc4190.new
      rec.record_method(calc, :total, :average)
      avg = calc.average(10, 20, 30, 40)   #=> 25
      #
      ok {rec.length}  == 2
      #
      ok {rec[0].obj}  == calc
      ok {rec[0].name} == :average
      ok {rec[0].args} == [10, 20, 30, 40]
      ok {rec[0].ret}  == 25
      #
      ok {rec[1].obj}  == calc
      ok {rec[1].name} == :total
      ok {rec[1].args} == [10, 20, 30, 40]
      ok {rec[1].ret}  == 100
    end
    it "[!9kh1f] calls original method." do
      rec = Benry::Recorder.new
      calc = Calc4190.new
      rec.record_method(calc, :total, :average)
      ok {calc.average(10, 20, 30, 40)} == 25
      ok {calc.average(1.0, 2.0, 3.0, 4.0)} == 2.5
    end
  end

  describe '#fake_method()' do
    it "[!g112x] defines fake methods." do
      rec = Benry::Recorder.new
      calc = Calc4190.new
      rec.fake_method(calc, :total=>150)
      ret = calc.average(10, 20)  # calc.average() calls calc.total() internally
      ok {ret} == 75              # 75 == 150/2
      #
      ok {rec.length}  == 1
      ok {rec[0].obj}  == calc
      ok {rec[0].name} == :total
      ok {rec[0].args} == [10, 20]
      ok {rec[0].ret}  == 150
    end
    it "[!kgvm1] defined methods can can take any arguments." do
      rec = Benry::Recorder.new
      calc = Calc4190.new
      rec.fake_method(calc, :total=>999)
      ret = calc.total(10, 20, :a=>1, 'b'=>2)
      ok {ret} == 999
      #
      ok {rec.length}  == 1
      #
      ok {rec[0].obj}  == calc
      ok {rec[0].name} == :total
      ok {rec[0].args} == [10, 20, {:a=>1, 'b'=>2}]
      ok {rec[0].ret}  == 999
    end
    it "[!2p1b0] returns self." do
    end
  end

  describe '#fake_object()' do
    it "[!hympr] creates fake object." do
      rec = Benry::Recorder.new
      obj = rec.fake_object(:foo=>123, :bar=>"abc")
      ok {obj.foo(10, 20, 'a'=>1, 'b'=>2)} == 123
      ok {obj.bar(30, 40, x: 8, y: 9)} == "abc"
      #
      ok {rec.length}  == 2
      #
      ok {rec[0].obj}  == obj
      ok {rec[0].name} == :foo
      ok {rec[0].args} == [10, 20, {'a'=>1, 'b'=>2}]
      ok {rec[0].ret}  == 123
      #
      ok {rec[1].obj}  == obj
      ok {rec[1].name} == :bar
      ok {rec[1].args} == [30, 40, {:x=>8, :y=>9}]
      ok {rec[1].ret}  == "abc"
    end
  end

  describe '#inspect()' do
    it "[!k85bz] represents internal data." do
      rec = Benry::Recorder.new
      calc = Calc4190.new
      rec.fake_method(calc, :total=>200)
      rec.record_method(calc, :average)
      ret = calc.average(10, 20, 30, 40)
      #
      s = rec.inspect.gsub(/#<Calc4190:0x\w+>/, '#<Calc4190:0xXXXX>')
      ok {s} == ("0: #<Calc4190:0xXXXX>.average(10, 20, 30, 40) #=> 50\n"\
                 "1: #<Calc4190:0xXXXX>.total(10, 20, 30, 40) #=> 200\n")
    end
  end

end


describe Benry::Recorder::Called do

  before do
    @calc = Calc4190.new
    @rec = Benry::Recorder.new
    @rec.record_method(@calc, :total, :average)
    avg = @calc.average(10, 20, 30, 40)   #=> 25
    @called0 = @rec[0]
    @called1 = @rec[1]
  end

  describe '#obj' do
    it "[!m98p9] returns receiver object." do
      ok {@called0.obj} == @calc
      ok {@called1.obj} == @calc
    end
  end

  describe '#name' do
    it "[!es61g] returns method name." do
      ok {@called0.name} == :average
      ok {@called1.name} == :total
    end
  end

  describe '#args' do
    it "[!2yeeo] returns arguments." do
      ok {@called0.args} == [10, 20, 30, 40]
      ok {@called1.args} == [10, 20, 30, 40]
    end
  end

  describe '#ret' do
    it "[!yd3hl] returns arguments." do
      ok {@called0.ret} == 25
      ok {@called1.ret} == 100
    end
  end

  describe '#to_a' do
    it "[!hrol9] returns array of obj, nae, args, and ret." do
      ok {@called0.to_a} == [@calc, :average, [10, 20, 30, 40], 25]
      ok {@called1.to_a} == [@calc, :total,   [10, 20, 30, 40], 100]
    end
  end

  describe '#inspect()' do
    it "[!g2iwe] represents internal data." do
      rexp = /\A#<Calc4190:0x\w+>\.average\(10, 20, 30, 40\) #=> 25\z/
      ok {@called0.inspect()} =~ rexp
    end
  end

end
