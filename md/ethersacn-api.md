# Etherscan API:

## Get ERC20-Token Account Balance for TokenContractAddress:

https://docs.etherscan.io/api-endpoints/tokens#get-erc20-token-account-balance-for-tokencontractaddress

## Get Token Info by ContractAddress:(PRO)

https://docs.etherscan.io/api-endpoints/tokens#get-token-info-by-contractaddress

## Get a list of 'ERC721 - Token Transfer Events' by Address:

https://docs.etherscan.io/api-endpoints/accounts#get-a-list-of-erc721-token-transfer-events-by-address

Mint: from = "0x0000000000000000000000000000000000000000";

https://api.etherscan.io/api?module=account&action=tokennfttx&contractaddress=0x025d7D6df01074065B8Cfc9cb78456d417BBc6b7&address=0x0000000000000000000000000000000000000000&page=1&offset=10000&startblock=0&endblock=latest&sort=asc&apikey=YourApiKeyToken

## Get Event Logs by Address filtered by Topics:

https://docs.etherscan.io/api-endpoints/logs#get-event-logs-by-address-filtered-by-topics

Transfer (index_topic_1 address from, index_topic_2 address to, index_topic_3 uint256 tokenId)
Topics0:0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

Offset size must be less than or equal to 10000

https://api.etherscan.io/api?module=logs&action=getLogs&fromBlock=0&toBlock=latest&address=0x19811DaD1dFAbd8D27Dae13881a39Af5e9D1BfBa&topic0=0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef&topic0_1_opr=and&topic1=0x0000000000000000000000000000000000000000000000000000000000000000&page=1&offset=10000&apikey=YourApiKeyToken
