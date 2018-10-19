#!/usr/bin/ruby
# extrapolo

class Ares
  require "selenium-webdriver"
  require 'rspec/retry'
  require 'net/http'
  require "json"
  require "yaml"
  require "byebug"

  ZAP_URL = "https://chat.whatsapp.com/invite"
  BROWSER = "/usr/lib/chromium-browser/chromedriver"
  TIMEOUT = 40 # seconds

  def self.chromebot
    RSpec.configure do |config|
      config.verbose_retry = true
      config.default_retry_count = 3
      config.exceptions_to_retry = [Net::ReadTimeout]
    end
    Selenium::WebDriver::Chrome.driver_path = BROWSER
    Selenium::WebDriver.for :chrome,
      options: Selenium::WebDriver::Chrome::Options.new(args: %w[--user-data-dir=./cache])
  end

  def self.update_meta
    bot = chromebot

    bozaps = JSON.load(File.new "bozaps.json")
    bozaps["invites"].each do |group|
      id = group["id"]
      # puts "=> #{id}..."
      bot.get "#{ZAP_URL}/#{id}"
      wait = Selenium::WebDriver::Wait.new(timeout: TIMEOUT)
      wait.until{ bot.find_element(id: "action-button") }
      bot.find_element(id: "action-button").click
      wait.until{ bot.find_elements(xpath: "//div[contains(text(), 'join')]").count==1 || bot.find_elements(xpath: "//div[contains(text(), 'OK')]").count==1 || bot.find_elements(xpath: "//span[contains(text(), 'Created by')]").count == 1}

      group["status"] = "revoked" if (bot.find_elements(xpath: "//div[contains(text(), 'join this group because this invite link was revoked.')]").count==1)
      group["status"] = "full" if (bot.find_elements(xpath: "//div[contains(text(), 'join this group because it is full.')]").count==1)

      # click Ok if exists
      ok_btn = bot.find_elements(xpath: "//div[contains(text(), 'OK')]")
      ok_btn.first.click if ok_btn.count==1

      el = bot.find_elements(xpath: "//span[contains(text(), 'Created by')]")
      if (el.count==1) #exists!
        group_meta = el.first.find_element(xpath: "../..").text.split("\n")
        group["status"] = "active"
        group["title"] = group_meta[0]
        group["created_by"] = group_meta[1].gsub("Created by ", "")
        group["subtitle"] = group_meta[2] || ""
        # icon = https://web.whatsapp.com/invite/icon/#{id}
        #todo: follow to join
      end
      puts group

    end

    File.open("results/meta.json","w") do |f|
      f.write(JSON.pretty_generate(bozaps))
    end
  end
end

Ares.update_meta
