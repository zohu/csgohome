
PROGRAM := CsgojSEAWiq9Ns1hW2Y8mmvKVhcmF9vU5W6fUXjg4uDi

# [mainnet-beta, testnet, devnet, localhost]

.PHONY: keys
keys:
	@cp -a ~/.config/solana/${PROGRAM}.json target/deploy/lottery-keypair.json;\
		solana address -k target/deploy/lottery-keypair.json;\
		anchor keys sync;

.PHONY: loc
loc: keys
	@anchor build;\
		anchor deploy --provider.cluster localnet;\
		solana program show ${PROGRAM} --url localhost;

.PHONY: dev
dev: keys
	@anchor build;\
		solana account  ~/.config/solana/id.json --url devnet;\
		solana airdrop 1  --url devnet;\
		anchor deploy --provider.cluster devnet;\
		solana program show ${PROGRAM} --url devnet;

.PHONY: main
main:
	@anchor build --verifiable;\
		solana account  ~/.config/solana/id.json --url mainnet-beta;\
		anchor deploy --provider.cluster mainnet-beta;\
		solana program show ${PROGRAM} --url mainnet-beta;

sol:
	@anchor build && solana rent $$(stat -f%z target/deploy/lottery.so)

test:
	@solana-verify verify-from-repo -u "http://localhost:8899" \
		--program-id ${PROGRAM_ID} https://github.com/zohu/csgohome