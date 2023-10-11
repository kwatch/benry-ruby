require_relative './app'

## for development environment
class AppConfig < AppConfigBase
  ## set (= override) existing values
  set :db_pass          , "pass1"        # set ABSTRACT value
end
