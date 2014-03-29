require "nokogiri"
require "open-uri"


module NetNets

  @@missed_keys = {}

  def self.tickers
    file = File.new("tickers.dat", "r").read.split(/\n/)
  end

  def self.add_missed_key(label)
    @@missed_keys[label] = true
  end

  def self.missed_keys
    @@missed_keys
  end

  def self.quart_bal_row_sel
    "##{QUARTER_BALANCE_DIV_ID} table tr"
  end

  def self.cur_price_sel
    CURRENT_PRICE_SELECTOR
  end

  def self.liability_mult
    LIABILITY_MULTIPLIERS
  end

  def self.asset_mult
    ASSET_MULTIPLIERS
  end

  def self.outstanding_label
    OUTSTANDING_SHARES_LABEL
  end

  class Stock
    @ticker = ""
    @asset = 0.0
    @liabilities = 0.0
    @outstanding_shares = 0.0
    @price = 0.0

    def initialize(ticker)
      @ticker = ticker
    end

    def calculate
      puts "Calculating: #{@ticker}..."
      @assets = 0.0
      @liabilities = 0.0
      @outstanding_shares = 0.0
      @price = 0.0

      p_doc = Nokogiri::HTML(open(url))
      price_cell = p_doc.css(NetNets.cur_price_sel).first
      if price_cell
        price_data = price_cell.content
        @price = price_data.to_f if(price_data =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/)
      end

      doc = Nokogiri::HTML(open(bal_url))

      doc.css(NetNets.quart_bal_row_sel).each do |row|
        cols = row.css("td")

        first = cols.shift
        label = first.content.strip if first

        data_cell = cols.shift
        if(data_cell)
          data = data_cell.content
          data = data.gsub(/\,/, "").strip

           NetNets.add_missed_key(label) if(NetNets.asset_mult[label].nil? && NetNets.liability_mult[label].nil?)

          if(data =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/)
            v = data.to_f

            a_mult = NetNets.asset_mult[label] || 0.0
            @assets += v * a_mult

            l_mult = NetNets.liability_mult[label] || 0.0
            @liabilities += v * l_mult

            @outstanding_shares = v || 0.0 if(label == NetNets.outstanding_label)
          end

        end
      end

    end

    def net_liquid_capital
      @assets - @liabilities
    end

    def net_liquid_capital_per_share
      begin
        return net_liquid_capital / @outstanding_shares
      rescue
        puts "Net Liquid Capital Per Share Error"
        return -1
      end
    end

    def price_to_liquid_ratio
      begin
        return (@price / net_liquid_capital_per_share * 10000).round / 100.0
      rescue
        puts "Price to Liquid Ratio Error"
        return -1
      end
    end

    def to_s
      [
        "Ticker:\t\t\t\t#{@ticker}",
        "URL:\t\t\t\t#{url}",
        "Current Price:\t\t\t#{@price}",
        "Outstanding Shares:\t\t#{@outstanding_shares}",
        "Liabilities:\t\t\t#{@liabilities}",
        "Tangible Assets:\t\t#{@assets}",
        "Net Liquid Capital:\t\t#{net_liquid_capital}",
        "Net Liquid Capital / Share:\t#{net_liquid_capital_per_share}",
        "Price to Liquid Ratio:\t\t%#{price_to_liquid_ratio}"
      ].join("\n")
    end

    private
      def bal_url
        "https://www.google.com/finance?q=#{@ticker}&fstype=ii"
      end

      def url
        "https://www.google.com/finance?q=#{@ticker}"
      end
  end

  QUARTER_BALANCE_DIV_ID = "balinterimdiv"
  CURRENT_PRICE_SELECTOR= "#price-panel > div > span.pr > span"

  ASSET_MULTIPLIERS = {
    "Cash & Equivalents" => 1.0, #Cash
    "Short Term Investments" => 0.75, #In the cash section
    "Accounts Receivable - Trade, Net" => 0.75,
    "Receivables - Other" => 0.75,
    "Prepaid Expenses" => 0.5,
    "Other Current Assets, Total" => 0.5,
    "Property/Plant/Equipment, Total - Gross" => 0.5,
    "Accumulated Depreciation, Total" => 0.5, #To go against the property and plant
    "Long Term Investments" => 0.5,
    "Other Long Term Assets" => 0.5,
    "Cash and Short Term Investments" => 0.0 #Total line
  }

  OUTSTANDING_SHARES_LABEL = "Total Common Shares Outstanding"

  LIABILITY_MULTIPLIERS = {
    "Total Liabilities" => 1.0
  }

end

if __FILE__ == $0
  puts

  date = DateTime.now.to_s.gsub(" ", "-")
  file = File.open("output-#{date}.dat", "w")

  tickers = NetNets.tickers
  num = tickers.count

  tickers[3000..(tickers.length-1)].each_with_index do |ticker, i|
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

  puts
  puts "======== Missed Keys ========="
  NetNets.missed_keys.keys.each{ |key| puts key }
end
