require 'active_record'
require 'logger'

class DatabaseConnector
  class << self
    def establish_connection
      ActiveRecord::Base.logger = Logger.new(active_record_logger_path)

      # configuration = YAML::load(IO.read(database_config_path))
      configuration = db_config

      ActiveRecord::Base.establish_connection(configuration)
    end

    private

    def active_record_logger_path
      'debug.log'
    end

    def database_config_path
      'config/database.yml'
    end

    def db_config
      {"adapter"=>"sqlite3", "database"=>ENV['DATABASE'], "encoding"=>"unicode", "pool"=>5, "timeout"=>5000}
    end
  end
end
