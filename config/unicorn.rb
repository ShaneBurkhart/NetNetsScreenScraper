worker_processes 2
timeout 30

before_fork do |server, worker|
     @sidekiq_pid ||= spawn("bundle exec sidekiq -r ./lib/worker.rb -c 1")
end

