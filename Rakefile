require "./lib/stock"
require "./lib/db"
require "net/smtp"

task default: [:scrape, :email_stocks]

task :scrape do
  NetNets::DB.connection

  NetNets::Stock.clear

  NetNets::Stock.tickers.each do |ticker|
    s = NetNets::Stock.new(ticker)
    if s.calculate
      s.save
    end
  end

  puts
  puts "Missed Attributes:"
  puts NetNets::Stock.class_variable_get(:@@missed_attrs)

  NetNets::DB.close
end

task :email_stocks do
  gmail_email = "shaneburkhart@gmail.com"
  gmail_password = ENV["GMAIL_PASS"]

  if gmail_password.nil?
    puts "No Gmail password provided. GMAIL_PASS."
    next
  end

  smtp = Net::SMTP.new("smtp.gmail.com", 587)
  smtp.enable_starttls

  stock_list = NetNets::Stock.all.map { |s| "#{s[1]}: #{s[s.count - 1]}%" }.join("\n")
  puts stock_list

  msg = [
    "From: Stock Master <#{gmail_email}>",
    "To: Shane Burkhart <#{gmail_email}>",
    "Subject: Stocks",
    "",
    stock_list
  ].join("\n")

  smtp.start('gmail.com', gmail_email, gmail_password, :login) do |smtp|
      smtp.send_message msg, gmail_email, gmail_email
  end
end

task :run do
  sh "unicorn -p 3000 -c ./config/unicorn.rb"
end

task :run_prod do
  sh "unicorn -p 80 -c ./config/unicorn.rb"
end
