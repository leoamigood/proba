use crate::card::Suit::*;
use crate::card::*;
use crate::hand::Hand;
use rand::seq::SliceRandom;

pub fn deck() -> Vec<Card> {
    [].iter()
        .chain(Card::set(Spades).iter())
        .chain(Card::set(Hearts).iter())
        .chain(Card::set(Diamonds).iter())
        .chain(Card::set(Clubs).iter())
        .map(|card| card.clone())
        .collect()
}

pub fn comminity(deck: &Vec<Card>) -> Vec<Card> {
    deck.choose_multiple(&mut rand::thread_rng(), 5)
        .map(|c| c.clone())
        .collect::<Vec<Card>>()
}

pub fn withdraw<'a>(deck: &'a mut Vec<Card>, hands: &Vec<Hand>) -> &'a Vec<Card> {
    for hand in hands {
        for card in hand.cards() {
            let index = deck.iter().position(|x| *x == card).unwrap();
            deck.remove(index);
        }
    }
    deck
}
