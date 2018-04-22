# By default if you have the Webmock gem installed when the specs are
# run they will hit recorded responses.  However, if you don't have
# the Webmock gem installed or you set the environment variable
# LIVE_TEST then the tests will hit the live site IMDB.com.
#
# Having both methods available for testing allows you to quickly
# refactor and add features, while also being able to make sure that
# no changes to the IMDB.com interface have affected the parser.
###

require 'rspec'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'imdb'

# NOTE: An alternative would be to use VCR gem: https://github.com/vcr/vcr
def read_fixture(path)
  File.read(File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', path)))
rescue Errno::ENOENT
  raise(Errno::ENOENT, "Missing fixture #{path.inspect}. Please run 'rake fixtures:refresh ONLY=#{path}'")
end

IMDB_SAMPLES = {
  'https://www.imdb.com/find?q=Kannethirey+Thondrinal&s=tt' => 'search_kannethirey_thondrinal',
  'https://www.imdb.com/title/tt0330508/?fr=c2M9MXxsbT01MDB8ZmI9dXx0dD0xfG14PTIwfGh0bWw9MXxjaD0xfGNvPTF8cG49MHxmdD0xfGt3PTF8cXM9S2FubmV0aGlyZXkgVGhvbmRyaW5hbHxzaXRlPWFrYXxxPUthbm5ldGhpcmV5IFRob25kcmluYWx8bm09MQ__&fc=1&ft=1' => 'tt0330508',
  'https://www.imdb.com/find?q=I+killed+my+lesbian+wife&s=tt' => 'search_killed_wife',
  'https://www.imdb.com/find?q=Star+Trek%3A+TOS&s=tt' => 'search_star_trek',
  'https://www.imdb.com/title/tt0117731/reference' => 'tt0117731',
  'https://www.imdb.com/title/tt0095016/reference' => 'tt0095016',
  'https://www.imdb.com/title/tt0095016/' => 'apex',
  'https://www.imdb.com/title/tt0095016/reviews' => 'userreviews',
  'https://www.imdb.com/title/tt0095016/reviews/_ajax?paginationKey=h2hqyotfisvxpzqltwsrn76x7jrboz25p25prr4m2x5n4hrrusvwvq33z6w4yltpxvg2ku6z45q2m' => 'userreviews_p2',
  'https://www.imdb.com/title/tt0095016/plotsummary' => 'plotsummary',
  'https://www.imdb.com/title/tt0095016/locations' => 'locations',
  'https://www.imdb.com/title/tt0095016/releaseinfo' => 'releaseinfo',
  'https://www.imdb.com/title/tt0242653/reference' => 'tt0242653',
  'https://www.imdb.com/title/tt1821700/reference' => 'tt1821700',
  'https://www.imdb.com/title/tt0166222/?fr=c2M9MXxsbT01MDB8ZmI9dXx0dD0xfG14PTIwfGh0bWw9MXxjaD0xfGNvPTF8cG49MHxmdD0xfGt3PTF8cXM9SSBraWxsZWQgbXkgbGVzYmlhbiB3aWZlfHNpdGU9YWthfHE9SSBraWxsZWQgbXkgbGVzYmlhbiB3aWZlfG5tPTE_&fc=1&ft=7' => 'tt0166222',
  'https://www.imdb.com/chart/top' => 'top_250',
  'https://www.imdb.com/chart/boxoffice' => 'box_office',
  'https://www.imdb.com/title/tt0111161/reference' => 'tt0111161',
  'https://www.imdb.com/title/tt0111161/' => 'tt0111161_apex',
  'https://www.imdb.com/title/tt1401252/reference' => 'tt1401252',
  'https://www.imdb.com/title/tt0083987/reference' => 'tt0083987',
  'https://www.imdb.com/title/tt0036855/reference' => 'tt0036855',
  'https://www.imdb.com/title/tt0110912/reference' => 'tt0110912',
  'https://www.imdb.com/title/tt0468569/reference' => 'tt0468569',
  'https://www.imdb.com/title/tt1520211/reference' => 'tt1520211',
  'https://www.imdb.com/title/tt1520211/episodes?season=1' => 'thewalkingdead-s1',
  'https://www.imdb.com/title/tt1628064/reference' => 'thewalkingdead-s1e2',
  'https://www.imdb.com/title/tt0898266/episodes?season=1' => 'tbbt-s1',
  'https://www.imdb.com/title/tt0898266/reference' => 'tt0898266',
  'https://www.imdb.com/title/tt0056801/reference' => 'tt0056801',
  'https://www.imdb.com/title/tt0804503/reference' => 'tt0804503',
  'https://www.imdb.com/title/tt0804503/fullcredits' => 'mad_men_fullcredits',
  'https://www.imdb.com/title/tt0804503/' => 'tt0804503_apex',
  'https://www.imdb.com/name/nm0000019/' => 'nm0000019',
  'https://www.imdb.com/name/nm0000229/' => 'nm0000229',
  'https://www.imdb.com/name/nm0051482/' => 'nm0051482',
  'https://www.imdb.com/name/nm1879589/' => 'nm1879589',
  'https://www.imdb.com/name/nm0000206/' => 'nm0000206',
  'https://www.imdb.com/title/tt0303461/reference' => 'firefly',
  'https://www.imdb.com/title/tt0303461/episodes?season=1' => 'firefly-s1',
  'https://www.imdb.com/title/tt0060028/reference' => 'star_trek',
  'https://www.imdb.com/find?q=Wall-E&s=tt' => 'search_wall_e',
  'https://www.imdb.com/title/tt0910970/reference' => 'wall_e',
  'https://www.imdb.com/title/tt0401711/reference' => 'paris_je_t_aime',
  'https://www.imdb.com/title/tt0401711/fullcredits' => 'paris_je_t_aime_fullcredits',
  'https://www.imdb.com/title/tt5637536/reference' => 'avatar_5',
  'https://www.imdb.com/title/tt5637536/plotsummary' => 'avatar_5_plot',
  'https://www.imdb.com/title/tt5637536/reviews' => 'avatar_5_reviews',
  'https://www.imdb.com/title/tt5637536/' => 'avatar_5_apex',
  'https://www.imdb.com/title/tt7617048/reference' => 'untitled_star_wars_trilogy',
  'https://www.imdb.com/name/nm0742578/' => 'maria_rosenfeldt',
}.freeze

unless ENV['LIVE_TEST'] || ENV['FIXTURES_UPDATE']
  begin
    require 'rubygems'
    require 'webmock'

    WebMock.enable!
    WebMock.disable_net_connect!

    IMDB_SAMPLES.each do |url, fixture|
      # See https://github.com/bblimke/webmock/issues/274 for global stubs
      # stub_request could also be used, but it would need to be done before(:each) because stubs are cleared after each test.
      WebMock::StubRegistry.instance.global_stubs << WebMock::RequestStub.new(:get, url).to_return(read_fixture(fixture))
    end

  rescue LoadError
    puts 'Could not load Webmock, these tests will hit IMDB.com'
    puts 'You can run `gem install webmock` to stub out the responses.'
  end
end
