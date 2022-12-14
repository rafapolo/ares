#!/usr/bin/ruby
# extrapolo

require "selenium-webdriver"
require "rspec/retry"
require "net/http"
require "json"
require "yaml"
require "byebug"

class Ares


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

  def self.parse_history
    json = []
    history = []
    Dir["data/history/*.txt"].each do |file|
      hist = File.readlines(file)
      data = {}
      matched_admin = false
      hist.each do |line|
        # match "who" criou o grupo
        unless matched_admin
          meta = line.scan(/(\d{2}\/\d{2}\/\d{2} \d{2}:\d{2}) - (.*?) criou o grupo (.*)/)
          if meta.size==1 && meta.first.count==3 #match!
            actual = meta.first
            json << {grupo: actual[2].gsub("\"", ""), created_by: actual[1], file: file}
            matched_admin = true
          end
        end

        # parse lines
        meta = line.scan(/(\d{2}\/\d{2}\/\d{2} \d{2}:\d{2}) - (.*?:) (.*)/)
        if meta.size==1 && meta.first.count==3 #match!
          # close/open msg
          if data.keys.index "who"
            history << data
            data = {}
          end
          actual = meta.first
          data["when"] = actual[0]
          data["who"] = actual[1].gsub(":", "")
          data["what"] = actual[2]
        else
          # break-line msgs parts
          unless line.scan(/(\d{2}\/\d{2}\/\d{2} \d{2}:\d{2}) (.+)/)
            if data.keys.index "who"
              if data.keys.index "what"
                data["what"] = data["what"] +"\n"+ line
              else
                data["what"] = line
              end
            end
          end
        end
      end
      matched_admin = false
      json.first["history"] = history

      # save
      filename = file.split("/").last
      File.open("data/history/meta_"+filename+".json","w") do |f|
        f.write(JSON.pretty_generate(json))
      end
    end
    json
  end

  def self.update_meta
    bot = chromebot

    bozaps = JSON.load(File.new "data/meta_hashes.json")
    bozaps["invites"].each do |group|

      next if group["status"] # already scrapped?

      id = group["id"]
      puts "=> #{id}..."
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

      #todo: Retry now .click

      el = bot.find_elements(xpath: "//span[contains(text(), 'Created by')]")
      if (el.count==1) #exists
        group_meta = el.first.find_element(xpath: "../..").text.split("\n")
        group["status"] = "active"
        group["title"] = group_meta[0]
        group["created_by"] = group_meta[1].gsub("Created by ", "")
        group["subtitle"] = group_meta[2] || ""
        # icon = https://web.whatsapp.com/invite/icon/#{id}
        #todo: follow to join
      end
      puts group

      group["status"] = "invalid" unless group["status"]
      File.open("data/meta_hashes.json","w") do |f|
        f.write(JSON.pretty_generate(bozaps))
      end
    end
  end
end


Ares.parse_history if ARGV[0] == "history"
Ares.update_meta if ARGV[0] == "meta"
