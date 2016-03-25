require 'rubygems'
require 'bundler/setup'

# require 'pg'
require 'sqlite3'
require 'active_record'
require 'yaml'

namespace :db do

  desc 'Migrate the database'
  task :migrate do
    connection_details = db_config
    ActiveRecord::Base.establish_connection(connection_details)
    ActiveRecord::Migrator.migrate('db/migrate/')
  end

  desc 'Create the database'
  task :create do
    connection_details = db_config
    admin_connection = connection_details.merge({'database'=> 'postgres',
                                                'schema_search_path'=> 'public'})
    ActiveRecord::Base.establish_connection(admin_connection)
    ActiveRecord::Base.connection.create_database(connection_details.fetch('database'))
  end

  desc 'Drop the database'
  task :drop do
    connection_details = db_config
    admin_connection = connection_details.merge({'database'=> 'postgres',
                                                'schema_search_path'=> 'public'})
    ActiveRecord::Base.establish_connection(admin_connection)
    ActiveRecord::Base.connection.drop_database(connection_details.fetch('database'))
  end

  def db_config
    {"adapter"=>ENV['DATABASE_ADAPTER'], "database"=>ENV['DATABASE_NAME'], "encoding"=>"unicode", "pool"=>5, "timeout"=>5000}
  end

end
