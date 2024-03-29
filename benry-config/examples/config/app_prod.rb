require_relative './app'

## for production environment
class AppConfig < AppConfigBase
  ## set (= override) existing values
  set :db_host          , "db-master"    # override existing value
  set :db_pass          , "passXXX"      # set ABSTRACT value
  ## error because `:db_name` is not defined in paremnt class.
  set :db_name          , "prod1"        #=> Benry::ConfigError (not defined)
end
