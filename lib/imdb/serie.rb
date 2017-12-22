module Imdb
  # Represents a TV series on IMDB.com
  class Serie < Base
    def season(number)
      seasons.fetch(number - 1, nil)
    end

    def seasons
      season_urls.map { |url| Imdb::Season.new(url) }
    end

    private

    def newest_season
      document.at("//div[contains(text(), 'Seasons:')]/a").content.strip.to_i rescue 0
    end

    def season_urls
      (1..newest_season).map do |num|
        Imdb::Base.url_for(@id, "episodes?season=#{num}")
      end
    end
  end # Serie
end # Imdb
