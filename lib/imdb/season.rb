module Imdb
  class Season
    attr_reader :id, :url, :season_number

    def initialize(url)
      @url = url
      @id = url[/(?<=tt)\d+/]
      @season_number = @url[/(?<=episodes\?season=)\d+/].to_i
    end

    def episode(number)
      episodes.find { |ep| ep.episode == number }
    end

    def episodes
      @episodes ||= document.search("div.eplist div[@itemprop*='episode']").map do |div|
        link = div.at("a[@itemprop*='name']")
        Imdb::Episode.new(
          link[:href][/(?<=tt)\d+/],
          @season_number,
          div.at("meta[@itemprop*='episodeNumber']")[:content].to_i,
          link.content.strip
        )
      end
    end

    private

    def document
      @document ||= Nokogiri::HTML(open(@url, Imdb::HTTP_HEADER))
    end
  end
end
