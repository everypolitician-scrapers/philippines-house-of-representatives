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
  noko.css('section#comments table tr a[href*="search"]/@href').map(&:text).uniq.each do |link|
    mp_url = URI.join url, link
    mp = noko_for(mp_url)
    box = mp.css('section#main')

    data = { 
      id: mp_url.to_s[/search.php\?id=(.*)/, 1],
      name: box.css('h2').text.gsub('Hon. ', '').strip,
      constituency: box.xpath('.//h3[contains(., "District Representative")]/following-sibling::h3[1]').text,
      party: box.xpath('.//h3[contains(., "Party List")]').text.gsub(/Party List\s*-\s*/, ''),
      image: box.css('img[src*="images/16th"]/@src').text,
      term: 16,
      source: mp_url.to_s,
    }
    data[:image] = URI.join(mp_url, data[:image]).to_s unless data[:image].to_s.empty?
    # puts data
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

term = {
  id: '16',
  name: '16th Congress of the Philippines',
  start_date: '2013-06-30',
  end_date: '2016-06-30',
  source: 'https://en.wikipedia.org/wiki/16th_Congress_of_the_Philippines',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('http://www.congress.gov.ph/members/')
