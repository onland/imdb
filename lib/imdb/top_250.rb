module Imdb
  class Top250 < MovieList
    private

    def document
      @document ||= Nokogiri::HTML(open('http://imdb.com/chart/top'))
    end
  end # Top250
end # Imdb
