#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def members_data(url)
  noko = noko_for(url)
  noko.css('.table-responsive.table-striped tr a[href*="search"]/@href').map(&:text).uniq.map do |link|
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
    data
  end
end


data = members_data('http://www.congress.gov.ph/members/')
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i(id term), data)
