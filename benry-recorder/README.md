<!-- -*- coding: utf-8 -*- -->
# Benry-Recorder README

Benry-Recoder is a tiny utility that can:

* Record method calls of target object.
* Define fake methods on target object.
* Create fake object which has fake methods.


## Table of Contents

<!-- TOC -->

  * <a href="#how-to-record-method-calls">How to record method calls</a>
  * <a href="#how-to-define-fake-methods">How to define fake methods</a>
  * <a href="#how-to-create-fake-object">How to create fake object</a>
  * <a href="#license-and-copyright">License and Copyright</a>

<!-- /TOC -->


## How to record method calls

<!--
file: example1.rb
-->

```ruby
require 'benry/recorder'

class Calc
  def average(*nums)   # average() calls total()
    return total(*nums) / nums.length
  end
  def total(*nums)
    t = 0; nums.each {|n| t += n }
    return t   # or: return nums.sum
  end
end

## target object
calc = Calc.new

## record method calls
rec = Benry::Recorder.new
rec.record(calc, :total, :average)

## call methods
calc.average(10, 20, 30, 40)    # calls calc.total() internally

## details of method calls
p rec.length               #=> 2
puts rec.inspect
      #=> 0: #<Calc:0x001234abcd>.average(10, 20, 30, 40) #=> 25
      #   1: #<Calc:0x001234abcd>.total(10, 20, 30, 40) #=> 100
#
p rec[0].obj               #=> #<Calc:0x001234abcd>
p rec[0].obj.equal?(calc)  #=> true
p rec[0].name              #=> :average
p rec[0].args              #=> [10, 20, 30, 40]
p rec[0].ret               #=> 25
#
p rec[1].obj               #=> #<Calc:0x001234abcd>
p rec[1].obj.equal?(calc)  #=> true
p rec[1].name              #=> :total
p rec[1].args              #=> [10, 20, 30, 40]
p rec[1].ret               #=> 100
#
p rec[0].to_a              #=> [obj, :average, [10, 20, 30, 40], 25]
p rec[1].to_a              #=> [obj, :total, [10, 20, 30, 40], 100]
```


## How to define fake methods

<!--
file: example2.rb
-->

```ruby
require 'benry/recorder'

class Calc
  ....(snip)....
end

## target object
calc = Calc.new

## before
p calc.total(10, 20, 30, 40)     #=> 100
p calc.average(10, 20, 30, 40)   #=>  25

## define fake methods
rec = Benry::Recorder.new
rec.fake_method(calc, :total=>123, :average=>34)

## after
p calc.total(10, 20, 30, 40)     #=> 123
p calc.average(10, 20, 30, 40)   #=>  34
```


## How to create fake object

<!--
file: example3.rb
-->

```ruby
require 'benry/recorder'

rec = Benry::Recorder.new
obj = rec.fake_object(:foo=>10, :bar=>20)
p obj.foo()                #=> 10
p obj.bar()                #=> 20
p obj.bar(3, 4, 'a'=>5)    # accepts any arguments
```


## License and Copyright

* $License: MIT License $
* $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
