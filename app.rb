require "sinatra"
require "haml"
require "date"
require "pony"
require "uri"
require "./lib/connection"


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
  set :mongo_db, get_db_connection(get_mongo_connection)
end

get "/" do
  haml :index, locals: { flash: session[:flash] }
end

post "/_email" do
  file = File.new(File.join(File.dirname(__FILE__), "views/mail.txt"), "r").read

  settings.mongo_db["stocks"].find.each do |stock|
    stock.keys.each do |key|
      file += "#{key} : #{stock[key]}" unless key == "_id"
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
