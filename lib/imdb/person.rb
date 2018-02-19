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
      name_html = document.at("//span[@itemprop='name']")
      name_html.content.strip if name_html
    end

    def roles
      document.search("//span[@itemprop='jobTitle']").map { |a| a.content.strip }
    end

    def birth_date
      birth_date_html = document.at("//time[@itemprop='birthDate']")
      Date.parse(birth_date_html['datetime']) if birth_date_html
    end

    def death_date
      death_date_html = document.at("//time[@itemprop='deathDate']")
      Date.parse(death_date_html['datetime']) if death_date_html
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
      bio_html = document.at("//div[@itemprop='description']/text()")
      bio_html.content.strip if bio_html
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
      img_html = document.at("//img[@id='name-poster']")
      img_html['src'] if img_html
    end

    def award_highlight
      award_html = document.at("//span[@itemprop='awards']/b")
      award_html.content.gsub(/[[:space:]]+/, ' ').strip if award_html
    end

    def nickname
      nickname_html = document.at("//div[h4[text()='Nickname:']]/text()[2]")
      nickname_html.content.strip if nickname_html
    end

    def personal_quote
      quote_html = document.at("//div[h4[text()='Personal Quote:']]")
      quote_html.content.delete("\r\n").strip.gsub(/^Personal Quote:/, '').gsub(/\s\s+See more.*/, '') if quote_html
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
