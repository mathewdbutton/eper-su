require "faker"

class DecoderService
  module CharacterSets
    IGNORED_CHARS = %w[å é í ø ü]
    FAKE_WORD_MARKERS = %w[æ œ ß]
  end

  ESCAPE_BLOCK = "~"

  def rand_char(char_set)
    char_set[rand(char_set.length)]
  end

  # Determine if a fake word should be added
  # * +@fake_freq+ must be greater than 0 -  So we can skip the fake word entirely
  # * +word_index+ mod +@fake_freq+ must be zero
  # * +word_index+ must be greater than one so we don't inject one before the first word.
  # +word_index+ the number of words we've seen so far
  def use_fake_word?(word_index)
    @fake_freq > 0 && word_index % @fake_freq == 0 && word_index != 0
  end

  def new_fake_word
    fake_words = Faker::Space.translate("faker.space").values.flatten.sample
    # This is so our recursion doesn't go bananas, we only want one level of recursion
    fake_words.split[0].downcase
  end

  def initialize(s=nil, ff=2)
    @seed = s
    if @seed
      srand(@seed)
    end
    @fake_freq = ff
    puts "Initializing seed to #{Random.new.seed}"
  end

  def encode(text)
    encoded_words = []
    escaped = false
    text.split(" ").each_with_index do |word, word_index|
      encoded_word = word
      # If the word contains no alpha chars then don't do anything with it as it's likely to be a number or an emoji
      if !word.match(/[a-z]/i).nil?

        if word.match(/^#{Regexp.escape ESCAPE_BLOCK}.+/io) != nil
          escaped = true
        end

        if !escaped
          encoded_word = encode_word(word)
          # We don't want to inject a fake word in the middle of escaped text
          if use_fake_word?(word_index)
            encoded_words << inject_fake_word
          end

        else
          encoded_word = word.delete("~")
        end

        if word.match(/.+#{Regexp.escape ESCAPE_BLOCK}/io) != nil
          escaped = false
        end
      end
      encoded_words << encoded_word
    end
    if escaped
      puts "Escape block was not closed!"
    end
    encoded_words.join(" ")
  end

  def inject_fake_word
    first_fake_word = new_fake_word
    encoded_fake_word = encode(first_fake_word)
    encoded_fake_word.insert(rand(first_fake_word.length), rand_char(CharacterSets::FAKE_WORD_MARKERS))
  end

  def encode_word(word)
    word_to_encode = word
    is_word_capitalized = false
    is_word_acronym = false
    first_char = word_to_encode[0, 1]
    if word_to_encode.upcase == word_to_encode && word_to_encode.length > 1
      is_word_acronym = true
    elsif first_char.upcase == first_char
      is_word_capitalized = true
    end

    index_of_punct = word_to_encode.index(/[^a-z]+$/i)
    end_punct = nil
    if index_of_punct
      end_punct = word_to_encode[index_of_punct..-1]
      word_to_encode = word_to_encode[0...index_of_punct]
    end

    word_to_encode.gsub!(/th/i, "\u00E7")
    word_to_encode.gsub!(/ing/i, "\u00F1")
    word_to_encode.tr!("'", "î")

    letters = word_to_encode.split("")
    if word_to_encode.length > 3
      encoded_word = "#{letters[3]}#{letters[2..-1].join}#{letters[0..1].join}"
    elsif word_to_encode.length > 2
      temp = "#{letters[2..-1].join}#{letters[0..1].join}"
      encoded_word = "#{temp[1]}#{temp}"
    elsif word_to_encode.length > 1
      encoded_word = "#{letters[1]}#{word_to_encode}"
    else
      encoded_word = "#{rand_char(CharacterSets::IGNORED_CHARS)}#{word_to_encode}#{rand_char(CharacterSets::IGNORED_CHARS)}"
    end
    encoded_word = encoded_word.scan(/.{1,4}/).join(rand_char(CharacterSets::IGNORED_CHARS))

    if end_punct
      encoded_word = "#{encoded_word}#{end_punct}"
    end

    encoded_word.downcase!
    if is_word_acronym
      encoded_word = UnicodeUtils.upcase(encoded_word)
    elsif is_word_capitalized
      encoded_word = "#{UnicodeUtils.upcase(encoded_word[0])}#{encoded_word[1..-1]}"
    end
    encoded_word
  end
end
