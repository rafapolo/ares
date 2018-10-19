#!/usr/bin/ruby
# extrapolo

class Ares
  require "selenium-webdriver"
  require 'rspec/retry'
  require 'net/http'
  require "json"
  require "byebug"

  ZAP_URL = "https://chat.whatsapp.com/invite"
  BROWSER = "/usr/lib/chromium-browser/chromedriver"

  def self.chromebot
    RSpec.configure do |config|
      config.verbose_retry = true
      config.default_retry_count = 3
      config.exceptions_to_retry = [Net::ReadTimeout]
    end
    Selenium::WebDriver::Chrome.driver_path = BROWSER
    Selenium::WebDriver.for :chrome
  end

  def self.update_meta
    bot = chromebot

    # login!
    puts "=> login com seu phone por QRcode antes"
    bot.get "https://web.whatsapp.com"
    wait = Selenium::WebDriver::Wait.new(timeout: 10) # seconds

    # connected?
    wait.until{
      bot.find_element(xpath: "//h1[contains(text(), 'phone connected')]")
    }

    bozaps = JSON.load(File.new "bozaps.json")
    bozaps["zaps"].each do |group|
      id = group["id"]
      puts "=> #{id}..."
      bot.get "#{ZAP_URL}/#{id}"
      wait.until{ bot.find_element(id: "action-button") }
      bot.find_element(id: "action-button").click
      sleep 4
      if (bot.find_elements(xpath: "//div[contains(text(), 'join this group because this invite link was revoked.')]").count==1)
        puts "revoked!"
        if (bot.find_elements(xpath: "//div[contains(text(), 'join this group because it is full.')]").count==1)
          puts "full!"
      else
        #todo: Follow this link to join
        # class="block__img img icon-chat
        byebug
      end
    end
    # File.open("result.json","w") do |f|
    #   f.write(bozaps.to_json)
    # end
  end
end

Ares.update_meta
