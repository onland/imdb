module Imdb
  class BoxOffice < MovieList
    private

    def document
      @document ||= Nokogiri::HTML(open('http://www.imdb.com/chart/boxoffice', Imdb::HTTP_HEADER))
    end
  end # BoxOffice
end # Imdb
