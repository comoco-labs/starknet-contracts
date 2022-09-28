import argparse
import asyncio
import os

from starknet_py.contract import Contract
from starknet_py.net import AccountClient
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
    replace_abi
)


REGISTRY_IMPL_FILE = os.path.join(
    'contracts', 'registry', 'TokenRegistryImpl.cairo'
)
TOKEN_CONTRACT_FILE = os.path.join(
    'contracts', 'token', 'DerivativeToken.cairo'
)
TOKEN_IMPL_FILE = os.path.join(
    'contracts', 'token', 'DerivativeTokenImpl.cairo'
)
LICENSE_IMPL_FILE = os.path.join(
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
    account_clients: dict[str, AccountClient],
    compiled_token_contract: str,
    token_impl_abi: AbiType,
    token_class: int,
    license_class: int,
    registry_contract: Contract,
    config: dict
) -> Contract:
    token_contract = await deploy_contract(
        account_clients['comoco_admin'],
        compiled_token_contract,
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
    token_contract = replace_abi(token_contract, token_impl_abi)
    return token_contract


async def setup_token_contract(
    account_clients: dict[str, AccountClient],
    registry_contract: Contract,
    token_contract: Contract,
    config: dict
):
    if 'l1_addr' in config:
        print("Registering at TokenRegistry...")
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
        print("Configuring license settings at DerivativeToken...")
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

    print("Declaring DerivativeTokenImpl class...")
    compiled_token_impl_contract = compile_contract(TOKEN_IMPL_FILE)
    token_class = await declare_contract(
        account_clients['comoco_deployer'],
        compiled_token_impl_contract
    )
    print("Declaring DerivativeLicense class...")
    license_class = await declare_contract(
        account_clients['comoco_deployer'],
        compile_contract(LICENSE_IMPL_FILE)
    )
    registry_contract = Contract(
        args.registry_address,
        get_abi(compile_contract(REGISTRY_IMPL_FILE)),
        account_clients['comoco_registrar']
    )

    compiled_token_contract = compile_contract(TOKEN_CONTRACT_FILE)
    token_impl_abi = get_abi(compiled_token_impl_contract)
    for token, config in TOKENS_CONFIG.items():
        print(f"Deploying DerivativeToken contract for {token}...")
        token_contract = await deploy_token_contract(
            account_clients, compiled_token_contract, token_impl_abi,
            token_class, license_class, registry_contract, config
        )
        print(f"Setting up DerivativeToken contract for {token}...")
        await setup_token_contract(
            account_clients, registry_contract, token_contract, config
        )
        print(f"{token} Address: 0x{token_contract.address:x}")


if __name__ == '__main__':
    asyncio.run(main())
