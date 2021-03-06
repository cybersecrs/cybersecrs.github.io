#!/usr/bin/env ruby

require 'csv'
require 'json'
require 'net/http'
require 'nokogiri'


# Get CZK for USD

module CZK

  URL = "https://www.cnb.cz/en/"

  def self.to_usd!
    open_page(URL)
    scrap!
    return @rate
  end

  def self.open_page(url)
    html  = Net::HTTP.get URI(url)
    @page = Nokogiri::HTML(html)
    @data = @page.search('div.courses__label')
  end

  def self.scrap!
    @data.each { |x| @rate = x.search('> span').text  rescue @rate = 'unknown' }
  end

end


# Get History Crypto Data

module ColorChain

 class Historic

  TIME  = 30                            # seconds to sleep between faild requests
  COINS = %w[BTC ETH LTC XMR].freeze    # define coins to scrap

  def initialize(currency)
    @table = currency.downcase  + '_historic_data.csv'
    @count = 1; @coins = '';
    @coins_array = []; time = Time.new;
    @time = time.strftime("%d/%m/%Y")
    @coins_array << @time.to_s
    @currency = currency
    make_request_for(api_url)
  end

  private

  def make_request_for(url)
    page = Net::HTTP.get URI(url)
    data = JSON.parse(page)
    process_data(data) unless data[:response]
  end

  def api_url(coins=COINS)
    coins.collect { |coin| @coins << "fsyms=#{coin}&" }
    url = "https://min-api.cryptocompare.com/data/pricemultifull?#{@coins}tsyms=#{@currency}"
    return url
  end

  def process_data(data)
    @czk = CZK.to_usd!  # get czk rate
    # use next line only with terminal output
    print_terminal_header
    COINS.each do |coin|
      @coins_array << price = data["RAW"][coin][@currency]["PRICE"].round(5)
      # remove line for no-terminal-output
      puts "[#{coin}]: #{price}"
      get_all_coin_info(data, coin, @currency)
    end
    @coins_array << @czk
    save_csv_output!
  rescue
    puts "[#{@count}] - Request Faild!"
    try_again!
  end

  def try_again!(sec=TIME)
    unless @count >= 3
      sleep(sec)
      @count += 1
      process_data(@data)
    else
      puts "Request faild #{@count} times."
    end
  end

  def get_all_coin_info(data, coin, currency)
    @symbol = data["RAW"][coin][currency]["FROMSYMBOL"]
    @price  = data["RAW"][coin][currency]["PRICE"].round(2)
    @chg    = data["RAW"][coin][currency]["CHANGE24HOUR"].round(3)
    @chgpct = data["RAW"][coin][currency]["CHANGEPCT24HOUR"].round(3)
    @high   = data["RAW"][coin][currency]["HIGH24HOUR"].round(2)
    @low    = data["RAW"][coin][currency]["LOW24HOUR"].round(2)

    CSV.open("#{@symbol}.csv", "w") { |header| header << %w[PRICE 24h-HIGH 24h-LOW 24h-CHANGE 24h-%-CHANGE] }
    CSV.open("#{@symbol}.csv", 'ab') { |row| row << [ @price, @high, @low, @chg, "#{@chgpct}%" ] }
  end

  def print_terminal_header
    puts "\n[#{@currency}] coversion rate:"
    30.times { print '='}
    puts ''
  end

  def save_csv_output!
    create_csv_headers unless File.exist?(@table)
    insert_after_header( @table, 1 ) do |row|
      row.puts Array(@coins_array).join(",")
    end
  end

  def create_csv_headers
    header_array = %w[DATE]
    COINS.each { |coin| header_array << coin }
    header_array << 'CZK'
    CSV.open(@table, "w" ) { |header| header << header_array }
  end

  def insert_after_header file, line_no
    tmp_fn = "#{file}.tmp"
    File.open( tmp_fn, 'w' ) do |outf|
      line_ct = 0
      IO.foreach(file) do |line|
        outf.print line
        yield(outf) if line_no == (line_ct += 1)
      end
    end
    File.rename tmp_fn, file
  end


 end    # end of historic::class



# Get data for main page

 class Data

  TIME  = 30                            # seconds to sleep between faild requests
  COINS = %w[BTC ETH LTC XMR].freeze    # define coins to scrap

  def initialize(currency)
    @table = currency.downcase  + '_data.csv'
    @count = 1; @coins = ''; @coins_array = []
    @currency = currency
    make_request_for(api_url)
  end

  private

  def make_request_for(url)
    page = Net::HTTP.get URI(url)
    data = JSON.parse(page)
    process_data(data) unless data[:response]
  end

  def api_url(coins=COINS)
    coins.collect { |coin| @coins << "fsyms=#{coin}&" }
    url = "https://min-api.cryptocompare.com/data/pricemultifull?#{@coins}tsyms=#{@currency}"
    return url
  end

  def process_data(data)
    # use next line only with terminal output
    print_terminal_header
    COINS.each do |coin|
      @coins_array << price = data["RAW"][coin][@currency]["PRICE"].round(5)
      # remove line for no-terminal-output
      puts "[#{coin}]: #{price}"
    end

    save_csv_output!
  rescue
    puts "[#{@count}] - Request Faild!"
    try_again!
  end

  def try_again!(sec=TIME)
    unless @count >= 3
      sleep(sec)
      @count += 1
      process_data(@data)
    else
      puts "Request faild #{@count} times."
    end
  end

  def print_terminal_header
    puts "\n[#{@currency}] coversion rate:"
    30.times { print '='}
    puts ''
  end

  def save_csv_output!
    create_csv_headers
    CSV.open(@table, 'ab') { |column| column << @coins_array }
  end


  def create_csv_headers
    header_array = []
    COINS.each { |coin| header_array << coin }
    CSV.open(@table, "w" ) { |header| header << header_array }
  end

 end

end
#=========================================================> end of class/module


  puts "\nCollecting data for main page..."
    ColorChain::Data.new('USD')

  puts "\nCollecting history data..."
    ColorChain::Historic.new('USD')


