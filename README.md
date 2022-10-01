# cairo-contracts

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

### For testnet/mainnet

1. Create new accounts

    Either with `starknet deploy_account --account ACCOUNT_NAME` command, or from Argent-X/Braavos wallet, and export to a json file in the following format:

        {
            "testnet": {
                "comoco_deployer": {
                    "address": "0x0111111111111111111111111111111111111111111111111111111111111111",
                    "private_key": "0xABCDEF"  # Can be in hex
                },
                "comoco_upgrader": {
                    "address": "0x0222222222222222222222222222222222222222222222222222222222222222",
                    "private_key": "12345678"  # or in decimal
                },
                "comoco_registrar": {
                    ...
                },
                "comoco_admin": {
                    ...
                },
                "comoco_receiver": {
                    ...
                },
                "comoco_agent": {
                    ...
                }
            },
            "mainnet": {
                ...
            }
        }

2. Fund the accounts

    Use the [faucet](https://faucet.goerli.starknet.io) for testnet, or other means for mainnet, to fund the following accounts:

    - comoco_deployer
    - comoco_upgrader
    - comoco_registrar
    - comoco_admin

3. Deploy the contracts

    Run the same commands as in devnet with the following extra flags:

        --network testnet|mainnet --accounts_file /path/to/accounts/file.json
