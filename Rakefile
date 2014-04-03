require "./lib/netnets"
require "./lib/connection"

task default: [:run]

task :run do
  sh "unicorn -p 3000 -c ./config/unicorn.rb"
end

task :scrape do
  require "./lib/worker.rb"
  ScraperWorker.perform_async
end

task :test do
  conn = get_mongo_connection
  db = get_db_connection(conn)
  collection = db.collection "test"
  puts "Worked"
  conn.close
end

task :worker_test do
  require "./lib/worker"
  ScraperWorker.perform_async
end

task :dyno_ping do
  require "net/http"
  if ENV['PING_URL']
    puts "Running upkeep ping!"
    uri = URI(ENV['PING_URL'])
    Net::HTTP.get_response(uri)
  else
    puts "No PING_URL found..."
  end
end
