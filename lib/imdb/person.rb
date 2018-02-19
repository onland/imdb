module Imdb
  # Represents a person on IMDB.com
  class Person
    attr_accessor :id, :url

    def initialize(imdb_id)
      @id = imdb_id
      @url = "http://www.imdb.com/name/#{imdb_id}/"
    end

    # NOTE: Can a Person not have a name on IMDB?
    def name
      get_node_content("//span[@itemprop='name']")
    end

    def roles
      document.search("//span[@itemprop='jobTitle']").map { |a| a.content.strip }
    end

    def birth_date
      get_node_content("//time[@itemprop='birthDate']") do |node|
        Date.parse(node['datetime'])
      end
    end

    def death_date
      get_node_content("//time[@itemprop='deathDate']") do |node|
        Date.parse(node['datetime'])
      end
    end

    def age
      return unless birth_date
      bday = birth_date
      end_date = death_date || Date.today
      age = (end_date.year - bday.year)
      age -= 1 if end_date < Date.new(end_date.year, bday.month, bday.day)
      age
    end

    # NOTE: Can a Person not have a bio on IMDB?
    def bio
      get_node_content("//div[@itemprop='description']/text()")
    end

    # Returns an array of Imdb::Movie objects with some data pre-populated
    def known_for
      document.search("//div[starts-with(@id, 'knownfor')]/div[contains(@class, 'knownfor-title')]").map do |div|
        begin
          imdb_id = div.at("div[@class='knownfor-title-role']/a")['href'][/(?<=title\/tt)\d+/]
          movie = Imdb::Movie.new(imdb_id)
          movie.title = div.at("div[@class='knownfor-title-role']/a").content
          movie.year = div.at("div[@class='knownfor-year']/span").content[/\d{4}/].to_i
          movie.poster_thumbnail = div.at('img')['src']
          movie.related_person = self
          movie.related_person_role = div.at("div[@class='knownfor-title-role']/span").content
          movie
        rescue
          nil
        end
      end.compact
    end

    def picture_thumbnail
      get_node_content("//img[@id='name-poster']") { |node| node['src'] }
    end

    def award_highlight
      get_node_content("//span[@itemprop='awards']/b") do |node|
        node.content.gsub(/[[:space:]]+/, ' ').strip
      end
    end

    def nickname
      get_node_content("//div[h4[text()='Nickname:']]/text()[2]")
    end

    def personal_quote
      get_node_content("//div[h4[text()='Personal Quote:']]") do |node|
        node.content.delete("\r\n").strip.gsub(/^Personal Quote:/, '').gsub(/\s\s+See more.*/, '')
      end
    end

    def alternative_names
      document.search("//div[h4[text()='Alternate Names:']]/text()").map do |name|
        nm = name.content.strip
        nm unless nm.empty?
      end.compact
    end

    private

    # Get node content from document at xpath.
    # Returns stripped content if present, nil otherwise.
    def get_node_content(xpath)
      node = document.at(xpath)
      if node
        if block_given?
          yield node
        else
          node.content.strip
        end
      end
    end

    def document
      @document ||= Nokogiri::HTML(open(@url, Imdb::HTTP_HEADER))
    end
  end
end
