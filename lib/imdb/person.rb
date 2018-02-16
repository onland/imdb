module Imdb
  # Represents a person on IMDB.com
  class Person
    attr_accessor :id, :url

    def initialize(imdb_id)
      @id = imdb_id
      @url = "http://www.imdb.com/name/#{imdb_id}/"
    end

    def name
      document.at("//span[@itemprop='name']").content.strip rescue nil
    end

    def roles
      document.search("//span[@itemprop='jobTitle']").map { |a| a.content.strip }
    end

    def birth_date
      Date.parse(document.at("//time[@itemprop='birthDate']")['datetime']) rescue nil
    end

    def death_date
      Date.parse(document.at("//time[@itemprop='deathDate']")['datetime']) rescue nil
    end

    def age
      return unless birth_date
      bday = birth_date
      end_date = death_date || Date.today
      age = (end_date.year - bday.year)
      age -= 1 if end_date < Date.new(end_date.year, bday.month, bday.day)
      age
    end

    def bio
      document.at("//div[@itemprop='description']/text()").content.strip rescue nil
    end

    # Returns an array of Imdb::Movie objects with some data pre-populated
    def known_for
      document.search("//div[@id='knownfor']/div[contains(@class, 'knownfor-title')]").map do |div|
        begin
          imdb_id = div.at("div[@class='knownfor-title-role']/a")['href'].match(/title\/tt([0-9]+)/)[1]
          movie = Imdb::Movie.new(imdb_id)
          movie.title = div.at("div[@class='knownfor-title-role']/a").content
          movie.year = div.at("div[@class='knownfor-year']/span").content.match(/\(([0-9\-]+)\)/)[1].to_i
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
      document.at("//img[@id='name-poster']")['src']
    end

    def award_highlight
      document.at("//span[@itemprop='awards']/b").content.gsub(/[[:space:]]+/, ' ').strip rescue nil
    end

    def nickname
      document.at("//div[h4[text()='Nickname:']]/text()[2]").content.strip rescue nil
    end

    def personal_quote
      document.at("//div[h4[text()='Personal Quote:']]").content.delete("\r\n").strip.gsub(/^Personal Quote:/, '').gsub(/\s\s+See more.*/, '') rescue nil
    end

    def alternative_names
      document.search("//div[h4[text()='Alternate Names:']]/text()").map do |name|
        nm = name.content.strip
        nm unless nm.empty?
      end.compact
    end

    private

    def document
      @document ||= Nokogiri::HTML(open(@url, Imdb::HTTP_HEADER))
    end
  end
end
