require "sinatra"
require "haml"
require "pony"
require "./lib/db"
require "./lib/stock"


Pony.options = {
  :via => :smtp,
  :via_options => {
    :address => 'smtp.gmail.com',
    :port => '587',
    :domain => 'gmail.com',
    :user_name => ENV['GMAIL_USERNAME'],
    :password => ENV['GMAIL_PASSWORD'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
}

configure do
  enable :sessions
  set :db, NetNets::DB.connection
end

get "/" do
  haml :index, locals: { flash: session[:flash] }
end

post "/_email" do
  file = File.new(File.join(File.dirname(__FILE__), "views/mail.txt"), "r").read

  NetNets::Stock.all.each do |stock|
    file += [
      "ticker: #{stock[1]}",
      "current_price: $#{stock[2]}",
      "outstanding_shares: #{stock[3]}",
      "liabilities: #{stock[4]}",
      "tangible_assets: #{stock[5]}",
      "net_liquid_capital: #{stock[6]}",
      "net_liquid_capital_per_share: #{stock[7]}",
      "price_to_liquid_ratio: #{stock[8]}%",
      "",
      ""
    ].join("\n")
  end

  Pony.mail   to: params[:email],
              from: "shaneburkhart@gmail.com",
              subject: "Here are some stocks!",
              body: file

  session[:flash] = "Success!"

  redirect to("/")
end
