#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'csv'
require 'scraperwiki'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('.table-responsive.table-striped tr a[href*="search"]/@href').map(&:text).uniq.each do |link|
    mp_url = URI.join url, link
    mp = noko_for(mp_url)

    data = {
      id:           mp_url.to_s[/search.php\?id=(.*)/, 1],
      name:         mp.css('.text-primary').text.gsub('Hon. ', '').strip,
      constituency: mp.xpath('.//text()[.="District Representative"]//following-sibling::text()').text.strip,
      party:        mp.css('h4 small:starts-with("Party List")').text.gsub('Party List -', '').strip,
      image:        mp.css('img[src*="images/17th"]/@src').text,
      term:         17,
      source:       mp_url.to_s,
    }
    data[:image] = URI.join(mp_url, data[:image]).to_s unless data[:image].to_s.empty?

    ScraperWiki.save_sqlite(%i(id term), data)
  end
end

scrape_list('http://www.congress.gov.ph/members/')
