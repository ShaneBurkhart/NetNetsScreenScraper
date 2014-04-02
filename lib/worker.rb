require "./lib/connection"
require "sidekiq"
require "mongo"

include Mongo

class ScraperWorker
  include Sidekiq::Worker

  def perform
    conn = get_mongo_connection
    db = get_db_connection(conn)
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

    conn.close
  end

end
