module Imdb
  class BoxOffice < MovieList
    private

    def document
      @document ||= Nokogiri::HTML(open('http://imdb.com/boxoffice/'))
    end
  end # BoxOffice
end # Imdb
