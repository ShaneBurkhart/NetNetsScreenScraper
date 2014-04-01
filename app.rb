require "sinatra"
require "haml"
require "date"
require "mongo"
require "pony"
require "uri"

include Mongo

Pony.options = {
  :via => :smtp,
  :via_options => {
    :address => 'smtp.sendgrid.net',
    :port => '587',
    :domain => 'heroku.com',
    :user_name => ENV['SENDGRID_USERNAME'],
    :password => ENV['SENDGRID_PASSWORD'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
}

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

configure do
  enable :sessions
  set :mongo_db, get_db_connection(get_mongo_connection)
end

get "/" do
  haml :index, locals: { flash: session[:flash] }
end

post "/_email" do
  file = File.new(File.join(File.dirname(__FILE__), "view/mail.txt"), "r").read

  settings.mongo_db["stocks"].find.each do |stock|
    stock.keys.each do |key|
      file += "#{key} : #{stock}" unless key == "_id"
      file += "\n\n"
    end
  end


  Pony.mail   to: params[:email],
              from: "noreply@shaneburkhart.com",
              subject: "Here are some stocks!",
              body: file

  session[:flash] = "Success!"

  redirect to("/")
end
