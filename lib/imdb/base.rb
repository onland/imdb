module Imdb
  # Represents something on IMDB.com
  class Base
    attr_accessor :id, :url, :title, :year, :poster_thumbnail, :related_person, :related_person_role

    # Initialize a new IMDB movie object with it's IMDB id (as a String)
    #
    #   movie = Imdb::Movie.new("0095016")
    #
    # Imdb::Movie objects are lazy loading, meaning that no HTTP request
    # will be performed when a new object is created. Only when you use an
    # accessor that needs the remote data, a HTTP request is made (once).
    #
    def initialize(imdb_id, title = nil)
      @id = imdb_id
      @url = Imdb::Base.url_for(@id, :reference)
      @title = title.delete('"').strip if title
    end

    def reload
      @title = nil
      @year = nil
      @poster_thumbnail = nil
    end

    # Returns an array with cast members
    def cast_members
      document.search('table.cast_list td.itemprop a').map { |a| a.content.strip } rescue []
    end

    def cast_member_ids
      document.search('table.cast_list tr td[itemprop="actor"] a').map { |a| a['href'][/(?<=\/name\/)nm\d+/] }
    end

    # Returns an array with cast characters
    def cast_characters
      document.search('table.cast_list td.character').map { |a| a.content.tr("\u00A0", ' ').gsub(/(\(|\/).*/, '').strip } rescue []
    end

    # Returns an array with cast members and characters
    def cast_members_characters(sep = '=>')
      cast_members.zip(cast_characters).map do |cast_member, cast_character|
        "#{cast_member} #{sep} #{cast_character}"
      end
    end

    # Returns an array of starring actors as strings
    def starring_actors
      apex_document.search('//span[@itemprop="actors"]//span[@itemprop="name"]/text()').map(&:content) rescue []
    end

    # Returns the name of the directors.
    # Extracts from full_credits for movies with more than 3 directors.
    def directors
      top_directors = document.search("div[text()*='Director']//a").map { |a| a.content.strip }
      if top_directors.empty? || top_directors.last.start_with?('See more')
        all_directors
      else
        top_directors
      end
    end
    # NOTE: Keeping Base#director method for compatibility.
    alias director directors

    # Returns the names of Writers
    # Extracts from full_credits for movies with more than 3 writers.
    def writers
      top_writers = document.search("div[text()*='Writer']//a").map { |a| a.content.strip }
      if top_writers.empty? || top_writers.last.start_with?('See more')
        all_writers
      else
        top_writers
      end
    end

    # Returns the url to the "Watch a trailer" page
    def trailer_url
      'http://www.imdb.com/' + document.at("a[@href^='videoplayer/']")['href'] rescue nil
    end

    # Returns an array of genres (as strings)
    def genres
      document.search("//tr[td[contains(@class, 'label') and text()='Genres']]/td[2]//a").map { |a| a.content.strip } rescue []
    end

    # Returns an array of languages as strings.
    def languages
      document.search("//tr[td[contains(@class, 'label') and text()='Language']]/td[2]//a").map { |a| a.content.strip } rescue []
    end

    # Returns an array of countries as strings.
    def countries
      document.search("//tr[contains(@class, 'item') and td[text()='Country']]/td[2]//a").map { |a| a.content.strip } rescue []
    end

    # Returns the duration of the movie in minutes as an integer.
    def length
      document.at("//tr[td[contains(@class, 'label') and text()='Runtime']]/td[2]").content.strip.gsub(/ min$/, '').to_i rescue nil
    end

    # Returns a single production company (legacy)
    def company
      production_companies.first
    end

    # Returns a list of production companies
    def production_companies
      document.search("//h4[text()='Production Companies']/following::ul[1]/li/a[contains(@href, '/company/')]").map { |a| a.content.strip } rescue []
    end

    # Returns a string containing the (possibly truncated) plot summary.
    def plot
      sanitize_plot(document.at('//section[contains(@class, "overview")]//hr[last()]/preceding-sibling::div[1]').content.strip) rescue nil
    end

    # Returns a string containing the plot synopsis
    def plot_synopsis
      summary_document.at("li[@id*='synopsis']").content.strip rescue nil
    end

    # Retruns a string with a longer plot summary
    def plot_summary
      document.at("//tr[td[contains(@class, 'label') and text()='Plot Summary']]/td[2]/p/text()").content.strip rescue nil
    end

    # Returns a string containing the URL for a thumbnail sized movie poster.
    def poster_thumbnail
      return @poster_thumbnail if @poster_thumbnail
      document.at("img[@alt*='Poster']")['src'] rescue nil
    end

    # Returns a string containing the URL to the movie poster.
    def poster
      case poster_thumbnail
      when /^(https?:.+@@)/
        Regexp.last_match[1] + '.jpg'
      when /^(https?:.+?)\.[^\/]+$/
        Regexp.last_match[1] + '.jpg'
      end
    end

    # Returns a float containing the average user rating
    def rating
      document.at('.ipl-rating-star__rating').content.strip.to_f rescue nil
    end

    # Returns an enumerator of user reviews as hashes
    # NOTE: Not an enumerator of arrays of hashes anymore.
    def user_reviews
      Enumerator.new do |enum|
        data_key = nil
        loop do
          reviews_doc = userreviews_document(data_key)
          review_divs = reviews_doc.search('div.review-container')
          break if review_divs.empty?
          review_divs.each do |review_div|
            title = review_div.at('div.title').text
            text = review_div.at('div.content div.text').text
            rating = review_div.at_xpath(".//span[@class='point-scale']/preceding-sibling::span").text.to_i rescue nil
            enum.yield(title: title, review: text, rating: rating)
          end
          # Extracts the key for the next page
          data_key = reviews_doc.at('div.load-more-data')['data-key'] rescue nil
          break unless data_key
          sleep 1
        end
      end
    end

    # Returns an int containing the Metascore
    def metascore
      apex_document.at('div[@class*="metacriticScore"]/span').content.to_i rescue nil
    end

    # Returns an int containing the number of user ratings
    def votes
      document.at('.ipl-rating-star__total-votes').content.strip.gsub(/[^\d+]/, '').to_i rescue nil
    end

    # Returns a string containing the tagline
    def tagline
      document.at("//tr[td[contains(@class, 'label') and text()='Taglines']]/td[2]/text()").text.strip rescue nil
    end

    # Returns a string containing the mpaa rating and reason for rating
    def mpaa_rating
      apex_document.at("span[@itemprop='contentRating']").content.strip
    end

    # Returns a string containing the MPAA letter rating.
    # IMDB Certificates also include 'TV-14' or 'TV-MA', so they need to be filtered out.
    def mpaa_letter_rating
      document.search("a[@href*='certificates=US%3A']").map do |a|
        a.text.gsub(/^United States:/, '')
      end.find { |r| r =~ /\b(G|PG|PG-13|R|NC-17)\b/ }
    end

    # Returns a string containing the original title if present, the title otherwise.
    # Even with localization disabled, "Die Hard" will be displayed as "Stirb langsam (1998) Die Hard (original title)" in Germany
    def title(force_refresh = false)
      if @title && !force_refresh
        @title
      else
        original_title = document.at_xpath("//h3[@itemprop='name']/following-sibling::text()").content.strip
        @title = if original_title.empty?
                   document.at("//h3[@itemprop='name']/text()").content.strip rescue nil
                 else
                   original_title
                 end
      end
    end

    # Returns an integer containing the year (CCYY) the movie was released in.
    def year
      return @year if @year
      document.at("//h3[@itemprop='name']/span/a/text()").content.strip.to_i rescue nil
    end

    # Returns release date for the movie.
    def release_date
      sanitize_release_date(document.at("a[@href*='/releaseinfo']").text) rescue nil
    end

    # Returns filming locations from imdb_url/locations
    def filming_locations
      locations_document.search('#filming_locations .soda dt a').map { |link| link.content.strip } rescue []
    end

    # Returns alternative titles from imdb_url/releaseinfo
    def also_known_as
      releaseinfo_document.search('#akas tr').map do |aka|
        {
          version: aka.search('td:nth-child(1)').text,
          title:   aka.search('td:nth-child(2)').text,
        }
      end rescue []
    end

    private

    # Returns a new Nokogiri document for parsing.
    def document
      @document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id))
    end

    def locations_document
      @locations_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'locations'))
    end

    def releaseinfo_document
      @releaseinfo_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'releaseinfo'))
    end

    def fullcredits_document
      @fullcredits_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'fullcredits'))
    end

    def apex_document
      @apex_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, ''))
    end

    def summary_document
      @summary_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'plotsummary'))
    end

    def userreviews_document(data_key = nil)
      path = if data_key
               "reviews/_ajax?paginationKey=#{data_key}"
             else
               'reviews'
             end
      Nokogiri::HTML(Imdb::Movie.find_by_id(@id, path))
    end

    def all_directors
      fullcredits_document.search("h4[text()*='Directed by'] + table tbody tr td[class='name']").map do |name|
        name.content.strip
      end.uniq
    end

    def all_writers
      fullcredits_document.search("h4[text()*='Writing Credits'] + table tbody tr td[class='name']").map do |name|
        name.content.strip
      end.uniq
    end

    # Use HTTParty to fetch the raw HTML for this movie.
    def self.find_by_id(imdb_id, page = :reference)
      open(Imdb::Base.url_for(imdb_id, page), Imdb::HTTP_HEADER)
    end

    def self.url_for(imdb_id, page = :reference)
      "http://www.imdb.com/title/tt#{imdb_id}/#{page}"
    end

    # Convenience method for search
    def self.search(query)
      Imdb::Search.new(query).movies
    end

    def self.top_250
      Imdb::Top250.new.movies
    end

    def sanitize_plot(the_plot)
      the_plot = the_plot.gsub(/add\ssummary|full\ssummary/i, '')
      the_plot = the_plot.gsub(/add\ssynopsis|full\ssynopsis/i, '')
      the_plot = the_plot.gsub(/see|more|\u00BB|\u00A0/i, '')
      the_plot = the_plot.gsub(/\|/i, '')
      the_plot.strip
    end

    def sanitize_release_date(the_release_date)
      the_release_date.gsub(/see|more|\u00BB|\u00A0/i, '').strip
    end
  end # Movie
end # Imdb
