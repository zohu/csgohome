

define set_cluster
solana config set --url $1
endef

PROGRAM_ID := CsgojSEAWiq9Ns1hW2Y8mmvKVhcmF9vU5W6fUXjg4uDi

.PHONY: keypair
keypair:
	@cp -a ~/.config/solana/${PROGRAM_ID}.json target/deploy/csgohome-keypair.json
	@solana address -k target/deploy/csgohome-keypair.json

.PHONY: build
build: keypair
	@anchor build --verifiable

.PHONY: deploy-loc
deploy-loc: build
	@$(call set_cluster,"http://localhost:8899");\
	anchor deploy --provider.cluster localnet;\
	solana program show ${PROGRAM_ID};\
	anchor verify ${PROGRAM_ID} --provider.cluster localnet;

.PHONY: deploy-dev
deploy-dev: build
	@$(call set_cluster,"https://api.devnet.solana.com");\
	solana account  ~/.config/solana/id.json;\
	solana airdrop 5;\
	anchor deploy --provider.cluster devnet;\
	solana program show ${PROGRAM_ID};\
	anchor verify ${PROGRAM_ID} --provider.cluster devnet;

.PHONY: upgrade-dev
upgrade-dev: build
	@$(call set_cluster,"https://api.devnet.solana.com");\
	solana account  ~/.config/solana/id.json;\
	anchor upgrade target/deploy/lottery.so \
		--program-id ${PROGRAM_ID} \
		--provider.cluster devnet;\
	solana program show ${PROGRAM_ID};\
	anchor verify ${PROGRAM_ID} --provider.cluster devnet;

.PHONY: deploy-main
deploy-main: build
	@$(call set_cluster,"https://api.mainnet-beta.solana.com");\
	solana account  ~/.config/solana/id.json;\
	anchor deploy --provider.cluster mainnet;\
	solana program show ${PROGRAM_ID};\
	anchor verify ${PROGRAM_ID} --provider.cluster mainnet;

.PHONY: upgrade-main
upgrade-main: build
	@$(call set_cluster,"https://api.mainnet-beta.solana.com");\
	solana account  ~/.config/solana/id.json;\
	anchor upgrade target/deploy/lottery.so \
		--program-id ${PROGRAM_ID} \
		--provider.cluster mainnet;\
	solana program show ${PROGRAM_ID};\
	anchor verify ${PROGRAM_ID} --provider.cluster mainnet;

sol:
	@solana rent $$(stat -f%z target/deploy/lottery.so)