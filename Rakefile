require "./lib/netnets"

task default: [:run]

task :run do
  sh "unicorn -p 3000 -c ./config/unicorn.rb"
end

task :scrape do
  require "./app"
  require "mongo"
  include Mongo

  db = get_db_connection
  collection = db.collection "stocks"

  collection.drop

  length = NetNets.tickers.length
  NetNets.tickers.each_with_index do |ticker, i|
    puts "#{i} of #{length}"
    s = NetNets::Stock.new(ticker)
    s.calculate

    if s.price_to_liquid_ratio > 0 && s.price_to_liquid_ratio < 75
      collection.insert s.to_json
    end
  end

  db.client.close
end

task :test do
  db = get_db_connection
  collection = db.collection "test"
  puts "Worked"
  db.client.close
end
