# cairo-contracts

Smart contracts for Comoco Licensor in StarkNet

## Installation

### Setup a virtual environment

```
python3 -m venv .venv
source .venv/bin/activate
```

or

```
conda create -n blockchain python=3.9
conda activate blockchain
```

### Install the dependencies

```
pip install -r requirements.txt
```

## Development

### Compile the contracts

```
make build
```

### Test the contracts

```
make test
```

## Deployment

### Deploy to the local devnet

#### Launch the local devnet

```
nile node
```

#### Export the predeployed accounts

```
make prep  # Accounts are exported to the accounts.json file
```

#### Deploy the TokenRegistry contract

```
python scripts/deploy_registry.py  # Find REGISTRY_ADDRESS in the output deployments.txt file
```

#### Deploy the DerivativeToken contracts

```
python scripts/deploy_tokens.py --registry_address REGISTRY_ADDRESS  # Results are appended to the deployments.txt file
```

### Deploy to the testnet/mainnet

#### Manage accounts through a wallet

Create accounts using Argent-X or Braavos wallet, and export to a json file in the following format:

```
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
```

#### Fund the accounts

Use the [faucet](https://faucet.goerli.starknet.io) for testnet, or other means for mainnet, to fund the following accounts:

- comoco_deployer
- comoco_upgrader
- comoco_registrar
- comoco_admin


#### Deploy the contracts

Run the same commands as in devnet with the following flags:

```
--network testnet|mainnet
--accounts_file /path/to/accounts/file.json
```
