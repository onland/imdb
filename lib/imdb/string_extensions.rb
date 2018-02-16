require 'cgi'

module Imdb #:nordoc:
  module StringExtensions
    # Unescape HTML
    def imdb_unescape_html
      CGI.unescapeHTML(encode('UTF-8'))
    end

    # Strip tags
    def imdb_strip_tags
      gsub(/<\/?[^>]*>/, '')
    end

    # Strips out whitespace then tests if the string is empty.
    unless method_defined?(:blank?)
      def blank?
        strip.empty?
      end
    end
  end
end

String.send :include, Imdb::StringExtensions
