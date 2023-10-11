# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2011 kwatch@gmail.com $
### $License: MIT License $
###


module Benry


  ##
  ## record method calls, or define fake methods.
  ##
  ## ex. record method calls
  ##    ## target class
  ##    class Calc
  ##      def average(*nums)   # average() calls total()
  ##        return total(*nums) / nums.length
  ##      end
  ##      def total(*nums)
  ##        t = 0; nums.each {|n| t += n }
  ##        return t   # or: return nums.sum
  ##      end
  ##    end
  ##    ## record method calls
  ##    rec = Benry::Recorder.new
  ##    calc = Calc.new
  ##    rec.record(calc, :total, :average)
  ##    ## call methods
  ##    calc.average(10, 20, 30, 40)
  ##    ## details of method calls
  ##    p rec.length               #=> 2
  ##    puts rec.inspect
  ##          #=> 0: #<Calc:0x001234abcd>.average(10, 20, 30, 40) #=> 25
  ##          #   1: #<Calc:0x001234abcd>.total(10, 20, 30, 40) #=> 100
  ##    #
  ##    p rec[0].obj               #=> #<Calc:0x001234abcd>
  ##    p rec[0].obj.equal?(calc)  #=> true
  ##    p rec[0].name              #=> :average
  ##    p rec[0].args              #=> [10, 20, 30, 40]
  ##    p rec[0].ret               #=> 25
  ##    #
  ##    p rec[1].obj               #=> #<Calc:0x001234abcd>
  ##    p rec[1].obj.equal?(calc)  #=> true
  ##    p rec[1].name              #=> :total
  ##    p rec[1].args              #=> [10, 20, 30, 40]
  ##    p rec[1].ret               #=> 100
  ##    #
  ##    p rec[0].to_a              #=> [obj, :average, [10, 20, 30, 40], 25]
  ##    p rec[1].to_a              #=> [obj, :total, [10, 20, 30, 40], 100]
  ##
  ## ex. fake method
  ##    rec = Benry::Recorder.new
  ##    calc = Calc.new
  ##    ## before
  ##    p calc.total(10, 20, 30, 40)     #=> 100
  ##    p calc.average(10, 20, 30, 40)   #=>  25
  ##    ## after
  ##    rec.fake_method(calc, :total=>123, :average=>34)
  ##    p calc.total(10, 20, 30, 40)     #=> 123
  ##    p calc.average(10, 20, 30, 40)   #=>  34
  ##
  ## ex. fake object
  ##    rec = Benry::Recorder.new
  ##    obj = rec.fake_object(:foo=>10, :bar=>20)
  ##    p obj.foo()                #=> 10
  ##    p obj.bar()                #=> 20
  ##    p obj.bar(3, 4, 'a'=>5)    # accepts any arguments
  ##
  class Recorder


    class Called

      def initialize(obj, name, args, ret)
        @obj  = obj
        @name = name
        @args = args
        @ret  = ret
      end

      #; [!m98p9] returns receiver object.
      #; [!es61g] returns method name.
      #; [!2yeeo] returns arguments.
      #; [!yd3hl] returns arguments.
      attr_accessor :obj, :name, :args, :ret

      def to_a()
        #; [!hrol9] returns array of obj, nae, args, and ret.
        return [@obj, @name, @args, @ret]
      end

      def inspect()
        #; [!g2iwe] represents internal data.
        s = args.collect {|arg| arg.inspect }.join(", ")
        return "#{obj.inspect}.#{name}(#{s}) #=> #{ret.inspect}"
      end

    end


    def initialize()
      @called = []
    end

    def length()
      @called.length
    end

    alias size length

    def [](index)
      return @called[index]
    end

    def inspect()
      #; [!k85bz] represents internal data.
      buf = []
      @called.each_with_index {|called, i| buf << "#{i}: #{called.inspect}\n" }
      return buf.join()
    end

    def record_method(obj, *method_names)
      #; [!61z3j] records method calls.
      called_list = @called
      proc_obj = proc do |obj, name, orig_method|
        (class << obj; self; end).class_eval do
          alias_method orig_method, name
          define_method(name) do |*args|
            called = Recorder::Called.new(obj, name.to_s.intern, args, nil)
            called_list << called
            #; [!9kh1f] calls original method.
            ret = obj.__send__(orig_method, *args)
            called.ret = ret
            ret
          end
        end
      end
      method_names.each do |name|
        proc_obj.call(obj, name, "__#{name}_orig".intern)
      end
      self
    end
    alias record record_method

    def fake_method(obj, **name_and_values)
      #; [!g112x] defines fake methods.
      called_list = @called
      proc_obj = proc do |obj, name, val|
        (class << obj; self; end).class_eval do
          #; [!kgvm1] defined methods can can take any arguments.
          define_method(name) do |*args|
            called_list << Recorder::Called.new(obj, name, args, val)
            val
          end
        end
      end
      name_and_values.each do |name, val|
        proc_obj.call(obj, name, val)
      end
      #; [!2p1b0] returns self.
      self
    end
    alias fake fake_method

    def fake_object(**name_and_values)
      #; [!hympr] creates fake object.
      obj = Object.new
      fake_method(obj, **name_and_values)
      return obj
    end

  end


end
