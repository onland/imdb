module Imdb
  # Represents something on IMDB.com
  class Base
    attr_accessor :id, :url, :title, :also_known_as

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
      @url = "http://www.imdb.com/title/tt#{imdb_id}/reference"
      @title = title.gsub(/"/, '').strip if title
    end

    # Returns an array with cast members
    def cast_members
      document.search('table.cast_list tr td[itemprop="actor"] a span').map(&:text)
    end

    def cast_member_ids
      document.search('table.cast_list tr td[itemprop="actor"] a').map{|l| l['href'][/(?<=\/name\/)nm\d+/]}
    end

    # Returns an array with cast characters
    def cast_characters
      document.search('table.cast_list tr td.character div').map{|div| div.text.strip.gsub(/\s+/, " ") }
    end

    # Returns an array with cast members and characters
    def cast_members_characters(sep = '=>')
      memb_char = []
      cast_members.zip(cast_characters).map{|cast_member, cast_character|
        "#{cast_member} #{sep} #{cast_character}"
      }
    end

    # Returns the name of the director
    def director
      #PATCH: h5 -> div.titlereference...
      document.search("div.titlereference-overview-section:contains('Director') ul li a").map { |link| link.content.strip } rescue []
    end

    # Returns the names of Writers
    def writers
      fullcredits_document.search("h4[text()^='Writing Credits'] + table tbody tr td[class='name']").map do |name|
        name.content.strip
      end.uniq rescue []
    end

    # Returns the url to the "Watch a trailer" page
    def trailer_url
      'http://www.imdb.com' + document.at("a[@href*='/video/screenplay/']")['href'] rescue nil
    end

    # Returns an array of genres (as strings)
    def genres
      # Alternative:
      # document.search("tr.ipl-zebra-list__item td.ipl-zebra-list__label[text()^='Genres'] ~ td ul li a").map(&:text)
      document.search("td a[@href*='/genre/']").map(&:text)
    end

    # Returns an array of languages as strings.
    def languages
      document.search("td a[@href*='/language/']").map(&:text)
    end

    # Returns an array of countries as strings.
    def countries
      document.search("td a[@href*='/country/']").map(&:text)
    end

    # Returns the duration of the movie in minutes as an integer.
    def length
      #PATCH: h5 -> td:contains
      document.at("td:contains('Runtime') ~ td ul li").content[/\d+ min/].to_i rescue nil
    end

    # Returns the company
    def company
      document.search("h5[text()='Company:'] ~ div a[@href*='/company/']").map { |link| link.content.strip }.first rescue nil
    end

    # Returns a string containing the plot.
    def plot
      #PATCH No 'Plot:' anymore. Could be brittle
      sanitize_plot(document.at("section.titlereference-section-overview div").content) rescue nil
    end

    # Returns a string containing the plot summary
    def plot_synopsis
      doc = Nokogiri::HTML(Imdb::Movie.find_by_id(@id, :plotsummary))
      doc.at('ul#plot-synopsis-content li').text.imdb_unescape_html
    end

    def plot_summary
      doc = Nokogiri::HTML(Imdb::Movie.find_by_id(@id, :plotsummary))
      doc.at('ul#plot-summaries-content li p').text.imdb_unescape_html
    end

    # Returns a string containing the URL to the movie poster.
    def poster
      #PATCH a name poster -> alt=Poster
      src = document.at("a img[alt=Poster]")['src'] rescue nil
      case src
      when /^(https?:.+@@)/
        Regexp.last_match[1] + '.jpg'
      when /^(https?:.+?)\.[^\/]+$/
        Regexp.last_match[1] + '.jpg'
      end
    end

    # Returns a float containing the average user rating
    def rating
      #PATCH: starbar-meta -> ipl-rating...
      document.at('.ipl-rating-star__rating').content.to_f rescue nil
    end

    def user_reviews
      Enumerator.new do |enum|
        start = 0
        loop do
          ratings = userreviews_document(start)
                      .search('//div[contains(@id, "tn15content")]//div[@class="yn"]//preceding-sibling::*[self::div and not(contains(@class, "yn")) or self::p]')
                      .each_slice(2).map do |head, review|
                        rating = head.children.search('img')[1]
                        {
                          title: head.at('h2').text,
                          rating: rating ? rating['alt'].to_s.gsub('/10', '').to_i : nil,
                          review: review.text
                        }
          end.compact
          break if ratings.empty?
          enum.yield(ratings)
          start += 10
          sleep 1
        end
      end
    end
    
    # Returns an int containing the Metascore
    def metascore
      criticreviews_document.at('//span[@itemprop="ratingValue"]').content.to_i rescue nil
    end

    # Returns an int containing the number of user ratings
    def votes
      document.at('#tn15rating .tn15more').content.strip.gsub(/[^\d+]/, '').to_i rescue nil
    end

    # Returns a string containing the tagline
    def tagline
      document.at("tr.ipl-zebra-list__item td.ipl-zebra-list__label[text()^='Taglines'] ~ td").children.first.text.strip rescue nil
    end

    # Returns a string containing the mpaa rating and reason for rating
    def mpaa_rating
      document.at("//a[starts-with(.,'MPAA')]/../following-sibling::*").content.strip rescue nil
    end

    # Returns a string containing the title
    def title(force_refresh = false)
      if @title && !force_refresh
        @title
      else
        # If (original title) is present, it's the first text node after 'h3'
        original_title = document.at_xpath('//h3/following-sibling::text()').content.strip.imdb_unescape_html
        @title = if original_title.empty?
                   document.at('h3').inner_html.split('<span').first.strip.imdb_unescape_html rescue nil
                 else
                   original_title
                 end
      end
    end

    # Returns an integer containing the year (CCYY) the movie was released in.
    def year
      #PATCH: Link has moved
      # "a[@href^='/year/']" -> "a[@href^='/search/title?year']"
      # or
      # "a[@href^='/year/']" -> "span.titlereference-title-year a"
      document.at("span.titlereference-title-year a").content.to_i rescue nil
    end

    # Returns release date for the movie.
    def release_date
      sanitize_release_date(document.at("li a[@href*='/releaseinfo']").text) rescue nil
    end

    # Returns filming locations from imdb_url/locations
    def filming_locations
      locations_document.search('#filming_locations_content .soda dt a').map { |link| link.content.strip } rescue []
    end

    # Returns alternative titles from imdb_url/releaseinfo
    def also_known_as
      releaseinfo_document.search('#akas tr').map do |aka|
        {
          version: aka.search('td:nth-child(1)').text,
          title:   aka.search('td:nth-child(2)').text
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
    
    def criticreviews_document
      @criticreviews_document ||= Nokogiri::HTML(Imdb::Movie.find_by_id(@id, 'criticreviews'))
    end

    def userreviews_document(start=0)
      Nokogiri::HTML(Imdb::Movie.find_by_id(@id, "reviews?start=#{start}"))
    end
    
    # Use HTTParty to fetch the raw HTML for this movie.
    def self.find_by_id(imdb_id, page = :reference)
      open("http://www.imdb.com/title/tt#{imdb_id}/#{page}", Imdb::HTTP_HEADER)
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
