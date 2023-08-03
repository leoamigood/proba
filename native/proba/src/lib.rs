mod card;
mod constants;
mod deck;
mod deckcards;
mod flush;
mod hand;
mod offsets;
mod rank_hash;

use itertools::Itertools;

use crate::card::*;
use crate::deck::*;
use crate::hand::*;

#[rustler::nif(schedule = "DirtyCpu")]
fn odds(cards: Vec<&str>, community: Vec<&str>, iterations: usize) -> Vec<Hand> {
    apply(cards, community, iterations)
}

fn apply(hands: Vec<&str>, board: Vec<&str>, iterations: usize) -> Vec<Hand> {
    let mut hands: Vec<Hand> = hands.iter().map(|hand| Hand::from(*hand)).collect();
    let board: Vec<Card> = board.iter().map(|card| Card::from(*card)).collect();

    let deck = &mut deck();
    withdraw(deck, &hands, &board);

    for _ in 0..iterations {
        let winners: Vec<usize> = run(&hands, &community(deck, &board));
        match winners[..] {
            [index] => { hands[index].win(); }
            _ => for index in winners { hands[index].tie() }
        }
    }

    hands
}

fn run(hands: &Vec<Hand>, community: &Vec<Card>) -> Vec<usize> {
    let results: Vec<(usize, u16)> = hands
        .iter()
        .enumerate()
        .map(|(index, hand)| (index, get_rank(hand, &community)))
        .collect();

    results.iter()
        .max_set_by(|(_, rank1), (_, rank2)| rank1.cmp(rank2)).iter()
        .map(|(index, _)| *index)
        .collect()
}

rustler::init!("Elixir.Proba.Native", [odds]);

#[cfg(test)]
mod tests {
    use crate::{apply};

    #[test]
    fn test_odds() {
        apply(vec!["AhKc", "8h8d"], vec!["As", "Ac", "Ad"], 1000);
    }
}