pub(crate) const TWO: u32 = 0;
pub(crate) const THREE: u32 = 1;
pub(crate) const FOUR: u32 = 5;
pub(crate) const FIVE: u32 = 22;
pub(crate) const SIX: u32 = 98;
pub(crate) const SEVEN: u32 = 453;
pub(crate) const EIGHT: u32 = 2031;
pub(crate) const NINE: u32 = 8698;
pub(crate) const TEN: u32 = 22854;
pub(crate) const JACK: u32 = 83661;
pub(crate) const QUEEN: u32 = 262349;
pub(crate) const KING: u32 = 636345;
pub(crate) const ACE: u32 = 1479181;

pub(crate) const SPADES: u32 = 0;
pub(crate) const HEARTS: u32 = 1;
pub(crate) const DIAMONDS: u32 = 8;
pub(crate) const CLUBS: u32 = 57;

pub const TWO_FLUSH: usize = 1;
pub const THREE_FLUSH: usize = TWO_FLUSH << 1;
pub const FOUR_FLUSH: usize = THREE_FLUSH << 1;
pub const FIVE_FLUSH: usize = FOUR_FLUSH << 1;
pub const SIX_FLUSH: usize = FIVE_FLUSH << 1;
pub const SEVEN_FLUSH: usize = SIX_FLUSH << 1;
pub const EIGHT_FLUSH: usize = SEVEN_FLUSH << 1;
pub const NINE_FLUSH: usize = EIGHT_FLUSH << 1;
pub const TEN_FLUSH: usize = NINE_FLUSH << 1;
pub const JACK_FLUSH: usize = TEN_FLUSH << 1;
pub const QUEEN_FLUSH: usize = JACK_FLUSH << 1;
pub const KING_FLUSH: usize = QUEEN_FLUSH << 1;
pub const ACE_FLUSH: usize = KING_FLUSH << 1;

pub const RANK_OFFSET_SHIFT: u32 = 9;
pub const RANK_HASH_MOD: u64 = (1 << RANK_OFFSET_SHIFT) - 1;

// Bit masks
pub const FLUSH_BIT_SHIFT: u8 = 23;
pub const FACE_BIT_MASK: u64 = (1 << FLUSH_BIT_SHIFT) - 1;
