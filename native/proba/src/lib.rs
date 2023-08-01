mod card;
mod constants;
mod deck;
mod deckcards;
mod flush;
mod hand;
mod offsets;
mod rank_hash;

use crate::card::*;
use crate::deck::*;
use crate::hand::*;

#[rustler::nif(schedule = "DirtyCpu")]
fn odds(cards: Vec<&str>, community: Vec<&str>, iterations: u32) -> Vec<Stats> {
    apply(cards, community, iterations)
}

fn apply(cards: Vec<&str>, community: Vec<&str>, iterations: u32) -> Vec<Stats> {
    let hands: Vec<Hand> = cards.iter().map(|hand| Hand::from(*hand)).collect();
    let board: Vec<Card> = community.iter().map(|card| Card::from(*card)).collect();

    let deck = &mut deck();
    withdraw(deck, &hands, &board);

    let mut cards: Vec<Vec<Card>> = vec![];
    for _ in 0..iterations {
        let community = comminity(deck, &board);
        cards.push(community);
    }

    run(&hands, &cards)
}

fn run(hands: &Vec<Hand>, decks: &Vec<Vec<Card>>) -> Vec<Stats> {
    let mut stats: Vec<Stats> = hands.iter().map(|h| Stats::new((*h).clone())).collect();
    let mut iter = decks.iter();
    loop {
        match iter.next() {
            Some(community) => {
                let ranks = hands
                    .iter()
                    .map(|h| get_rank(h, community))
                    .collect::<Vec<u16>>();

                let top = ranks.iter().max().unwrap();
                let tie: bool = ranks.iter().filter(|r| *r == top).count() > 1;

                for (index, _) in hands.iter().enumerate() {
                    stats[index].run();
                    if ranks[index] == *top {
                        if tie {
                            stats[index].tie();
                        } else {
                            stats[index].win();
                        }
                    }
                }
            }
            None => break,
        }
    }
    stats
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