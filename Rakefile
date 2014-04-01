require "./lib/netnets"

task default: [:run]

task :run do
  sh "unicorn -p 3000 -c ./config/unicorn.rb"
end

task :scrape do
  require "mongo"
  include Mongo

  conn = MongoClient.new "localhost", 27017
  db = conn.db "test"
  collection = db.collection "stocks"

  length = NetNets.tickers.length
  NetNets.tickers.each_with_index do |ticker, i|
    puts "#{i} of #{length}"
    s = NetNets::Stock.new(ticker)
    s.calculate

    unless s.price_to_liquid_ratio > 0 && s.price_to_liquid_ratio < 75
      collection.insert s.to_json
    end
  end

  conn.close
end
