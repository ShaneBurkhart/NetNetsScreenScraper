require "./lib/stock"
require "./lib/db"

task default: [:scrape]

task :scrape do
  NetNets::DB.connection

  NetNets::Stock.tickers.each do |ticker|
    s = NetNets::Stock.new(ticker)
    s.calculate
    s.save
  end

  NetNets::DB.close
end

task :run do
  sh "unicorn -p 3000 -c ./config/unicorn.rb"
end
