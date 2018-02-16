require 'spec_helper'

describe 'Imdb::Serie' do
  subject { Imdb::Serie.new('1520211') }

  # Double check from Base.
  it 'finds the title' do
    expect(subject.title).to eq('The Walking Dead')
  end

  it 'finds the creators' do
    expect(subject.creators).to include('Frank Darabont')
  end

  it 'reports the number of seasons' do
    expect(subject.seasons.size).to eq(9)
  end

  it 'finds the plot' do
    expect(subject.plot).to match('Sheriff Deputy Rick Grimes wakes up from a coma to learn the world is in ruins')
  end

  it 'can fetch a specific season' do
    expect(subject.season(1).season_number).to eq(1)
    expect(subject.season(1).episodes.size).to eq(6)
  end

  context 'Mad Men' do
    # Mad Men (2007)
    subject { Imdb::Serie.new('0804503') }

    it 'finds the base info' do
      expect(subject.title).to eq('Mad Men')
      expect(subject.year).to eq(2007)
      expect(subject.plot).to match(/A drama about one of New York's most prestigious ad agencies at the beginning of the 1960s/)
      expect(subject.plot_summary).to match(/The professional and personal lives of those who work in advertising on Madison Avenue/)
      expect(subject.starring_actors).to include('Jon Hamm', 'Elisabeth Moss')
      expect(subject.creators).to include('Matthew Weiner')
      expect(subject.directors).to include('Matthew Weiner', 'Phil Abraham')
      expect(subject.writers).to include('Matthew Weiner')
      expect(subject.cast_members).to include('Jon Hamm', 'John Slattery')
      expect(subject.cast_characters).to include('Don Draper', 'Roger Sterling')
      expect(subject.poster_thumbnail).to match(/\Ahttp.*.jpg\Z/)
    end
  end
end

describe 'Imdb::Serie with only one season' do
  subject { Imdb::Serie.new('0303461') }

  # Double check from Base.
  it 'finds the title' do
    expect(subject.title).to match(/Firefly/)
  end

  it 'reports the number of seasons' do
    expect(subject.seasons.size).to eq(1)
  end

  it 'finds the plot' do
    expect(subject.plot).to match('Five hundred years in the future, a renegade crew aboard a small spacecraft tries to survive')
  end

  it 'can fetch a specific season' do
    expect(subject.season(1).season_number).to eq(1)
    expect(subject.season(1).episodes.size).to eq(14)
  end
end
