module Imdb
  class Episode < Base
    attr_accessor :season, :episode, :episode_title

    def initialize(imdb_id, season, episode, episode_title)
      super(imdb_id, episode_title)
      @url = "http://www.imdb.com/title/tt#{imdb_id}/reference"
      @season = season
      @episode = episode
    end

    # Return the original air date for this episode
    def air_date
      release_date
    end

    private

    def document
      @document ||= Nokogiri::HTML(open(@url))
    end
  end
end
