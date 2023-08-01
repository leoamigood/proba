use std::fmt;
use std::str::FromStr;
use strum::IntoEnumIterator;
use strum_macros::Display;
use strum_macros::EnumIter;
use strum_macros::EnumString;

use crate::constants::*;

#[derive(Debug, Clone, Copy, Eq, PartialEq)]
pub struct Card {
    rank: Rank,
    suit: Suit,
    pub value: usize,
    weight: u32,
}

impl From<&str> for Card {
    fn from(value: &str) -> Self {
        let mut chars = value.chars();
        Card::new(
            Rank::from_str(&chars.next().unwrap().to_string()).unwrap(),
            Suit::from_str(&chars.next().unwrap().to_string()).unwrap(),
        )
    }
}

impl fmt::Display for Card {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}{}", self.rank.to_string(), self.suit.to_string())
    }
}

impl Card {
    pub fn new(rank: Rank, suit: Suit) -> Self {
        Self {
            rank,
            suit,
            value: rank as usize * 4 + suit as usize,
            weight: (suit_value(suit) << FLUSH_BIT_SHIFT) + rank_value(rank),
        }
    }
}

impl Card {
    pub fn set(suit: Suit) -> Vec<Card> {
        Rank::iter().map(|rank| Card::new(rank, suit)).collect()
    }
}

pub fn weight(hand: &Vec<Card>) -> u64 {
    hand.iter().fold(0, |acc, card| acc + card.weight) as u64
}

pub fn suit_value(suit: Suit) -> u32 {
    match suit {
        Suit::Spades => SPADES,
        Suit::Hearts => HEARTS,
        Suit::Diamonds => DIAMONDS,
        Suit::Clubs => CLUBS,
    }
}

pub fn rank_value(rank: Rank) -> u32 {
    match rank {
        Rank::Ace => ACE,
        Rank::King => KING,
        Rank::Queen => QUEEN,
        Rank::Jack => JACK,
        Rank::Ten => TEN,
        Rank::Nine => NINE,
        Rank::Eight => EIGHT,
        Rank::Seven => SEVEN,
        Rank::Six => SIX,
        Rank::Five => FIVE,
        Rank::Four => FOUR,
        Rank::Three => THREE,
        Rank::Two => TWO,
    }
}

#[derive(Display, EnumString, Debug, EnumIter, Clone, Copy, Eq, PartialEq)]
pub enum Rank {
    #[strum(serialize = "A")]
    Ace = 0,
    #[strum(serialize = "K")]
    King = 1,
    #[strum(serialize = "Q")]
    Queen = 2,
    #[strum(serialize = "J")]
    Jack = 3,
    #[strum(serialize = "T")]
    Ten = 4,
    #[strum(serialize = "9")]
    Nine = 5,
    #[strum(serialize = "8")]
    Eight = 6,
    #[strum(serialize = "7")]
    Seven = 7,
    #[strum(serialize = "6")]
    Six = 8,
    #[strum(serialize = "5")]
    Five = 9,
    #[strum(serialize = "4")]
    Four = 10,
    #[strum(serialize = "3")]
    Three = 11,
    #[strum(serialize = "2")]
    Two = 12,
}

#[derive(Display, EnumString, Debug, EnumIter, Clone, Copy, Eq, PartialEq)]
pub enum Suit {
    #[strum(serialize = "♠", serialize = "s")]
    Spades = 0,
    #[strum(serialize = "♥", serialize = "h")]
    Hearts = 1,
    #[strum(serialize = "♦", serialize = "d")]
    Diamonds = 2,
    #[strum(serialize = "♣", serialize = "c")]
    Clubs = 3,
}
