require "./lib/netnets"
require "./lib/connection"

task default: [:run]

task :run do
  sh "unicorn -p 3000 -c ./config/unicorn.rb"
end

task :scrape do
  require "./lib/worker.rb"

  Sidekiq.configure_server do |config|
      config.redis = { :url => ENV["REDISTOGO_URL"] }
  end

  Sidekiq.configure_client do |config|
    config.redis = { :url => ENV["REDISTOGO_URL"] }
  end

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
