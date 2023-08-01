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

#[rustler::nif]
fn odds(input: Vec<&str>, iterations: u32) -> Vec<Stats> {
    let hands: Vec<Hand> = input.iter().map(|cards| Hand::from(*cards)).collect();

    let deck = &mut deck();
    let deck = withdraw(deck, &hands);

    let mut cards: Vec<Vec<Card>> = vec![];
    for _ in 0..iterations {
        let community = comminity(deck);
        cards.push(community);
    }

    run(&hands, &cards)
}

fn run(hands: &Vec<Hand>, comminity: &Vec<Vec<Card>>) -> Vec<Stats> {
    let mut stats: Vec<Stats> = hands.iter().map(|h| Stats::new((*h).clone())).collect();
    let mut iter = comminity.iter();
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
