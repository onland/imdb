module Imdb
  # Represents a person on IMDB.com
  class Person
    include Util
    attr_accessor :id, :url

    def initialize(imdb_id)
      @id = imdb_id
      @url = "#{Imdb::HTTP_PROTOCOL}://www.imdb.com/name/#{imdb_id}/"
    end

    # NOTE: Can a Person not have a name on IMDB?
    def name
      get_node("//span[@itemprop='name']")
    end

    def roles
      get_nodes("//span[@itemprop='jobTitle']")
    end

    def birth_date
      get_node("//time[@itemprop='birthDate']") do |node|
        Date.parse(node['datetime'])
      end
    end

    def death_date
      get_node("//time[@itemprop='deathDate']") do |node|
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
      get_node("//div[@itemprop='description']/text()")
    end

    # Returns an array of Imdb::Movie objects with some data pre-populated
    def known_for
      get_nodes("//div[starts-with(@id, 'knownfor')]/div[contains(@class, 'knownfor-title')]") do |div|
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
      get_node("//img[@id='name-poster']") { |node| node['src'] }
    end

    def award_highlight
      get_node("//span[@itemprop='awards']/b") do |node|
        node.content.gsub(/[[:space:]]+/, ' ').strip
      end
    end

    def nickname
      get_node("//div[h4[text()='Nickname:']]/text()[2]")
    end

    def personal_quote
      get_node("//div[h4[text()='Personal Quote:']]") do |node|
        node.content.delete("\r\n").strip.gsub(/^Personal Quote:/, '').gsub(/\s\s+See more.*/, '')
      end
    end

    def alternative_names
      get_nodes("//div[h4[text()='Alternate Names:']]/text()").reject(&:empty?)
    end

    private

    def document
      @document ||= Nokogiri::HTML(open(@url, Imdb::HTTP_HEADER))
    end
  end
end
