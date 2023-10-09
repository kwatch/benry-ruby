benry-yamlutil
==============

($Release: 0.0.0 $)

(**EXPERIMENTAL; NOT RELEASED**)


Overview
--------

Utility for YAML.

Features:

* Specify custom classes instead of Hash class.


Table of Contents
-----------------

<!-- TOC -->

<!-- /TOC -->


Example1: Custom Classes
------------------------

file: ex1.yaml
```yaml
teams:
  - name: SOS Brigade
    members:
      - {name: Haruhi, gender: F}
      - {name: Kyon  , gender: M}
      - {name: Mikuru, gender: F}
      - {name: Itsuki, gender: M}
      - {name: Yuki  , gender: F}
```

file: ex1.rb
```ruby
require 'yaml'
require 'benry/yamlutil'

## define custom classes (strongly recommend to use Struct class)
Team   = Struct.new('Team',   :name, :members)
Member = Struct.new('Member', :name, :gender)

## define classmap
classmap = {
  "teams"    => Team,
  "members"  => Member,
}

## parse YAML string with classmap
yamlstr = File.read('ex1.yaml')
ydoc = Benry::YAMLUtil.load(yamlstr, classmap)

## 'Team' and 'Member' classes are used instead of Hash
p ydoc['tables'][0].class                #=> Struct::Table
p ydoc['tables'][0]['members'][0].class  #=> Struct::Member

## you can access data by `obj.foo.bar` instead of `obj['foo']['bar']`.
team = ydoc['tables'][0]
p team.name                        #=> "SOS Brigade"
p team.members[0].name             #=> "Haruhi"
p team.members[0].gender           #=> "F"
```


Example2: MagicHash
-------------------

file: ex2.yaml
```yaml
teams:
  - name: SOS Brigade
    members:
      - {name: Haruhi, gender: F}
      - {name: Kyon  , gender: M}
      - {name: Mikuru, gender: F}
      - {name: Itsuki, gender: M}
      - {name: Yuki  , gender: F}
```

file: ex2.rb
```ruby
require 'yaml'
require 'benry/yamlutil'

## define custom Hash class
class MagicHash < Hash
  ## allows `hashobj.foo` instead of `hashobj['foo']`
  def method_missing(name, *args)
    return self[name.to_s] if args.empty?
    super
  end
end

## define classmap
classmap = {
  "*"   => MagicHash,
}

## parse YAML string with classmap
yamlstr = File.read('ex2.yaml')
ydoc = Benry::YAMLUtil.load(yamlstr, classmap)

## MagicHash class is used instead of Hash class.
p ydoc.class                              #=> MagicHash
p ydoc['tables'][0].class                 #=> MagicHash
p ydoc['tables'][0]['members'][0].class   #=> MagicHash

## you can access data by `obj.foo.bar` instead of `obj['foo']['bar']`.
team = ydoc.tables[0]
p team.name                #=> "SOS Brigade"
p team.members[0].name     #=> "Haruhi"
p team.members[0].gender   #=> "F"
```


Topics
------

### `#[key]` and `#[key, val]`

Custom class should implement `#[key]` and `#[key, val]`, or you will get error
when parsing YAML document.

For example:

```ruby
Team = Struct.new('Team', :name, :members) do
  # ... define methods here ...
end

Members = Struct.new('Members', :name, :gender) do
  # ... define methods here ...
end
```

Or:

```ruby
class Team
  attr_accessor :name, :members
  def [](k); instance_variable_get("@#{k}"); end
  def [](k, v); instance_variable_set("@#{k}", v); end
end

class Member
  attr_accessor :name, :gender
  def [](k); instance_variable_get("@#{k}"); end
  def [](k, v); instance_variable_set("@#{k}", v); end
end
```


### YAML Tag

Custom class feature may not work well if there is YAML tags.
In order to work well with YAML tags, please +1 to this pull request:



Copyright and License
---------------------

$Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $

$License: MIT License $
