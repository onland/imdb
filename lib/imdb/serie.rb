module Imdb
  # Represents a TV series on IMDB.com
  class Serie < Base
    def season(number)
      seasons[number - 1]
    end

    def seasons
      season_urls.map { |url| Imdb::Season.new(url) }
    end

    private

    def season_urls
      season_count = document.search("section div[text()*='Season'] a[@href*='episodes?season']").map{|a| a.text.to_i}.max
      (1..season_count).map{ |season_id| URI.join(url, "episodes?season=#{season_id}").to_s }
    end
  end # Serie
end # Imdb
