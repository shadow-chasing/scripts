#!/usr/bin/env ruby

require File.expand_path('../../config/environment', __FILE__)

require 'pry'
require 'nokogiri'
require 'mechanize'
require 'open-uri'
require 'awesome_print'
require 'open-uri'


class Crawler
    def initialize(address)
        @address = address
        @site_name = "https://www.imdb.com"
        # need to set this
        @agent = Mechanize.new
        @arr = []
        @elements = []
        @Movie = Struct.new(:title, :year, :actor, :poster, :dir, :genre, :duration, :disc, :rating)
        @Movie_Actor = Struct.new(:actor, :image)
    end

    # Gets the url of a given site.
    def crawl
        page = @agent.get("#{@address}")
        return page
    end

    # noko search a given page and return a document.
    def noko_search(arg)
      doc = Nokogiri::HTML(open("#{arg}"))
      return doc
    end

    def forms(*args)
        site_form = crawl.form_with(:method => "GET")
        site_form.field_with(:name => "q").value = args
        page = @agent.submit(site_form)
    end

    # creates an array of movie titles to use as a mechanize search term.
    def create_imdb_movie_list(*arg)
      titles = noko_search(arg[0]).css("#{arg[1]}")
      title = titles.map { |item| item.text }
      return @arr = title.flatten
    end

    # clean strings of \n and space
    def clean(arg)
      if arg.class == String
          arg.chomp && arg.lstrip! && arg.rstrip!
      end
    end

    #----------------------------------------------------------------
    # Movie
    #----------------------------------------------------------------

    def year_of_movie(source)
      begin
        year = source.css(".title_wrapper > h1 > span#titleYear").text
      rescue NoMethodError
        puts "Rescued NoMethodError: Year of Movie"
      end
    end

    def poster_of_movie(source)
      begin
        poster = source.at_css(".poster > a > img").attr('src')
      rescue NoMethodError
        puts "Rescued NoMethodError: Poster of Movie"
      end
    end

    def dir_of_movie(source)
      begin
        dir = source.at_css(".credit_summary_item > a").text
      rescue NoMethodError
        puts "Rescued NoMethodError: Dir of Movie"
      end
    end

    def title_of_movie(source)
      begin
        movie_title = source.css(".title_wrapper > h1").text
        if movie_title.include?("\(")
          m = movie_title.split("(")
          movie = m[0].split(" ").join(" ")
          return movie
        else
          return movie_title
        end
      rescue NoMethodError
        puts "Rescued NoMethodError: Title of Movie"
      end
    end

    def duration_of_movie(source)
      begin
        movie_duration = source.css(".subtext > time").text
        duration = clean(movie_duration)
        return duration
      rescue NoMethodError
        puts "Rescued NoMethodError: Duration of Movie"
      end
    end

    def genre_of_movie(source)
      begin
        movie_genre = source.css(".subtext > a")
        movie_genre.pop
        genre = movie_genre.map { |item| item.text }
        return genre
      rescue NoMethodError
        puts "Rescued NoMethodError: Genre of Movie"
      end
    end

    def byline_of_movie(source)
      begin
        movie_byline = source.css(".summary_text")
        summary = clean(movie_byline.text)
        return summary
      rescue NoMethodError
        puts "Rescued NoMethodError: Byline of Movie"
      end
    end

    def rating_of_movie(source)
      begin
        movie_rating = source.css(".ratingValue > strong").attr("title")
        return movie_rating.text
      rescue NoMethodError
        puts "Rescued NoMethodError: Rating of Movie"
      end
    end
    #----------------------------------------------------------------
    # Actors
    #----------------------------------------------------------------

    def actor_of_movie(source)
      begin
        a = source.css("td > a > img")
        actors = a.map { |item| item.attr("title")  }
        return actors
      rescue NoMethodError
        puts "Rescued NoMethodError: Actor of Movie"
      end
    end

    #----------------------------------------------------------------
    def page_info
      @arr.each do |movie_name|
        puts "look ma no hands"
        results = forms(movie_name)
        final_page = results.link_with(text: movie_name)

        puts "pre page present"
        if final_page.present?
        puts "past page present"
          final_page = results.link_with(text: movie_name).click
          # title of movie
          title = title_of_movie(final_page)

          unless title.blank?
            puts "passed title blank " + "#{@arr[0][0]}"

            # actors of movie
            actor = actor_of_movie(final_page)
            # year of movie
            year = year_of_movie(final_page)
            # image of movie
            poster = poster_of_movie(final_page)
            # director of movie
            dir = dir_of_movie(final_page)
            # director of movie
            genre = genre_of_movie(final_page)
            # create struct
            duration = duration_of_movie(final_page)
            # byline
            byline = byline_of_movie(final_page)
            # rating
            rating = rating_of_movie(final_page)

            puts "i got out alive"

            film = @Movie.new(title, year, actor, poster, dir, genre, duration, byline, rating)
            ap "#{film}" + " count is " + @elements.count.to_s
            # populate array
            @elements << film
            ap "new count is " + @elements.count.to_s
          end
        end
        puts "<-----skipped the shiznit"
      end
    end

    def results
      puts "enterd the twighlight zone"
      while @elements.length > 0
        db_count = Movie.all.count
        puts "there are " + "#{@elements.count}" + " movies, the db has " + "#{db_count}" + " movies"
        @elements.each do |name|
          my_movie = Movie.find_or_create_by(title: name.title)
          binding.pry
          my_movie.update(date: name.year)
          my_movie.update(image: name.poster)
          my_movie.update(duration: name.duration)
          my_movie.update(byline: name.disc)
          my_movie.update(rating: name.rating)
          db_count = Movie.all.count

          puts "there are now " + "#{db_count}" + " movies"
          # movie actors join
          if name[2].class == String
            my_movie.actors.find_or_create_by(name: name[2])
          else
            binding.pry
            name[2].each do |actors_name|
              my_movie.actors.find_or_create_by(name: actors_name)
            end
          end

          # movie directors join
          if name[4].class == String
            my_movie.directors.find_or_create_by(name: name[4])
          else
            binding.pry
            name[4].each do |director_name|
              my_movie.directors.find_or_create_by(name: director_name)
            end
          end

          # movie genre join
          if name[5].class == String
            my_movie.genres.find_or_create_by(name: name[5])
          else
            binding.pry
            name[5].each do |genre_name|
              my_movie.genres.find_or_create_by(name: genre_name)
            end
          end


          # remove last elemnt of the array.
          @elements.shift
          puts "there are now #{@elements.count} movies in the arry "
        end

      end
    end

end

# get the main addes and search box
crawler = Crawler.new("https://www.imdb.com")
crawler.create_imdb_movie_list("https://www.imdb.com/list/ls000415188/", ".lister-item-header > a")
crawler.page_info
crawler.results
