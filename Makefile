

define set_cluster
solana config set --url $1
endef

PROGRAM_ID := CsgojSEAWiq9Ns1hW2Y8mmvKVhcmF9vU5W6fUXjg4uDi

.PHONY: keypair
keypair:
	@cp -a ~/.config/solana/${PROGRAM_ID}.json target/deploy/csgohome-keypair.json
	@solana address -k target/deploy/csgohome-keypair.json

.PHONY: build
build:
	@anchor build --verifiable

.PHONY: verify
verify:
	@anchor verify ${PROGRAM_ID} \
		--verifier solana-verify \
		--github-repo https://github.com/zohu/csgohome;\
	solana-verify status

.PHONY: deploy-loc
deploy-loc: build
	@$(call set_cluster,"http://localhost:8899");\
	anchor deploy --provider.cluster localnet;\
	solana program show ${PROGRAM_ID};
	@verify

.PHONY: deploy-dev
deploy-dev: build
	@$(call set_cluster,"https://api.devnet.solana.com");\
	solana account  ~/.config/solana/id.json;\
	solana airdrop 5;\
	anchor deploy --provider.cluster devnet;\
	solana program show ${PROGRAM_ID};
	@verify

.PHONY: upgrade-dev
upgrade-dev: build
	@$(call set_cluster,"https://api.devnet.solana.com");\
	solana account  ~/.config/solana/id.json;\
	anchor upgrade target/deploy/lottery.so \
		--program-id ${PROGRAM_ID} \
		--provider.cluster devnet;\
	solana program show ${PROGRAM_ID};
	@verify

.PHONY: deploy-main
deploy-main: build
	@$(call set_cluster,"https://api.mainnet-beta.solana.com");\
	solana account  ~/.config/solana/id.json;\
	anchor deploy --provider.cluster mainnet;\
	solana program show ${PROGRAM_ID};
	@verify

.PHONY: upgrade-dev
upgrade-dev: build
	@$(call set_cluster,"https://api.mainnet-beta.solana.com");\
	solana account  ~/.config/solana/id.json;\
	anchor upgrade target/deploy/lottery.so \
		--program-id ${PROGRAM_ID} \
		--provider.cluster mainnet;\
	solana program show ${PROGRAM_ID};
	@verify