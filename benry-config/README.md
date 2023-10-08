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

File: `config/config.rb`

```ruby
require 'benry/config'

class BaseConfig < Benry::BaseConfig
  ## add names and values
  add :db_host          , "localhost"
  add :db_user          , "user1"
  add :db_pass          , ABSTRACT       # should be set value in subclass
  add :session_cookie   , "sess"
  add :session_secret   , SECRET
  ## or:
  #add :db_pass         , ABSTRACT['DB_PASS']    # get value from ENV
  #add :session_secret  , SECRET['SESS_SECRET']  # get secret value from ENV
end
```

File: `config/config_dev.rb` (for development environment)

```ruby
## for development environment
class AppConfig < BaseConfig
  ## set (= override) existing values
  set :db_pass          , "pass1"        # set ABSTRACT value
end
```

File: `config/config_prod.rb` (for production environment)

```ruby
## for production environment
class AppConfig < BaseConfig
  ## set (= override) existing values
  set :db_host          , "db-master"    # override existing value
  set :db_pass          , "passXXX"      # set ABSTRACT value
  ## error because `:db_name` is not defined in paremnt class.
  set :db_name          , "prod1"        # error! (not defined)
end
```

File: `config/config.private` (should be ignored by `.gitignore`)

```ruby
## this file should be ignored by '.gitignore', and
## file permission should be `600`.
AppConfig.class_eval do
  set :session_secret   , "YRjCIAiPlCBvwLUq5mnZ"  # set SECRET value
end
```

File: `main.rb`

```ruby
## load config files
app_env = ENV['APP_ENV']  or raise "$APP_ENV required."
require "./config/config.rb"                # defines BaseConfig class
require "./config/config_#{app_env}.rb"     # defines Config class
load    "./config/config.private"
## or:
#load   "./config/config.#{app_env}.private"

## create a config object
$config = AppConfig.new.freeze
#
p $config.db_user             #=> "user1"
p $config.db_pass             #=> "pass1"
p $config.session_cookie      #=> "sess"
p $config.session_secret      #=> "YRjCIAiPlCBvwLUq5mnZ"
#
p $config.get_all(:db_)       #=> {:host=>"localhost", :user=>"user1", :pass=>"pass1"}
p $config.get_all(:session_)  #=> {:cookie=>"sess", :secret=>"YRjCIAiPlCBvwLUq5mnZ"}
#
$config.each  {|k, v| puts "#{k}=#{v.inspect}" }   # hide secret values as "(secret)"
$config.each! {|k, v| puts "#{k}=#{v.inspect}" }   # not hide secret values
```


Copyright and License
---------------------

$Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $

$License: MIT License $
