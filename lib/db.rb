require "sqlite3"

SQLITE_LOCATION = "#{File.dirname(__FILE__).gsub(/lib\/?/, "")}db/mydb.sqlite3"

module NetNets
  class DB

    def self.connection
      if !@db
        puts "Connecting to #{SQLITE_LOCATION}"
        @db = SQLite3::Database.new SQLITE_LOCATION

        if !table_exists?
          create_table
        end
      end
      return @db
    end

    def self.close
      if @db
        @db.close
        @db = nil
      end
    end

    TABLE_EXISTS_QUERY = "
      SELECT name
      FROM sqlite_master
      WHERE type='table'
      AND name='stocks';
    "

    CREATE_TABLE_QUERY = "
      CREATE TABLE stocks (
        id INTEGER PRIMARY KEY,
        ticker TEXT NOT NULL,
        current_price TEXT NOT NULL,
        outstanding_shares TEXT NOT NULL,
        liabilities TEXT NOT NULL,
        tangible_assets TEXT NOT NULL,
        net_liquid_capital TEXT NOT NULL,
        net_liquid_capital_per_share TEXT NOT NULL,
        price_to_liquid_ratio TEXT NOT NULL
      );
    "

    private

      def self.table_exists?
        connection.execute(TABLE_EXISTS_QUERY).count != 0
      end

      def self.create_table
        puts "Creating table stocks..."
        connection.execute(CREATE_TABLE_QUERY)
      end

  end
end
