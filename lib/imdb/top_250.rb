module Imdb
  class Top250 < MovieList
    private

    def document
      @document ||= Nokogiri::HTML(open('http://www.imdb.com/chart/top', Imdb::HTTP_HEADER))
    end
  end # Top250
end # Imdb
