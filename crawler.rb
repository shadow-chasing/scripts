#!/usr/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)

require 'pry'
require 'nokogiri'
require 'mechanize'
require 'open-uri'
require 'awesome_print'
require 'open-uri'

#TODO actor info creates array item with nil
#     new line chars a preseverd through the date for actors?
#     tv-show shows on credits - 39 episodes, 2015-2018
#-------------------------------------------------------------------------------
# Classes
#-------------------------------------------------------------------------------
class ImdbFilm
  attr_accessor :title, :year, :description, :artwork, :poster, :genre, :duration, :rating, :tagline, :trailer

  def attributes(args={})
    @title = args[:title]
    @year = args[:year]
    @description = args[:description]
    @artwork = args[:artwork]
    @poster = args[:poster]
    @genre = args[:genre]
    @duration = args[:duration]
    @rating = args[:rating]
    @tagline = args[:tagline]
    @trailer = args[:trailer]
  end

end

class ImdbActor
  attr_accessor :name, :character, :image, :movie_title

  def attributes(args={})
    @name = args[:name]
    @character = args[:character]
    @image = args[:image]
    @movie_title = args[:movie_title]
  end
end

class ImdbDirector
  attr_accessor :dir_name, :movie_title

  def attributes(args={})
    @movie_title = args[:movie_title]
    @dir_name = args[:dir_name]
  end
end

class MovieRole
  attr_accessor :title, :actor, :year, :char

  def attributes(args={})
    @title = args[:title]
    @actor = args[:actor]
    @year = args[:year]
    @char = args[:char]
  end

end

class Crawler
  attr_accessor :cat_id

    def initialize
      # Forms
      @agent = Mechanize.new
      @initial_movie_list = ["Rocky"]
      # Data Structure Pages
      @final_page = Array.new
      # ImdbDirector Css Elements Methods
      @actor_info_zip = Array.new

      @actor_list = Array.new
      @credits = Array.new

      # Data Collections
      @movies = Array.new
      @directors = Array.new
      @actors = Array.new
    end

    #---------------------------------------------------------------------------
    # getters and setters
    #---------------------------------------------------------------------------
    # get address
    def address
      @address
    end

    # set address
    def address(address)
      @address = address
    end

    # get css_tag
    def css_tag
      @css_tag
    end

    # set css_tag
    def css_tag(css_tag)
      @css_tag = css_tag
    end

    #def cat_id
    #  @cat_id
    #end

    #def cat_id(cat_id)
    #  @cat_id = cat_id
    #end
    #---------------------------------------------------------------------------
    # Helpers
    #---------------------------------------------------------------------------
    # clean strings of \n, space and handles both ASCII and Unicode whitespace.
    def clean(arg)
      if arg.class == String && arg.present?
        result = arg.split.join(" ")
        return result.squish
      else
        return arg
      end
    end

    def titleize_string(arg)
      if arg == String
        return arg.split.map(&:titleize).join(" ")
      else
        return arg
      end
    end
    #---------------------------------------------------------------------------
    # FORM
    #---------------------------------------------------------------------------
    # Mechanize - Gets the url of a given site.
    def crawl
        page = @agent.get(@address)
        return page
    end

    # Noko - search a given page and return a document.
    def imdb_search(arg)
      doc = Nokogiri::HTML(open(arg))
      return doc
    end

    # gets the page form and submits movie title returning a page to be
    # queried by page_info method.
    def form(*args)
      begin
        site_form = crawl.form_with(:method => "GET")
        site_form.field_with(:name => "q").value = args
        page = @agent.submit(site_form)
      rescue
        puts "seach form error: no results found"
      end
    end

    # Noko - creates an array of movie titles to use as a mechanize search term.
    def create_imdb_movie_list(*arg)
      begin
        titles = imdb_search(arg[0]).css("#{arg[1]}")
        title_to_text = titles.map { |item| item.text }.map { |item| item.strip }
        @initial_movie_list = title_to_text.flatten
        return @initial_movie_list
      rescue
        puts "Error creating create_imdb_movie_list"
      end
    end

    # use the movie name contained in the @initial_movie_list array to search imdb
    # returning the imdb search results then click the first link matching the name
    def create_final_page_array(arr=@initial_movie_list)
      arr.each do |movie_name|
        begin
          results = form(movie_name)
          final_page = results.link_with(text: movie_name)
          if final_page.present?
            @final_page << results.link_with(text: movie_name).click
          end
        rescue
          next
        end
      end
    end

    #---------------------------------------------------------------------------
    # ImdbFilm CSS ELEMENTS
    #---------------------------------------------------------------------------
    # These movies are searched for with the main imdb seach function.
    # This means the css will remain the same on any given search.
    def title_of_movie(source)
      begin
        movie_title = source.css(".title_wrapper > h1").text
        if movie_title.include?("\(")
          m = movie_title.split("(")
          movie = m[0].split(" ").join(" ")
          return clean(movie)
        else
          return clean(movie_title)
        end
      rescue NoMethodError
        puts "Rescued NoMethodError: Title of movie"
      end
    end

    def year_of_movie(source)
      begin
        year = source.css(".title_wrapper > h1 > span#titleYear").text
      rescue NoMethodError
        puts "Rescued NoMethodError: Year of movie"
      end
    end

    def poster_of_movie(source)
      begin
        poster = source.at_css(".poster > a > img").attr('src')
      rescue NoMethodError
        puts "Rescued NoMethodError: Poster of movie"
      end
    end

    def duration_of_movie(source)
      begin
        movie_duration = source.css(".subtext > time").text
        duration = clean(movie_duration)
        return duration
      rescue NoMethodError
        puts "Rescued NoMethodError: Duration of movie"
      end
    end

    def genre_of_movie(source)
      begin
        movie_genre = source.css(".subtext > a")
        movie_genre.pop
        genre = movie_genre.map { |item| item.text }
        return genre
      rescue NoMethodError
        puts "Rescued NoMethodError: Genre of movie"
      end
    end

    def byline_of_movie(source)
      begin
        movie_byline = source.css(".summary_text")
        summary = clean(movie_byline.text)
        return summary
      rescue NoMethodError
        puts "Rescued NoMethodError: Byline of movie"
      end
    end

    def rating_of_movie(source)
      begin
        movie_rating = source.css(".ratingValue > strong").attr("title")
        return movie_rating.text
      rescue NoMethodError
        puts "Rescued NoMethodError: Rating of movie"
      end
    end

    def trailer_of_movie(source)
      begin
        trailer = source.css(".slate > a").attr("href").text
        id = trailer.split("?")
        trailer = "http://www.imdb.com" + id[0] + "/imdb/embed?"
      rescue
        puts "Error: unable to retrieve trailer"
      end

    end

    def art_of_movie(source)
      begin
        arts = source.css("#titleImageStrip > .mediastrip > a > img")
        images = arts.map {|item| item.attr("loadlate") }
        return images
      rescue
        puts "Error: unable to retrieve Artwork"
      end
    end


    #---------------------------------------------------------------------------
    # ActorCredits CSS ELEMENTS
    #---------------------------------------------------------------------------

    def actor_credits(source)
      source.each do |page|
        # get actors name
        initial_name = page.css("#overview-top > h1.header > .itemprop")
        name = clean(initial_name.text)

        # create an group of attributes. film row for each movie
        group = page.css(".filmo-category-section > .filmo-row")
        group.each do |row|
          # year
          row_year = row.css(".year_column")
          year = clean(row_year.text)

          # title
          movie_title = row.css("b")
          movie = clean(movie_title.text)


        # create a new instance of imdb_actor
        imdb_actor_movies_list = MovieRole.new


          imdb_actor_movies_list.attributes({
            title: movie,
            actor: name,
            char: "",
            year: year
          })

          # group all text and spit at the brace. creating to array items get the last .
          #char = movie_text.split("\)")
          #character = char[1]
          unless @credits.include?(imdb_actor_movies_list) then @credits.push(imdb_actor_movies_list) end
        end
      end
    end

      #---------------------------------------------------------------------------
    # ImdbActors CSS ELEMENTS
    #---------------------------------------------------------------------------
    # This method collects three attributes for actor and returns an array of arrays.
    # returned array - @actor_info_zip
    # [actor name, actor image, actor character]
    def actor_info(source)
      begin
        char = source.css(".cast_list > tr")
        # clear array.
        @actor_info_zip.shift(@actor_info_zip.size)
        char.each do |item|
          if item.css("td > a").any?

            names = item.css("td > a > img")
            char = item.css("td.character > a")

            # create name and image off the same item attribute.
            full_name = names.attr("title")
            image = names.attr("loadlate")

            # Validate Present
            if image.present? then img = image.text end
            if full_name.present? then name = full_name.text end
            if char.present? then character = clean(char.text) end
          end
          # push name, charater and image to movie_zip which is an array.
          @actor_info_zip.push([name, character, img])

          # populate a list of all actors.
          unless @actor_list.include?(name) then @actor_list.push(name) end
        end

        # return the actor_info_zip [actor name, charactor, image]
        return @actor_info_zip
      rescue NoMethodError
        puts "Rescued NoMethodError: ImdbActor info"
      end
    end

    #---------------------------------------------------------------------------
    # ImdbDirector CSS ELEMENTS
    #---------------------------------------------------------------------------
    # this methord retruns if single director, a string and if there a multiple
    # directors an array.
    def dir_of_movie(source)
      begin
        dir = source.at_css(".credit_summary_item > a").text
        return dir
      rescue NoMethodError
        puts "Rescued NoMethodError: Dir of movie"
      end
    end

    #---------------------------------------------------------------------------
    # DATA
    #---------------------------------------------------------------------------
    # all searches are relient on @final_page
    # Each method passes in an array of imdb pages stored as mechanize objects.
    #---------------------------------------------------------------------------
    # MOVIE: CREATE DATA STRUCTURE
    #---------------------------------------------------------------------------
    def find_movie_page_attributes

      @final_page.each do |imdb_movie_pages|
        #-----------------------------------------------------------------------
        # find attributes: prefix - attr_
        #-----------------------------------------------------------------------
        # title of movie
        attr_movie_title = title_of_movie(imdb_movie_pages)
        # image of movie
        attr_movie_poster = poster_of_movie(imdb_movie_pages)
        # byline
        attr_movie_byline = byline_of_movie(imdb_movie_pages)
        # year of movie
        attr_movie_year = year_of_movie(imdb_movie_pages)
        # genre of movie
        attr_movie_genre = genre_of_movie(imdb_movie_pages)
        # duration of movie
        attr_movie_duration = duration_of_movie(imdb_movie_pages)
        # rating
        attr_movie_rating = rating_of_movie(imdb_movie_pages)
        # trailer
        attr_movie_trailer = trailer_of_movie(imdb_movie_pages)
        # movie art
        attr_movie_art = art_of_movie(imdb_movie_pages)


        #-----------------------------------------------------------------------
        # create structure for information:
        #-----------------------------------------------------------------------
        imdb_movie = ImdbFilm.new

        imdb_movie.attributes({

          title: attr_movie_title,
          year: attr_movie_year,
          description: attr_movie_byline,
          artwork: attr_movie_art,
          poster: attr_movie_poster,
          genre: attr_movie_genre,
          duration: attr_movie_duration,
          rating: attr_movie_rating,
          tagline: attr_movie_byline,
          trailer: attr_movie_trailer,

        })

        # create a array of the movie information
        @movies.push(imdb_movie)

      end
    end

    #---------------------------------------------------------------------------
    # ACTOR: CREATE DATA STRUCTURE
    #---------------------------------------------------------------------------
    def find_actor_page_attributes
      # loops throughh each movie page. retreving attributes from each loop.
      @final_page.each do |imdb_movie_pages|

        # movie actor info - per movie - per loop.
        attr_movie_actor_info = actor_info(imdb_movie_pages)

        # title
        attr_movie_title = title_of_movie(imdb_movie_pages)

        # iterates over a 2 dimensinal array.
        attr_movie_actor_info.each do |actor_info|

        # create a new instance of imdb_actor
        imdb_actor = ImdbActor.new


          imdb_actor.attributes({
            name: actor_info[0],
            character: actor_info[1],
            image: actor_info[2],
            movie_title: attr_movie_title
          })

          @actors.push(imdb_actor)
        end

        # stop the movie titles from acumilating removing the last used movie.
        unless attr_movie_title.class == String
          attr_movie_title.shift
        end

      end
    end

    #---------------------------------------------------------------------------
    # DIRECTOR: CREATE DATA STRUCTURE
    #---------------------------------------------------------------------------
    def find_director_page_attributes


      @final_page.each do |imdb_movie_pages|

        # director of movie
        attr_movie_dir = dir_of_movie(imdb_movie_pages)
        # title of movie
        attr_movie_title = title_of_movie(imdb_movie_pages)


        imdb_director = ImdbDirector.new
        imdb_director.attributes({
          dir_name: attr_movie_dir,
          movie_title: attr_movie_title
        })

        # create a array of the director information
        @directors.push(imdb_director)

        # stop the movie titles from acumilating removing the last used movie.
        unless attr_movie_title.class == String
          attr_movie_title.shift
        end


      end

    end

    #---------------------------------------------------------------------------
    # CREDITS: CREATE DATA STRUCTURE
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    # Build Database Methods
    #---------------------------------------------------------------------------
    def build_movie_database
        #-----------------------------------------------------------------------
        # build data base - movies
        #-----------------------------------------------------------------------
        my_cat = Category.find_or_create_by(name: cat_id)

        @movies.each do |imdb_final_movie|
          # create the first movie by title, and save the information in the variable.
          if imdb_final_movie.title.present?
            my_movie = Movie.all.find_or_create_by(title: imdb_final_movie.title)
            # add category id to movie.
            if my_cat.id.present? then my_movie.update(category_id: my_cat.id) end

            # create the movie by title then update each attribute.
            if imdb_final_movie.year.present? then my_movie.update(date: imdb_final_movie.year) end
            if imdb_final_movie.description.present? then my_movie.update(byline: imdb_final_movie.description) end
            if imdb_final_movie.duration.present? then my_movie.update(duration: imdb_final_movie.duration) end
            if imdb_final_movie.rating.present? then my_movie.update(rating: imdb_final_movie.rating) end
            if imdb_final_movie.trailer.present? then my_movie.update(iframe: imdb_final_movie.trailer) end
          end

        end
    end

    def build_actor_database
      @actors.each do |actor_information|
        if actor_information.name.present? && actor_information.movie_title.present?
          # create an actors join to Movie
          my_movie = Movie.find_by(title: actor_information.movie_title)
          if my_movie.title.present? then my_movie.actors.find_or_create_by(name: actor_information.name) end

          # create an Actor
          my_actor = Actor.find_by(name: actor_information.name)
          # create Actor join through pictures and characters
          if my_actor.name.present?
            my_actor.pictures.find_or_create_by(name: actor_information.name).update(link_address: actor_information.image)
            my_actor.characters.find_or_create_by(name: actor_information.character).update(movie_name: actor_information.movie_title)
          end
        end
      end

    end

    def build_picture_database
        #-----------------------------------------------------------------------
        # build data base - pictures
        #-----------------------------------------------------------------------

        @movies.each do |imdb_final_movie|
          if imdb_final_movie.title.present?
            # create the first movie by title, and save the information in the variable.
            my_movie = Movie.all.find_by(title: imdb_final_movie.title)

            if imdb_final_movie.poster.present? then my_movie.pictures.find_or_create_by(link_address: imdb_final_movie.poster) end
              poster_image = Picture.find_by(link_address: imdb_final_movie.poster).update(page_type: "poster")

            if imdb_final_movie.artwork.class == String
                  my_movie.pictures.find_or_create_by(link_address: imdb_final_movie.artwork)
            else
                imdb_final_movie.artwork.each do |image|
                  if image.present? then my_movie.pictures.find_or_create_by(link_address: image).update(page_type: "artwork") end
                end
            end

          end
        end
    end

    def build_genre_database
        #-----------------------------------------------------------------------
        # build data base - genre
        #-----------------------------------------------------------------------

        @movies.each do |imdb_final_movie|
          # create the first movie by title, and save the information in the variable.
          my_movie = Movie.all.find_by(title: imdb_final_movie.title)
          if imdb_final_movie.genre.class == String
              my_movie.genres.find_or_create_by(name: imdb_final_movie.genre)
          else
            imdb_final_movie.genre.each do |genre_item|
              if genre_item.present? then my_movie.genres.find_or_create_by(name: genre_item) end
            end
          end
        end

    end

    def build_director_database
        #-----------------------------------------------------------------------
        # build data base - genre
        #-----------------------------------------------------------------------

        @directors.each do |director_item|

          # create the first movie by title, and save the information in the variable.
          my_movie = Movie.all.find_by(title: director_item.movie_title)

          if director_item.dir_name.class == String
            if director_item.dir_name.present? then my_movie.directors.find_or_create_by(name: director_item.dir_name) end
          else
            if director_item.dir_name.present?
              director_item.dir_name.each do |director_items|
                # create the assosiation between the movie and the director.
                if director_items.present? then my_movie.directors.find_or_create_by(name: director_items) end
              end
            end
          end

        end
    end

    #---------------------------------------------------------------------------
    #
    #---------------------------------------------------------------------------
    def find_page_atributes
      # retrive movie, actor and director page attributes from imdb pages.
      find_movie_page_attributes
      find_actor_page_attributes
      find_director_page_attributes
    end

    def build
      # build the data base.
      build_movie_database
      build_actor_database
      build_director_database
      build_genre_database
      build_picture_database
    end

    def create_actor_info_page
      # start by clearing the array. As it is used by previous search it will
      # be full, it is also the standard array returned from the method its self.
      @final_page.shift(@final_page.size)
      # pass in an array for the create final page method to iterate over.
      create_final_page_array(@actor_list)

      # pass an array of actor pages in to the css method to retrieve attributes.
      actor_credits(@final_page)
    end

    def build_credits_database
      @credits.each do |cred|
          begin
            if cred.actor.present? && cred.title.present?
              # create an Actor
              my_actor = Actor.find_by(name: cred.actor)

              if my_actor.name.present?
                # find or create movie
                my_movie = Movie.find_or_create_by(title: cred.title)
                my_movie.update(date: cred.year)
                # add actor to movie
                if my_movie.present? then my_actor.movies.find_or_create_by(title: my_movie.title) end

              end
            end
        rescue NoMethodError
          puts "Error: something went wrong with a entry?"
        end
      end
    end

  end

#-------------------------------------------------------------------------------
# IMDB movies list
#-------------------------------------------------------------------------------
# create and instance of Crawler
crawler = Crawler.new

#-------------------------------------------------------------------------------
# pass in the imdb website address used by mechanize.
imdb_crawler_address = crawler.address("https://www.imdb.com")

#-------------------------------------------------------------------------------
# pass in the list address. used to populate the array of movies.
#imdb_create_list_address = crawler.address("https://www.imdb.com/chart/boxoffice?pf_rd_m=A2FGELUUNOQJNL&pf_rd_p=d120b30e-f0de-4d19-a67b-80c0ca1f8c6e&pf_rd_r=YTS57WXX7V4FDKJJGKWY&pf_rd_s=right-6&pf_rd_t=15061&pf_rd_i=homepage&ref_=hm_cht_hd")

#-------------------------------------------------------------------------------
# create the css tag. This tag is is the tag that retrives all the movie names.
#site_css = crawler.css_tag(".lister-item-header > a")

#-------------------------------------------------------------------------------
# create
#-------------------------------------------------------------------------------
# create_final_page_array.#crawler.create_final_page_array
#-------------------------------------------------------------------------------
# find
#-------------------------------------------------------------------------------
#crawler.find_page_atributes
#-------------------------------------------------------------------------------
# build
#-------------------------------------------------------------------------------
#crawler.build
#crawler.create_actor_info_page
#crawler.build_credits_database

#-------------------------------------------------------------------------------
# Box office Imdb
#-------------------------------------------------------------------------------

# Imdb Box Office Page Adress
#imdb_create_box_office_list = crawler.address("https://www.imdb.com/chart/boxoffice?pf_rd_m=A2FGELUUNOQJNL&pf_rd_p=d120b30e-f0de-4d19-a67b-80c0ca1f8c6e&pf_rd_r=YTS57WXX7V4FDKJJGKWY&pf_rd_s=right-6&pf_rd_t=15061&pf_rd_i=homepage&ref_=hm_cht_hd")

# Imdb Box Office Css Tag
#top_box_office_css = crawler.css_tag(".titleColumn > a")

#-------------------------------------------------------------------------------
# create the movie array populated with titles
#crawler.create_imdb_movie_list(imdb_create_box_office_list, top_box_office_css)

#-------------------------------------------------------------------------------
# create
#-------------------------------------------------------------------------------
# create_final_page_array.
#crawler.create_final_page_array
#crawler.cat_id=("box office")
#-------------------------------------------------------------------------------
# find
#-------------------------------------------------------------------------------
#crawler.find_page_atributes
#-------------------------------------------------------------------------------
# build
#-------------------------------------------------------------------------------
#crawler.build
#crawler.create_actor_info_page
#crawler.build_credits_database

#-------------------------------------------------------------------------------
# Latest Trailers Imdb
#-------------------------------------------------------------------------------
# Imdb Box Office Page Adress
imdb_create_new_trailers_list = crawler.address("https://www.imdb.com/trailers?pf_rd_m=A2FGELUUNOQJNL&pf_rd_p=09c064e2-1b0c-4636-a3bb-8ec51b30dfb6&pf_rd_r=YTS57WXX7V4FDKJJGKWY&pf_rd_s=hero&pf_rd_t=15061&pf_rd_i=homepage&ref_=hm_hp_sm")

# Imdb Box Office Css Tag
new_trailers_css = crawler.css_tag(".trailer-caption > a")
#-------------------------------------------------------------------------------
# create the movie array populated with titles
crawler.create_imdb_movie_list(imdb_create_new_trailers_list, new_trailers_css)
#-------------------------------------------------------------------------------
# create
#-------------------------------------------------------------------------------
# create_final_page_array.
crawler.create_final_page_array
crawler.cat_id=("latest")
#-------------------------------------------------------------------------------
# find
#-------------------------------------------------------------------------------
crawler.find_page_atributes
#-------------------------------------------------------------------------------
# build
#-------------------------------------------------------------------------------
crawler.build
#-------------------------------------------------------------------------------
