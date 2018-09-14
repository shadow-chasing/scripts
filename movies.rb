#!/usr/bin/env ruby

require File.expand_path('../../config/environment', __FILE__)

require 'pry'


require 'nokogiri'
require 'open-uri'

top = []

# Fetch and parse HTML document
doc = Nokogiri::HTML(open('https://www.imdb.com/chart/top'))

# page
titles = doc.css(".titleColumn > a")
# titles
titles.each do |title|
  top << title.text
end

def create_table(arg)
  arg.each do |name_actor|
      Movie.find_or_create_by(title: name_actor)
  end
end

def remove_table(arg)
  arg.each do |name_actor|
      Movie.find_or_create_by(title: name_actor).destroy
  end
end

create_table(top)
