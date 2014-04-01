require "sinatra"
require "haml"
require "date"
require "mongo"
require "json/ext"
require "pony"

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

configure do
  enable :sessions
  conn = MongoClient.new("localhost", 27017)
  set :mongo_connection, conn
  set :mongo_db, conn.db("test")
end

get "/" do
  haml :index, locals: { flash: session[:flash] }
end

post "/_email" do
  @stocks = []
  settings.mongo_db["stocks"].find.each{ |stock| @stocks << stock }

  Pony.mail   to: params[:email],
              from: "noreply@shaneburkhart.com",
              subject: "Here are some stocks!",
              body: haml(:mail, locals: { stocks: @stocks })

  session[:flash] = "Success!"

  redirect to("/")
end

