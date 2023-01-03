import argparse
import asyncio
import os

from starknet_py.contract import Contract, DeclareResult
from starknet_py.net import AccountClient
from starkware.starknet.public.abi import AbiType
from starkware.starknet.public.abi import get_selector_from_name

from common import (
    MAX_FEE,
    create_clients,
    declare_contract,
    deploy_contract,
    load_abi,
    load_compiled_contract,
    parse_arguments,
    save_hash
)


COMPILED_PROXY_FILE = os.path.join(
    'artifacts', 'Proxy.json'
)
COMPILED_TOKEN_FILE = os.path.join(
    'artifacts', 'DerivativeToken.json'
)

REGISTRY_ABI_FILE = os.path.join(
    'artifacts', 'abis', 'TokenRegistry.json'
)
TOKEN_ABI_FILE = os.path.join(
    'artifacts', 'abis', 'DerivativeToken.json'
)

INITIALIZER_SELECTOR = get_selector_from_name('initializer')

TOKENS_CONFIG = {
    'BAYC': {
        'name': 'Bored Ape Yacht Club',
        'symbol': 'BAYC',
        'primary_addr': 0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d,
        'allow_transfer': 1,
        'drag_along': 1,
        'royalties': 500
    },
    'BAYC_3DS1': {
        'name': '3D BAYC (S1)',
        'symbol': 'BAYC_3DS1',
        'royalties': 500
    },
    'BAYC_STS1': {
        'name': 'Stylized BAYC (S1)',
        'symbol': 'BAYC_STS1',
        'royalties': 500
    },
    'BAYC_STS2': {
        'name': 'Stylized BAYC (S2)',
        'symbol': 'BAYC_STS2',
        'royalties': 500
    },
    'DOODLE': {
        'name': 'Doodles',
        'symbol': 'DOODLE',
        'primary_addr': 0x8a90cab2b38dba80c64b7734e58ee1db38b8992e,
        'allow_transfer': 2,
        'drag_along': 1,
        'royalties': 500
    },
    'DOODLE_3DS1': {
        'name': '3D Doodles (S1)',
        'symbol': 'DOODLE_3DS1',
        'royalties': 500
    },
    'DOODLE_STS1': {
        'name': 'Stylized Doodles (S1)',
        'symbol': 'DOODLE_STS1',
        'royalties': 500
    },
    'DOODLE_STS2': {
        'name': 'Stylized Doodles (S2)',
        'symbol': 'DOODLE_STS2',
        'royalties': 500
    }
}


async def deploy_token_contract(
    proxy_declare_result: DeclareResult,
    token_abi: AbiType,
    token_class_hash: int,
    registry_contract_address: int,
    account_clients: dict[str, AccountClient],
    config: dict
) -> Contract:
    token_deploy_result = await deploy_contract(
        proxy_declare_result,
        [
            token_class_hash,
            INITIALIZER_SELECTOR,
            [
                account_clients['comoco_dev'].address,
                config['name'],
                config['symbol'],
                account_clients['comoco_admin'].address,
                registry_contract_address
            ]
        ]
    )
    return Contract(
        token_deploy_result.deployed_contract.address,
        token_abi,
        account_clients['comoco_admin']
    )


async def setup_token_contract(
    account_clients: dict[str, AccountClient],
    registry_contract: Contract,
    token_contract: Contract,
    config: dict
):
    if 'primary_addr' in config:
        invocation = await registry_contract.functions['setPrimaryTokenAddress'].invoke(
            token_contract.address, config['primary_addr'], max_fee=MAX_FEE)
        await invocation.wait_for_acceptance()

    calls = []
    if 'allow_transfer' in config:
        calls.append(token_contract.functions['setCollectionSettings'].prepare(
            'allow_transfer', config['allow_transfer']))
    if 'drag_along' in config:
        calls.append(token_contract.functions['setCollectionSettings'].prepare(
            'drag_along', config['drag_along']))
    if 'royalties' in config:
        calls.append(token_contract.functions['setCollectionArraySettings'].prepare(
            'royalties', [account_clients['comoco_bank'].address, config['royalties']]))
    if calls:
        resp = await account_clients['comoco_admin'].execute(calls=calls, max_fee=MAX_FEE * len(calls))
        await account_clients['comoco_admin'].wait_for_tx(resp.transaction_hash)


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--registry_address', dest='registry_address', required=True,
        help='The address of the deployed TokenRegistry contract'
    )
    args = parse_arguments(parser)

    _, account_clients = create_clients(args)
    registry_contract = Contract(
        args.registry_address,
        load_abi(REGISTRY_ABI_FILE),
        account_clients['comoco_admin']
    )

    print("Declaring DerivativeToken class...")
    token_declare_result = await declare_contract(
        account_clients['comoco_dev'],
        load_compiled_contract(COMPILED_TOKEN_FILE)
    )
    save_hash('Token Class', token_declare_result.class_hash)

    print("Declaring Proxy class...")
    proxy_declare_result = await declare_contract(
        account_clients['comoco_dev'],
        load_compiled_contract(COMPILED_PROXY_FILE)
    )
    token_abi = load_abi(TOKEN_ABI_FILE)

    for token, config in TOKENS_CONFIG.items():
        print(f"Deploying DerivativeToken contract for {token}...")
        token_contract = await deploy_token_contract(
            proxy_declare_result, token_abi,
            token_declare_result.class_hash, registry_contract.address,
            account_clients, config
        )
        save_hash(token + ' Contract', token_contract.address)

        print(f"Setting up DerivativeToken contract for {token}...")
        await setup_token_contract(
            account_clients, registry_contract, token_contract, config
        )


if __name__ == '__main__':
    asyncio.run(main())
