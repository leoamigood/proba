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

pub fn community(deck: &Vec<Card>, board: &Vec<Card>) -> Vec<Card> {
    let mut cards = deck.choose_multiple(&mut rand::thread_rng(), 5 - board.iter().count())
        .map(|c| c.clone())
        .collect::<Vec<Card>>();

    cards.extend(board);
    cards
}

pub fn withdraw(deck: &mut Vec<Card>, hands: &Vec<Hand>, community: &Vec<Card>){
    for hand in hands {
        for card in hand.cards() {
            let index = deck.iter().position(|c| *c == card).unwrap();
            deck.remove(index);
        }
    }

    for card in community {
        let index = deck.iter().position(|c| c == card).unwrap();
        deck.remove(index);
    }
}
