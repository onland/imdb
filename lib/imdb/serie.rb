module Imdb
  # Represents a TV series on IMDB.com
  class Serie < Base
    def season(number)
      seasons.fetch(number - 1, nil)
    end

    def seasons
      season_urls.map { |url| Imdb::Season.new(url) }
    end

    def creators
      document.search("div[text()*='Creator']//a").map { |a| a.content.strip } rescue []
    end

    private

    def newest_season
      document.at("section div[text()*='Season'] a[@href*='episodes?season']").content.strip.to_i rescue 0
    end

    def season_urls
      (1..newest_season).map do |num|
        Imdb::Base.url_for(@id, "episodes?season=#{num}")
      end
    end
  end # Serie
end # Imdb
