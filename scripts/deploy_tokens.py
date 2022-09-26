import argparse
import asyncio

from starknet_py.contract import Contract
from starknet_py.net import AccountClient
from starknet_py.net.gateway_client import GatewayClient
from starkware.starknet.public.abi import get_selector_from_name

from common import (
    MAX_FEE,
    compile_contract,
    create_clients,
    declare_contract,
    deploy_contract,
    get_abi,
    parse_arguments,
    replace_abi
)


COMPILED_REGISTRY_IMPL_CONTRACT = compile_contract(
    'contracts/registry/TokenRegistryImpl.cairo'
)
COMPILED_TOKEN_CONTRACT = compile_contract(
    'contracts/token/DerivativeToken.cairo'
)
COMPILED_TOKEN_IMPL_CONTRACT = compile_contract(
    'contracts/token/DerivativeTokenImpl.cairo'
)
COMPILED_LICENSE_CONTRACT = compile_contract(
    'contracts/license/DerivativeLicense.cairo'
)

REGISTRY_IMPL_ABI = get_abi(COMPILED_REGISTRY_IMPL_CONTRACT)
TOKEN_IMPL_ABI = get_abi(COMPILED_TOKEN_IMPL_CONTRACT)

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
    account_clients: dict[str, AccountClient],
    token_class: int,
    license_class: int,
    registry_contract: Contract,
    config: dict
) -> Contract:
    token_contract = await deploy_contract(
        account_clients['comoco_admin'],
        COMPILED_TOKEN_CONTRACT,
        [
            token_class,
            INITIALIZER_SELECTOR,
            [
                account_clients['comoco_upgrader'].address,
                config['name'],
                config['symbol'],
                account_clients['comoco_admin'].address,
                license_class,
                registry_contract.address
            ]
        ]
    )
    token_contract = replace_abi(token_contract, TOKEN_IMPL_ABI)
    return token_contract


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
            'royalties', [account_clients['comoco_receiver'].address, config['royalties']]))
    if calls:
        resp = await account_clients['comoco_admin'].execute(calls=calls, max_fee=MAX_FEE)
        await account_clients['comoco_admin'].wait_for_tx(resp.transaction_hash)


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--registry_address', dest='registry_address', required=True,
        help='The address of the deployed TokenRegistry contract'
    )
    args = parse_arguments(parser)
    _, account_clients = create_clients(args)

    token_class = await declare_contract(
        account_clients['comoco_deployer'],
        COMPILED_TOKEN_IMPL_CONTRACT
    )
    license_class = await declare_contract(
        account_clients['comoco_deployer'],
        COMPILED_LICENSE_CONTRACT
    )
    registry_contract = Contract(
        args.registry_address,
        REGISTRY_IMPL_ABI,
        account_clients['comoco_registrar']
    )

    for token, config in TOKENS_CONFIG.items():
        token_contract = await deploy_token_contract(
            account_clients, token_class, license_class, registry_contract, config
        )
        await setup_token_contract(
            account_clients, registry_contract, token_contract, config
        )
        print(f'{token} Address: 0x{token_contract.address:x}')


if __name__ == '__main__':
    asyncio.run(main())
