#![allow(unexpected_cfgs)]

use anchor_lang::prelude::*;
use blake3;

declare_id!("CsgojSEAWiq9Ns1hW2Y8mmvKVhcmF9vU5W6fUXjg4uDi");

const MAX_RANDOM:u64 = 100000;

// 使用[拒絕抽樣法]消除取模偏誤，確保產生的隨機數在1-100000之間均勻分佈無偏誤。
// Use [rejection sampling] to eliminate modulo bias and ensure that the generated random numbers are uniformly distributed between 1 and 100,000 without bias.
const MAX_SAFE: u64 = u64::MAX - (u64::MAX % MAX_RANDOM);
fn rejection_sampling(raw: u64) -> Option<u32> {
    if raw < MAX_SAFE {
        Some((raw % MAX_RANDOM) as u32 + 1)
    } else {
        None
    }
}

#[program]
pub mod lottery {
    use super::*;

    pub fn generate_random<'a>(
        ctx: Context<Random>,
        oid: String,
        latest: String,
        count: u8,
    ) -> Result<()> {
        // 添加訂單ID作為雜湊熵源
        // Incorporate the order ID as an entropy source for hashing
        let order_bytes = oid.as_bytes();
        let count_bytes = count.to_le_bytes();
        // 添加時間作為雜湊熵源
        // Add time as a hash entropy source
        let clock = Clock::get()?;
        let slot_bytes = clock.slot.to_le_bytes();
        let timestamp_bytes = clock.unix_timestamp.to_le_bytes();
        // 添加玩家和簽名者作為熵源
        // Add the player and signer as an entropy source
        let player_bytes = ctx.accounts.player.key().to_bytes();
        let signer_bytes = ctx.accounts.signer.key().to_bytes();
        // 使用最后一个区块作為隨機的熵源，防止預測
        // Use the last block as a random entropy source to prevent prediction
        let latest_block_bytes = latest.as_bytes();

        let mut data = Vec::with_capacity(
            order_bytes.len() +
                count_bytes.len() +
                slot_bytes.len() +
                timestamp_bytes.len() +
                player_bytes.len() +
                signer_bytes.len() +
                latest_block_bytes.len()
        );
        data.extend_from_slice(order_bytes);
        data.extend_from_slice(&count_bytes);
        data.extend_from_slice(&slot_bytes);
        data.extend_from_slice(&timestamp_bytes);
        data.extend_from_slice(&player_bytes);
        data.extend_from_slice(&signer_bytes);
        data.extend_from_slice(&latest_block_bytes);

        // 第一輪雜湊
        // First-round hashing
        let mut hasher = blake3::Hasher::new();
        hasher.update(&data);
        let intermediate = hasher.finalize();

        let mut arr: Vec<u32> = Vec::with_capacity(count as usize);
        let mut iteration_count:i32 = 0;
        while arr.len() < count as usize {
            iteration_count += 1;
            // 第二輪雜湊，消除熵源關聯性
            // Second-round hashing to eliminate entropy source correlation
            hasher.reset();
            hasher.update(intermediate.as_bytes());
            hasher.update(&iteration_count.to_le_bytes());
            let batch_hash = hasher.finalize();
            let bytes = batch_hash.as_bytes()[..8].try_into().unwrap();
            let raw = u64::from_le_bytes(bytes);
            match rejection_sampling(raw) {
                Some(random_value) => {
                    arr.push(random_value);
                }
                None => {
                    break
                }
            }
        }

        msg!("ID={} RANDOMS={:?}", oid, arr);

        Ok(())
    }
}

#[derive(Accounts)]
pub struct Random<'info> {
    #[account(constraint = signer.is_signer @ Error::InvalidSigner,)]
    pub player: Signer<'info>,
    #[account(constraint = signer.is_signer @ Error::InvalidSigner,)]
    pub signer: Signer<'info>,
    #[account(mut,constraint = payer.is_signer @ Error::InvalidSigner,)]
    pub payer: Signer<'info>,
    pub clock: Sysvar<'info, Clock>,
    pub system_program: Program<'info, System>,
}

#[error_code]
pub enum Error {
    #[msg("Not signed")]
    InvalidSigner,
}