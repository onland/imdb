require 'spec_helper'

describe 'Imdb::Person' do
  context 'Federico Fellini' do
    subject { Imdb::Person.new('nm0000019') }

    it 'finds the name' do
      expect(subject.name).to eq('Federico Fellini')
    end

    it 'finds their birth date' do
      expect(subject.birth_date).to eq(Date.new(1920, 1, 20))
    end

    it 'finds their death date' do
      expect(subject.death_date).to eq(Date.new(1993, 10, 31))
    end

    it 'finds their age' do
      expect(subject.age).to eq(73)
    end

    it 'finds movies they are known for' do
      known_for = subject.known_for
      expect(known_for).to be_an(Array)
      known_for.each { |movie| expect(movie).to be_an_instance_of(Imdb::Movie) }

      expect(known_for.last.id).to eq('0056801')
      expect(known_for.last.title).to eq('8½')
      expect(known_for.last.year).to eq(1963)
      expect(known_for.last.poster_thumbnail).to match(/\Ahttp.*jpg\Z/)
      expect(known_for.last.related_person).to eq(subject)
      expect(known_for.last.related_person_role).to eq('Writer')

      expect(known_for[1].id).to eq('0050783')
      expect(known_for[1].title).to eq('The Nights of Cabiria')
      expect(known_for[1].year).to eq(1957)
      expect(known_for[1].poster_thumbnail).to match(/\Ahttp.*jpg\Z/)
      expect(known_for[1].related_person).to eq(subject)
      expect(known_for[1].related_person_role).to eq('Writer')
    end

    it 'finds their picture thumbnail' do
      expect(subject.picture_thumbnail).to eq('https://images-na.ssl-images-amazon.com/images/M/MV5BMjE0NDI1MDU5Nl5BMl5BanBnXkFtZTgwNjQ2ODMwMzE@._V1_UY317_CR8,0,214,317_AL_.jpg')
    end

    it 'finds their roles' do
      expect(subject.roles).to include('Writer', 'Director')
    end

    it 'finds their bio' do
      expect(subject.bio).to start_with(/[A-Z]/)
      expect(subject.bio).to match(/Life and dreams were raw material for his films./)
    end

    it 'finds their nickname' do
      expect(['Il Maestro', 'FeFe']).to include(subject.nickname)
    end

    it 'finds their alternative names' do
      expect(subject.alternative_names).to include('Federico', 'F. Fellini')
    end

    it 'finds their award highlight' do
      expect(subject.award_highlight).to eq('Nominated for 12 Oscars.')
    end

    it 'finds their personal quote' do
      possible_quotes = [
        'There is no end. There is no beginning. There is only the infinite passion of life.',
        'My work is my only relationship to everything.',
        'You exist only in what you do.',
        'In the myth of the cinema, Oscar is the supreme prize.',
        'In the mythology of the cinema, the Oscar is the supreme prize.',
        'Our dreams are our real life. My fantasies and obsessions are not only my reality, but the stuff of which my films are made.',
        'You have to live spherically--in many directions. To accept yourself for what you are without inhibitions, to be open.',
        'Put yourself into life and never lose your openness, your childish enthusiasm throughout the journey that is life, and things will come your way.',
        "It's easier to be faithful to a restaurant than it is to a woman.",
        "All art is autobiographical. The pearl is the oyster's autobiography.",
        "Cinema is an old whore, like circus and variety, who knows how to give many kinds of pleasure. Besides, you can't teach old fleas new dogs.",
        'Censorship is advertising paid by the government.',
        "It's absolutely impossible to improvise. Making a movie is a mathematical operation. It is like sending a missile to the moon. It isn't improvised. It is too defined to be called improvisational, too mechanical. Art is a scientific operation, so I can say that what we usually call improvisation is in my case just having an ear and eye for things that sometimes occur during the time we are making the picture.",
        "I always direct the same film. I can't distinguish one from another.",
        "Happiness is simply a temporary condition that proceeds unhappiness. Fortunately for us, it works the other way around as well. But it's all a part of the carnival, isn't it.",
        '[on Akira Kurosawa] I think he is the greatest example of all that an author of the cinema should be. I feel a fraternal affinity with his way of telling a story.',
        "We don't really know who woman is. She remains in that precise place within man where darkness begins. Talking about women means talking about the darkest part of ourselves, the undeveloped part, the true mystery within. In the beginning, I believe man was complete and androgynous-both male and female, or neither, like angels. Then came the division, and Eve was taken from him. So the problem for man is to reunite himself with the other half of his being, to find the woman who is right for him-right be she is simply a projection, a mirror of himself. A man can't become whole or free until he has set woman free-his woman. It's his responsibility, not hers. He can't be complete, truly alive until he makes her his sexual companion, and not a slave of libidinous acts or a saint with a halo.",
        "I'm just a storyteller, and the cinema happens to be my medium. I like it because it recreates life in movement, enlarges it, enhances it, distills it. For me, it's far closer to the miraculous creation of life than, say, a painting or music or even literature. It's not just an art form; it's actually a new form of life, with its own rhythms, cadences, perspectives and transparencies. It's my way of telling a story.",
        'Anyone who lives, as I do, in a world of imagination must make an enormous and unnatural effect to be factual in the ordinary sense. I confess I would be a terrible witness in court because of this--and a terrible journalist. I feel compelled to a story the way I see it and this is seldom the way it happened, in all its documentary detail.',
        "No doubt there's a connection between pathology and creation, we can't deny it. Yet I view with pleasure the work of film professionals I love, such as Bunuel, Kurosawa, Kubrick, Bergman.",
        'With the death of Sergei Parajanov cinema lost one of its magicians. (July, 1990)',
        "Talking about dreams is like talking about movies, since the cinema uses the language of dreams; years can pass in a second and you can hop from one place to another. It's a language made of image. And in the real cinema, every object and every light means something as in a dream.",
        'The visionary is the only true realist.',
        'Even if I set out to make a film about a fillet of sole, it would be about me.',
        'Our duty as storytellers is to bring people to the station. There each person will choose his or her own train... But we must at least take them to the station... to a point of departure.',
      ]
      expect(subject.personal_quote).to satisfy do |quote|
        possible_quotes.any? do |possible_quote|
          possible_quote.start_with? quote.chomp('...')
        end
      end
    end
  end

  context 'Steven Spielberg' do
    subject { Imdb::Person.new('nm0000229') }

    it 'finds they are living' do
      expect(subject.birth_date).to eq(Date.new(1946, 12, 18))
      expect(subject.death_date).to eq(nil)
    end

    it 'finds nickname is nil if there is none' do
      expect(subject.nickname).to eq(nil)
    end

    it 'finds their award highlight' do
      expect(subject.award_highlight).to eq('Won 3 Oscars.')
    end

    it 'finds their age' do
      expect(subject.age).to eq(71)
    end
  end

  context 'Gerry Bamman' do
    subject { Imdb::Person.new('nm0051482') }

    it 'has no award highlight' do
      expect(subject.award_highlight).to eq(nil)
    end

    it 'finds they are an actor' do
      expect(subject.roles).to include('Actor')
    end

    it 'finds their personal quote' do
      expect(subject.personal_quote).to eq(nil)
    end
  end

  context 'Nelson McCormick' do
    subject { Imdb::Person.new('nm1879589') }

    it 'finds their name' do
      expect(subject.name).to eq('Nelson McCormick')
    end

    it 'handles lack of birth and death date' do
      expect(subject.birth_date).to eq(nil)
      expect(subject.death_date).to eq(nil)
      expect(subject.age).to eq(nil)
    end
  end

  context 'Keanu Reeves' do
    subject { Imdb::Person.new('nm0000206') }

    it 'finds their name' do
      expect(subject.name).to eq('Keanu Reeves')
    end

    it 'finds the personal quote even if there is a hyperlink in it' do
      expect(subject.personal_quote).to eq('[on River Phoenix] River was a remarkable artist and a rare human being. I miss him every day.')
    end
  end

  context 'with not much information except name' do
    subject { Imdb::Person.new('nm0742578') }

    it 'finds their name' do
      expect(subject.name).to eq('María Rosenfeldt')
    end

    it 'has no nickname' do
      expect(subject.nickname).to be_nil
    end

    it 'has no personal quote' do
      expect(subject.personal_quote).to be_nil
    end

    it 'has no birth date' do
      expect(subject.birth_date).to be_nil
    end

    it 'has no death date' do
      expect(subject.death_date).to be_nil
    end

    it 'has no age' do
      expect(subject.age).to be_nil
    end

    it 'has no picture' do
      expect(subject.picture_thumbnail).to be_nil
    end

    it 'has a template bio' do
      expect(subject.bio).to match(/#{subject.name} is an (actor|actress), known for/)
    end

    it 'has no award' do
      expect(subject.award_highlight).to be_nil
    end

    it 'has a single known_for movie' do
      expect(subject.known_for.size).to eq(1)
      expect(subject.known_for[0].related_person_role).to eq('Niña')
    end
  end
end
