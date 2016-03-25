require 'active_record'
require 'logger'

class DatabaseConnector
  class << self
    def establish_connection
      ActiveRecord::Base.logger = Logger.new(active_record_logger_path)

      # configuration = YAML::load(IO.read(database_config_path))

      # template = ERB.new File.new(database_config_path).read
      # configuration = YAML.load template.result(binding)

      configuration = db_config

      ActiveRecord::Base.establish_connection(configuration)
    end

    private

    def active_record_logger_path
      'debug.log'
    end

    def database_config_path
      'config/database.yml.erb'
    end

    def db_config
      {"adapter"=>ENV['DATABASE_ADAPTER'], "database"=>ENV['DATABASE_NAME'], "encoding"=>"unicode", "pool"=>5, "timeout"=>5000}
    end
  end
end
