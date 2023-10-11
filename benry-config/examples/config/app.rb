require 'benry/config'

class AppConfigBase < Benry::BaseConfig
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
