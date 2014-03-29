require "./netnets"

if __FILE__ == $0
  puts

  date = DateTime.now.to_s.gsub(" ", "-")
  file = File.open("output-#{date}.dat", "w")

  tickers = NetNets.tickers
  num = tickers.count

  tickers.each_with_index do |ticker, i|
    puts "#{i+1} of #{num}"
    begin
      stock = NetNets::Stock.new ticker
      stock.calculate
      if stock.price_to_liquid_ratio > 0 && stock.price_to_liquid_ratio < 75
        file.write(stock.to_s)
        file.write("\n")
      end
    rescue
      puts "Probably a 500 error"
    end
  end

  file.close unless file == nil

  #puts
  #puts "======== Missed Keys ========="
  #NetNets.missed_keys.keys.each{ |key| puts key }
end
