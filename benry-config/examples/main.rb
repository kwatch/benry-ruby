## load config files
app_env = ENV['APP_ENV']  or raise "$APP_ENV required."
require "./config/app.rb"                # defines AppConfigBase class
require "./config/app_#{app_env}.rb"     # defines AppConfig class
load    "./config/app.private"
## or:
#load   "./config/app.#{app_env}.private"

## create a config object
$config = AppConfig.new.freeze
#
p $config.db_user             #=> "user1"
p $config.db_pass             #=> "pass1"
p $config.session_cookie      #=> "sess"
p $config.session_secret      #=> "YRjCIAiPlCBvwLUq5mnZ"
#
p $config.defined?(:db_user)  #=> true
p $config.defined?(:db_pass)  #=> true
p $config.defined?(:db_name)  #=> false
#
p $config.get_all(:db_)       #=> {:host=>"localhost", :user=>"user1", :pass=>"pass1"}
p $config.get_all(:session_)  #=> {:cookie=>"sess", :secret=>"YRjCIAiPlCBvwLUq5mnZ"}
#
$config.each  {|k, v| puts "#{k}=#{v.inspect}" }   # hide secret values as "(secret)"
$config.each! {|k, v| puts "#{k}=#{v.inspect}" }   # not hide secret values
