# starknet-contracts

Smart contracts for Comoco Licensor in StarkNet

## Installation

### Setup a virtual environment

    python3 -m venv .venv
    source .venv/bin/activate

or

    conda create -n blockchain python=3.9
    conda activate blockchain

### Install the dependencies

    pip install -r requirements.txt

## Development

### Compile the contracts

    make build

### Test the contracts

    make test

## Deployment

### For local devnet

1. Launch the local devnet

        nile node

2. Export the predeployed accounts

        make prep  # Accounts are exported to the accounts.json file

3. Deploy the TokenRegistry contract

        python scripts/deploy_registry.py  # Find REGISTRY_ADDRESS in the output deployments.txt file after "Registry Contract"

4. Deploy the DerivativeToken contracts

        python scripts/deploy_tokens.py --registry_address REGISTRY_ADDRESS  # Results are appended to the deployments.txt file

### For live networks

1. Create new accounts

    Either with `starknet new_account --account ACCOUNT_NAME` followed by `starknet deploy_account --account ACCOUNT_NAME` command, or from Argent-X/Braavos wallet, create and export accounts to a json file in the following format:

        {
            "testnet": {
                "comoco_dev": {
                    "address": "0x0111111111111111111111111111111111111111111111111111111111111111",
                    "private_key": "0xABCDEF"  # Can be in hex
                },
                "comoco_admin": {
                    "address": "0x0222222222222222222222222222222222222222222222222222222222222222",
                    "private_key": "12345678"  # or in decimal
                },
                "comoco_bank": {
                    ...
                }
            },
            "testnet2": {
                ...
            },
            "mainnet": {
                ...
            }
        }

2. Fund the accounts

    Use the [faucet](https://faucet.goerli.starknet.io) for testnet, [ETH bridge](https://goerli.etherscan.io/address/0xaea4513378eb6023cf9ce730a26255d0e3f075b9#writeProxyContract) for testnet2, or other means for mainnet, to fund the accounts. More funds are needed for `comoco_admin` account.

3. Deploy the contracts

    Run the same commands as in devnet with the following extra flags:

        --network testnet|testnet2|mainnet
        --accounts_file /path/to/accounts/file.json
        [--token ...]  # Obtained from application for alpha-mainnet deployment
