module Imdb
  class MovieList
    def movies
      @movies ||= parse_movies
    end

    private

    def parse_movies(table_css_class = "")
      document.search("table#{table_css_class} tr td[2] a[@href^='/title/tt']").map do |element|
        id = element['href'][/(?<=tt)\d+/]
        title = element.text.imdb_strip_tags.imdb_unescape_html

        if title =~ /\saka\s/
          titles = title.split(/\saka\s/)
          title = titles.first.strip.imdb_unescape_html
        end

        [id, title]
      end.uniq.map do |values|
        Imdb::Movie.new(*values)
      end
    end
  end # MovieList
end # Imdb
