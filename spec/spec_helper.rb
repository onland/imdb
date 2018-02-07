# By default if you have the FakeWeb gem installed when the specs are
# run they will hit recorded responses.  However, if you don't have
# the FakeWeb gem installed or you set the environment variable
# LIVE_TEST then the tests will hit the live site IMDB.com.
#
# Having both methods available for testing allows you to quickly
# refactor and add features, while also being able to make sure that
# no changes to the IMDB.com interface have affected the parser.
###

require 'rspec'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'imdb'

def read_fixture(path)
  File.read(File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', path)))
end

def write_fixture(url, path)
  File.open(File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', path)), 'w+') do |fixture|
    fixture.write `curl -is #{url}`
  end
end

IMDB_SAMPLES = {
  'http://www.imdb.com:80/find?q=Kannethirey+Thondrinal;s=tt' => 'search_kannethirey_thondrinal',
  'http://www.imdb.com/title/tt0330508/?fr=c2M9MXxsbT01MDB8ZmI9dXx0dD0xfG14PTIwfGh0bWw9MXxjaD0xfGNvPTF8cG49MHxmdD0xfGt3PTF8cXM9S2FubmV0aGlyZXkgVGhvbmRyaW5hbHxzaXRlPWFrYXxxPUthbm5ldGhpcmV5IFRob25kcmluYWx8bm09MQ__;fc=1;ft=1' => 'tt0330508',
  'http://www.imdb.com:80/find?q=I+killed+my+lesbian+wife;s=tt' => 'search_killed_wife',
  'http://www.imdb.com/find?q=Star+Trek%3A+TOS;s=tt' => 'search_star_trek',
  'http://www.imdb.com:80/title/tt0117731/combined' => 'tt0117731',
  'http://www.imdb.com:80/title/tt0095016/combined' => 'tt0095016',
  'http://www.imdb.com/title/tt0095016/criticreviews' => 'criticreviews',
  'http://www.imdb.com/title/tt0095016/reviews?start=0' => 'userreviews',
  'http://www.imdb.com/title/tt0095016/synopsis' => 'synopsis',
  'http://www.imdb.com/title/tt0095016/plotsummary' => 'plotsummary',
  'http://www.imdb.com/title/tt0095016/locations' => 'locations',
  'http://www.imdb.com/title/tt0095016/releaseinfo' => 'releaseinfo',
  'http://www.imdb.com:80/title/tt0242653/combined' => 'tt0242653',
  'http://www.imdb.com:80/title/tt1821700/combined' => 'tt1821700',
  'http://www.imdb.com/title/tt1821700/fullcredits' => 'fullcredits',
  'http://www.imdb.com/title/tt0166222/?fr=c2M9MXxsbT01MDB8ZmI9dXx0dD0xfG14PTIwfGh0bWw9MXxjaD0xfGNvPTF8cG49MHxmdD0xfGt3PTF8cXM9SSBraWxsZWQgbXkgbGVzYmlhbiB3aWZlfHNpdGU9YWthfHE9SSBraWxsZWQgbXkgbGVzYmlhbiB3aWZlfG5tPTE_;fc=1;ft=7' => 'tt0166222',
  'http://www.imdb.com:80/chart/top' => 'top_250',
  'http://www.imdb.com/boxoffice/' => 'box_office',
  'http://www.imdb.com/title/tt0111161/combined' => 'tt0111161',
  'http://www.imdb.com/title/tt1401252/combined' => 'tt1401252',
  'http://www.imdb.com/title/tt0083987/combined' => 'tt0083987',
  'http://www.imdb.com/title/tt0036855/combined' => 'tt0036855',
  'http://www.imdb.com/title/tt0110912/combined' => 'tt0110912',
  'http://www.imdb.com/title/tt0468569/combined' => 'tt0468569',
  'http://www.imdb.com/title/tt1520211/combined' => 'tt1520211',
  'http://www.imdb.com/title/tt1520211/episodes?season=1' => 'thewalkingdead-s1',
  'http://www.imdb.com/title/tt1628064/combined' => 'thewalkingdead-s1e2',
  'http://www.imdb.com/title/tt0898266/episodes?season=1' => 'tbbt-s1',
  'http://www.imdb.com/title/tt0898266/combined' => 'tt0898266',
  'http://www.imdb.com/find?q=Wall-E;s=tt' => 'wall_e_search'
}

if ENV['UPDATE_FIXTURES']
  IMDB_SAMPLES.each do |url, basename|
    puts "Downloading #{url.inspect} as #{basename}"
    write_fixture(url, basename)
    sleep(1)
  end
end

begin
  require 'rubygems'
  require 'fakeweb'

  FakeWeb.allow_net_connect = false
  IMDB_SAMPLES.each do |url, response|
    FakeWeb.register_uri(:get, url, response: read_fixture(response))
  end
rescue LoadError
  puts 'Could not load FakeWeb, these tests will hit IMDB.com'
  puts 'You can run `gem install fakeweb` to stub out the responses.'
end
