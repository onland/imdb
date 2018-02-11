require 'spec_helper'

describe 'Imdb::Serie' do
  subject { Imdb::Serie.new('1520211') }

  # Double check from Base.
  it 'finds the title' do
    expect(subject.title).to match(/The Walking Dead/)
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
