require "nokogiri"
require "open-uri"
require "json"
require "./lib/db"


module NetNets
  class Stock
    @@missed_attrs = []

    def self.tickers
      file = File.new(File.join(File.dirname(__FILE__), "tickers.dat"), "r").read.split(/\n/)
    end

    def self.all
      query = "
        SELECT *
        FROM stocks s
      "
      NetNets::DB.connection.execute(query)
    end

    def self.clear
      query = "DELETE FROM stocks"
      NetNets::DB.connection.execute(query)
    end

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

      begin
        p_doc = Nokogiri::HTML(open(url))
      rescue
        return false
      end

      price_cell = p_doc.css(CURRENT_PRICE_SELECTOR).first
      if price_cell
        price_data = price_cell.content
        @price = price_data.to_f if(price_data =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/)
      end

      begin
        doc = Nokogiri::HTML(open(bal_url))
      rescue
        return false
      end

      doc.css("#{QUARTER_BALANCE_DIV_ID} tr").each do |row|
        # Check if in USD.  If not, skip.
        header_cells = row.css("th")
        if header_cells.count > 0
          begin
            if !header_cells.first.content.include?("USD")
              puts "Not in USD."
              return false
            end
          rescue
            puts "Error when checking if in USD."
            return false
          end
        end

        cols = row.css("td")

        first = cols.shift
        label = first.content.strip if first

        data_cell = cols.shift

        if data_cell
          data = data_cell.content
          data = data.gsub(/\,/, "").strip

          if data =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/
            v = data.to_f

            if ASSET_MULTIPLIERS[label].nil?
              if @@missed_attrs.find_index(label).nil?
                @@missed_attrs << label
              end
            end

            a_mult = ASSET_MULTIPLIERS[label] || 0.0
            @assets += v * a_mult

            l_mult = LIABILITY_MULTIPLIERS[label] || 0.0
            @liabilities += v * l_mult

            if label == OUTSTANDING_SHARES_LABEL
              @outstanding_shares = v || 0.0
            end
          end

        end
      end

      return true
    end

    def net_liquid_capital
      begin
        num = @assets - @liabilities
        if num.nan?
          return -1
        else
          return num
        end
      rescue
        return -1
      end
    end

    def net_liquid_capital_per_share
      begin
        num = net_liquid_capital / @outstanding_shares
        if num.nan?
          return -1
        else
          return num
        end
      rescue
        puts "Net Liquid Capital Per Share Error"
        return -1
      end
    end

    def price_to_liquid_ratio
      begin
        num = (@price / net_liquid_capital_per_share * 10000).round / 100.0
        if num.nan?
          return -1
        else
          return num
        end
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

    def to_json
      {
        ticker: @ticker || "",
        current_price: @price || 0,
        outstanding_shares: @outstanding_shares || 0,
        liabilities: @liabilities || 0,
        tangible_assets: @assets || 0,
        net_liquid_capital: net_liquid_capital || 0,
        net_liquid_capital_per_share: net_liquid_capital_per_share || 0,
        price_to_liquid_ratio: price_to_liquid_ratio || 0
      }
    end

    def save
      json = to_json
      ptlr = json[:price_to_liquid_ratio]
      puts "Price To Liquid: #{ptlr}"
      if ptlr <= 0 || ptlr >= 200
        return false
      end

      query = "
        INSERT INTO stocks (
          ticker,
          current_price,
          outstanding_shares,
          liabilities,
          tangible_assets,
          net_liquid_capital,
          net_liquid_capital_per_share,
          price_to_liquid_ratio
        ) VALUES (
          ?, ?, ?, ?, ?, ?, ?, ?
        );
      "
      NetNets::DB.connection.execute(query, json.values)
    end

    private
      def bal_url
        "https://www.google.com/finance?q=#{@ticker}&fstype=ii"
      end

      def url
        "https://www.google.com/finance?q=#{@ticker}"
      end
  end

  QUARTER_BALANCE_DIV_ID = "#balinterimdiv"
  CURRENT_PRICE_SELECTOR= "#price-panel > div > span.pr > span"

  ASSET_MULTIPLIERS = {
    "Cash & Equivalents" => 1.0, #Cash
    "Short Term Investments" => 0.75, #In the cash section
    "Accounts Receivable - Trade, Net" => 0.75,
    "Receivables - Other" => 0.75,
    "Total Inventory" => 0.5,
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

