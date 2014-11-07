require "./lib/stock"
require "./lib/db"

task default: [:scrape]

task :scrape do
  NetNets::DB.connection

  NetNets::Stock.clear

  NetNets::Stock.tickers.each do |ticker|
    s = NetNets::Stock.new(ticker)
    s.calculate
    s.save
  end

  puts
  puts "Missed Attributes:"
  puts NetNets::Stock.class_variable_get(:@@missed_attrs)

  NetNets::DB.close
end

task :run do
  sh "unicorn -p 3000 -c ./config/unicorn.rb"
end

task :run_prod do
  sh "unicorn -p 80 -c ./config/unicorn.rb"
end
