module Imdb
  class BoxOffice < MovieList
    def movies
      @movies ||= parse_movies('.chart')
    end
    private

    def document
      @document ||= Nokogiri::HTML(open('http://www.imdb.com/chart/boxoffice/', Imdb::HTTP_HEADER))
    end
  end # BoxOffice
end # Imdb
