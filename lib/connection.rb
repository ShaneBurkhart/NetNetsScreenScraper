require "mongo"

include Mongo

def get_mongo_connection
  puts ENV['MONGOHQ_URL']
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  Mongo::Connection.new(db.host, db.port)
end

def get_db_connection client
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = client.db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
  @db_connection
end
