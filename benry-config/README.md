benry-config
============

($Release: 0.0.0 $)


Overview
--------

Utility class to support configuration.

* Easy to define configuration for environments (production, development, ...).
* Raises error when configuration name is wrong (typo).
* Represents secret configurations which should be set by environment var or in private file.


Example
-------

```ruby
#----- config/common.rb -----
require 'benry/config'
class CommonConfig < Benry::BaseConfig
  add :db_user            , "user1"
  add :db_pass            , ABSTRACT
  add :session_cooie      , "sess"
  add :session_secret     , SECRET
  ## or:
  #add :session_secret    , SECRET['SESSION_SECRET']  # get secret value from ENV
end

#----- config/development.rb -----
require 'config/common'
class Config < CommonConfig
  set :db_pass            , "pass1"
end

#----- config/development.private -----
Config.class_eval do
  set :session_secret     , "YRjCIAiPlCBvwLUq5mnZ"
end

#----- main.rb -----
## Ruby < 2.2 has obsoleted 'Config' class, therefore remove it at first.
Object.class_eval { remove_const :Config } if defined?(Config)
#
rack_env = ENV['RACK_ENV']  or raise "$RACK_ENV required."
require "./config/#{rack_env}.rb"
load    "./config/#{rack_env}.private"
#
$config = Config.new.freeze
p $config.db_user             #=> "user1"
p $config.db_pass             #=> "pass1"
p $config.session_cookie      #=> "sess"
p $config.session_secret      #=> "YRjCIAiPlCBvwLUq5mnZ"
#
p $config.get_all(:db_)       #=> {:user=>"user1", :pass=>"pass1"}
p $config.get_all(:session_)  #=> {:cookie=>"sess", :secret=>"YRjCIAiPlCBvwLUq5mnZ"}
#
$config.each  {|k, v| puts "#{k}=#{v.inspect}" }   # hide secret values as "(secret)"
$config.each! {|k, v| puts "#{k}=#{v.inspect}" }   # not hide secret values
```


Copyright and License
---------------------

$Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $

$License: MIT License $
