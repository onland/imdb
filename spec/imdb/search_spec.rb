require 'spec_helper'

describe 'Imdb::Search with multiple search results' do
  context 'Star Trek: TOS' do
    subject { Imdb::Search.new('Star Trek: TOS') }

    it 'remembers the query' do
      expect(subject.query).to eq('Star Trek: TOS')
    end

    it 'finds many results' do
      expect(subject.movies.size).to be_within(50).of(250)
    end

    it 'returns Imdb::Movie objects only' do
      subject.movies.each { |movie| expect(movie).to be_a(Imdb::Movie) }
    end

    it 'does not return movies with no title' do
      subject.movies.each { |movie| expect(movie.title).to_not be_blank }
    end

    it 'returns only the title of the result' do
      expect(subject.movies.first.title).to eq('Star Trek (1966) (TV Series)')
    end

    it 'returns the correct result at the top' do
      expect(subject.movies.first.title(true)).to eq('Star Trek')
      expect(subject.movies.first.year).to eq(1966)
      expect(subject.movies.first.plot).to match(/Captain James T. Kirk and the crew of the Starship Enterprise/)
    end
  end
end

describe 'Imdb::Search with an exact match and no poster' do
  it 'does not raise an exception' do
    expect do
      Imdb::Search.new('Kannethirey Thondrinal').movies
    end.not_to raise_error
  end

  context 'Kannethirey Thondrinal' do
    subject { Imdb::Search.new('Kannethirey Thondrinal') }

    it 'returns the movie id correctly' do
      expect(subject.movies.first.id).to eq('0330508')
    end
  end
end
