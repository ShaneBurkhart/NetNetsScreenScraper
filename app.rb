require "sinatra"
require "haml"
require "./lib/db"
require "./lib/stock"

configure do
  enable :sessions
  set :db, NetNets::DB.connection
end

get "/" do
  haml :index, locals: { flash: session[:flash] }
end

post "/_email" do
  summary = File.new(File.join(File.dirname(__FILE__), "views/mail.txt"), "r").read

  stocks = NetNets::Stock.all

  labels = [
    "Ticker",
    "Current Price",
    "Outstanding Shares",
    "Liabilities",
    "Tangible Assets",
    "Net Liquid Capital",
    "Net Liquid Capital Per Share",
    "Price To Liquid Ratio",
  ]

  haml :stocks, locals: { stocks: stocks, labels: labels, summary: summary}
end
