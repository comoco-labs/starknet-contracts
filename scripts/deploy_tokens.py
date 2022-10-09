import argparse
import asyncio
import os

from starknet_py.contract import Contract
from starknet_py.net import AccountClient
from starknet_py.net.gateway_client import GatewayClient
from starkware.starknet.public.abi import AbiType
from starkware.starknet.public.abi import get_selector_from_name

from common import (
    MAX_FEE,
    compile_contract,
    create_clients,
    declare_contract,
    deploy_contract,
    get_abi,
    parse_arguments,
    write_contract
)


PROXY_FILE = os.path.join(
    'contracts', 'proxy', 'Proxy.cairo'
)
REGISTRY_FILE = os.path.join(
    'contracts', 'registry', 'TokenRegistry.cairo'
)
TOKEN_FILE = os.path.join(
    'contracts', 'token', 'DerivativeToken.cairo'
)
LICENSE_FILE = os.path.join(
    'contracts', 'license', 'DerivativeLicense.cairo'
)

INITIALIZER_SELECTOR = get_selector_from_name('initializer')

TOKENS_CONFIG = {
    'BAYC': {
        'name': 'Bored Ape Yacht Club',
        'symbol': 'BAYC',
        'l1_addr': 0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d,
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
        'l1_addr': 0x8a90cab2b38dba80c64b7734e58ee1db38b8992e,
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
    gateway_client: GatewayClient,
    account_clients: dict[str, AccountClient],
    compiled_proxy_contract: str,
    token_abi: AbiType,
    token_class_hash: int,
    license_class_hash: int,
    registry_contract_address: int,
    config: dict
) -> Contract:
    token_contract_address = await deploy_contract(
        gateway_client,
        compiled_proxy_contract,
        [
            token_class_hash,
            INITIALIZER_SELECTOR,
            [
                account_clients['comoco_dev'].address,
                config['name'],
                config['symbol'],
                account_clients['comoco_admin'].address,
                license_class_hash,
                registry_contract_address
            ]
        ],
        wait_for_accept=True
    )
    return Contract(token_contract_address, token_abi, account_clients['comoco_admin'])


async def setup_token_contract(
    account_clients: dict[str, AccountClient],
    registry_contract: Contract,
    token_contract: Contract,
    config: dict
):
    if 'l1_addr' in config:
        invocation = await registry_contract.functions['setMappingInfoForAddresses'].invoke(
            config['l1_addr'], token_contract.address, 1, max_fee=MAX_FEE)
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

    gateway_client, account_clients = create_clients(args)
    registry_contract = Contract(
        args.registry_address,
        get_abi(compile_contract(REGISTRY_FILE)),
        account_clients['comoco_registrar']
    )

    print("Declaring DerivativeToken class...")
    compiled_token_contract = compile_contract(TOKEN_FILE)
    token_class_hash = await declare_contract(
        gateway_client,
        account_clients['comoco_dev'],
        compiled_token_contract
    )
    write_contract('Token Class', token_class_hash)

    print("Declaring DerivativeLicense class...")
    license_class_hash = await declare_contract(
        gateway_client,
        account_clients['comoco_dev'],
        compile_contract(LICENSE_FILE)
    )
    write_contract('License Class', license_class_hash)

    compiled_proxy_contract = compile_contract(PROXY_FILE)
    token_abi = get_abi(compiled_token_contract)
    for token, config in TOKENS_CONFIG.items():
        print(f"Deploying DerivativeToken contract for {token}...")
        token_contract = await deploy_token_contract(
            gateway_client, account_clients, compiled_proxy_contract, token_abi,
            token_class_hash, license_class_hash, registry_contract.address, config
        )
        write_contract(token + ' Contract', token_contract.address)

        print(f"Setting up DerivativeToken contract for {token}...")
        await setup_token_contract(
            account_clients, registry_contract, token_contract, config
        )


if __name__ == '__main__':
    asyncio.run(main())
