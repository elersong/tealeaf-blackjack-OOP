require 'pry'
# ============================================================================== Pseudocode Algorithm

# 1. Prepare the decks. Generate 52 unique cards. Repeat for cases with more than
#    1 deck. Shuffle all the cards.
# 2. Allow user to place bets, knowing that wins pay 1:1 and blackjack pays 2:1 
#    on one deck and 3:1 on more than one deck.
# 3. Deal 2 cards to each player. 
# 4. Allow player to either hit (be dealt another card) or stay (no more cards)
#    until all players are either "busted" or satisfied with their position. See
#    rules of card addition.
# 5. Dealer gets two cards and must hit until a total of at least 17. Dealer can
#    choose to stay or hit past 17, but aims for the highest hand without breaking
#    a total card sum of 21. 
# 6. When dealer is satisfied, any player with a smaller card total loses their
#    entire bet. Any player with equal sum neither loses nor gains ("push"). Any
#    player with a greater sum wins 1x more than their bet. Any player with 
#    blackjack wins 2x or 3x more than their bet depending on the number of decks.
# 7. Repeat steps 3 - 6 until the deck(s) is empty. At which time, repeat step 1.
# 8. Game is over when the player either has no more money to bet or walks away.

# Card addition rules
# - An ace is worth either 1 or 11, whichever gets closer to 21 without going over
# - Face cards (K, Q, J) are worth 10
# - All number cards are worth their number, regardless of suit

# ============================================================================== Class Definitions

# Class nouns: Dealer, Player, GameEngine, Deck, Card, Hand, AI
# Class verbs: shuffle, deal, hit, stay, display, update, award, bet, reset

module Thinkable
end

class Dealer
  attr_accessor :hand, :total
  
  def initialize(game)
    @hand = []
    @game_obj = game
    @total = 0
  end
  
  def dealers_turn
    while (Deck.total_of_hand(@hand) < 21) && (Deck.total_of_hand(@hand) > 17)
      break if Deck.total_of_hand @hand == 21 #blackjack
      if Deck.total_of_hand(@hand) < 17
        @game_obj.game_deck.deal(self)
      else
        [true,false].sample ? @game_obj.game_deck.deal(self) : break
      end
    end
    winnings_to_winners
  end
  
  private
  
  def winnings_to_winners
    @game_obj.players.each do |player|
      if (Deck.total_of_hand player.hand) == (Deck.total_of_hand @hand)
        player.wallet += player.bet # 0 net loss on bet
        
      elsif (Deck.total_of_hand player.hand) == 21 && @game_obj.number_of_decks > 1
        player.wallet += (player.bet * 4) # 3:1 payout
        
      elsif (Deck.total_of_hand player.hand) == 21 
        player.wallet += (player.bet * 3) # 2:1 payout
        
      elsif (Deck.total_of_hand player.hand) > (Deck.total_of_hand @hand) && (Deck.total_of_hand player.hand) < 99
        player.wallet += (player.bet * 2) # 1:1 payout
      
      elsif (Deck.total_of_hand player.hand) > 21 
        player.wallet += (player.bet * 2) # 1:1 payout
      end
    end
  end
  
end

class Deck
  attr_accessor :array, :number_of_decks
  
  def initialize(number_of_decks) # <= Integer
    suits = ["♠","♣","♥","♦"]
    values = %w(1 2 3 4 5 6 7 8 9 J Q K A)
    deck = []
    
    suits.each do |suit|
      values.each do |value|
        deck << "[#{suit} #{value}]"
      end
    end
    
    @array = (deck *= number_of_decks).shuffle
    @number_of_decks = number_of_decks
  end
  
  def deal(player) # <= Obj
    if self.array.count <= 3
      self.array << Deck.new(self.number_of_decks)
    end
    
    how_many_cards = player.hand.count < 2 ? 2 : 1
    how_many_cards.times do
      card = self.array.pop
      player.hand << card
    end
    
    player.total = Deck.total_of_hand(player.hand)
  end
  
  def self.total_with_aces(subtotal, number_of_aces_in_hand) # <= Integer, Integer
  
    return 100 if (subtotal + number_of_aces_in_hand > 21) # so any total greater than 100 means busted
    
    case number_of_aces_in_hand
      when 0
        total = subtotal
      when 1
        total = (subtotal + 11 > 21) ? (subtotal + 1) : (subtotal + 11)
      when 2
        total = (subtotal + 12 > 21) ? (subtotal + 2) : (subtotal + 12)
      when 3
        total = (subtotal + 13 > 21) ? (subtotal + 3) : (subtotal + 13)
      when 4
        total = (subtotal + 14 > 21) ? (subtotal + 4) : (subtotal + 14)
    end
    total
  end # => Integer
  
  def self.total_of_hand(hand) # <= Array
    return 0 if hand == "BUSTED"
    total = 0
    aces = ["[♠ A]","[♣ A]","[♥ A]","[♦ A]"]
    indices_of_aces = hand.each_index.select { |i| aces.include? hand[i] }
    
    hand.each do |card|
      face = card.split("")[3]
      value = face.to_i if %w(1 2 3 4 5 6 7 8 9).include? face
      value = 10 if %w(Q K J).include? face
      value = 0 if face == "A"
      total += value
    end
    total = total_with_aces(total, indices_of_aces.count)
    return total
  end # => Integer
  
end

class Game
  attr_accessor :number_of_decks, :players, :game_deck, :dealer
  
  def initialize 
    @number_of_decks = (Game.prompt "Choose Difficulty: 1 (easy) - 5 (hard)").to_i
    
    @players = []
    @players << Player.new(self, (Game.prompt "What is your name?"))
    rand(4).times do
      @players << Player.new(self)
    end
    
    @game_deck = Deck.new @number_of_decks
    
    @dealer = Dealer.new(self)
  end
  
  def display_header
    system("clear")
    puts "Let's Play BlackJack"
    puts "===================="
    puts
  end
  
  def format_player_status(player)
    hand_string = ""
    hand_array = player.hand
    
    hand_array.each do |card|
      hand_string << "#{card} "
    end
    
    hand_total = (Deck.total_of_hand hand_array)[0]
    hand_total = "BUSTED" if hand_total > 21
    hand_total = "BLACKJACK" if hand_total == 21
    
    puts "#{player.name} ($#{player.wallet}) | Bet $#{player.bet}"
    puts "-----------------------"
    puts "#{hand_string} (#{hand_total})"
    puts ""
  end
  
  def self.prompt(msg) # <= String
    say msg
    gets.chomp
  end # => String
  
  def self.say(msg) # <= String
    puts " => #{msg}"
  end # => nil
  
  def update_playing_table
    display_header
    @players.each do |player|
      format_player_status player
    end
    
    dealer_hand_string = ""
    @dealer.hand.each do |card|
      dealer_hand_string << "#{card} "
    end
    
    dealer_bust_status = (Deck.total_of_hand(@dealer.hand) > 21) ? "BUSTED" : (Deck.total_of_hand(@dealer.hand))
    
    puts ""
    puts "DEALER: #{dealer_hand_string} (#{dealer_bust_status})"
    puts ""
  end 
  
  def clear_hands
    @players.each do |player|
      player.hand = []
    end
    @dealer.hand = []
  end
  
  def deal_first_two_cards
    @players.each do |player|
      self.game_deck.deal player
    end
  end
  
end

class Player
  include Thinkable
  
  attr_accessor :wallet, :hand, :bet, :total
  attr_reader :name, :game_obj
  
  def initialize(game, name = nil)
    @name = name.nil? ? File.readlines("names.txt").sample.strip.capitalize : name
    @wallet = 100
    @hand = []
    @bet = 0
    @total = 0
    @game_obj = game
  end
  
  def place_bet(type = "")
    if type == :human
      @bet = (Game.prompt "How much do you want to bet? (minimum of 1)").to_i.abs
    else
      ai_max_bet = (@wallet/4) # 25% of total holdings
      @bet = rand(ai_max_bet) #pick randomly up to the max bet... feelin lucky, I guess
    end
    @wallet -= @bet
  end
  
  def hit
    @game_obj.game_deck.deal self
  end
  
end


# ============================================================================== Game Logic
g = Game.new
p = g.players[0]
d = g.dealer
binding.pry