NetNetsScreenScraper
====================

Scrapes Google Finance balance sheets for all NASDAQ and NYSE stocks and runs calculations.

Unicorn + Sinatra + MongoDB + Haml + Nokogiri

Initally wrote the screen scraper with CLI ruby.  Decided to make the data public so implemented with Sinatra.

Scrapes data daily.  This is obviously overkill, but it is the least frequent Heroku will let me do.  Scrapes using a Rake task and stores in MongoDB.  When form is submitted, sends email of all of the DB entries.

