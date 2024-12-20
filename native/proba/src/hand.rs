use crate::card::*;
use crate::constants::*;
use crate::deckcards::*;
use crate::flush::*;
use crate::offsets::*;
use crate::rank_hash::*;
use std::fmt;

use rustler::{Encoder, Env, Term};
use std::str::FromStr;

impl Encoder for Hand {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a> {
        (self.to_string(), self.wins.clone(), self.ties.clone()).encode(env)
    }
}

#[derive(Debug, Eq, PartialEq)]
pub struct Hand {
    cards: [Card; 2],
    wins: usize,
    ties: usize,
}

impl From<&str> for Hand {
    fn from(value: &str) -> Self {
        let mut chars = value.chars();
        let card1 = Card::new(
            Rank::from_str(&chars.next().unwrap().to_string()).unwrap(),
            Suit::from_str(&chars.next().unwrap().to_string()).unwrap(),
        );

        let card2 = Card::new(
            Rank::from_str(&chars.next().unwrap().to_string()).unwrap(),
            Suit::from_str(&chars.next().unwrap().to_string()).unwrap(),
        );

        Hand::new([card1, card2])
    }
}

impl fmt::Display for Hand {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}{}", self.cards[0], self.cards[1])
    }
}

impl Hand {
    pub fn new(cards: [Card; 2]) -> Self {
        Self { cards, wins: 0, ties: 0 }
    }
    pub fn cards(&self) -> Vec<Card> {
        self.cards.to_vec()
    }

    pub fn win(&mut self) {
        self.wins += 1;
    }

    pub fn tie(&mut self) {
        self.ties += 1;
    }
}

pub fn get_rank(hand: &Hand, community: &Vec<Card>) -> u16 {
    let weight = weight(&hand.cards()) + weight(community);
    let is_flush = FLUSH_CHECK[(weight >> FLUSH_BIT_SHIFT) as usize];

    if is_flush >= 0 {
        let suits = SUIT_KRONECKER[is_flush as usize];
        FLUSH_RANKS[suits[hand.cards[0].value]
            | suits[hand.cards[1].value]
            | suits[community[0].value]
            | suits[community[1].value]
            | suits[community[2].value]
            | suits[community[3].value]
            | suits[community[4].value]]
    } else {
        let hash = FACE_BIT_MASK & (31 * weight);

        RANK_HASH[OFFSETS[(hash >> RANK_OFFSET_SHIFT) as usize] + (hash & RANK_HASH_MOD) as usize]
    }
}
