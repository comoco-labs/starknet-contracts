import argparse
import asyncio
import os

from starkware.starknet.public.abi import get_selector_from_name

from common import (
    compile_contract,
    create_clients,
    declare_contract,
    deploy_contract,
    parse_arguments
)


REGISTRY_CONTRACT_FILE = os.path.join(
    'contracts', 'registry', 'TokenRegistry.cairo'
)
REGISTRY_IMPL_FILE = os.path.join(
    'contracts', 'registry', 'TokenRegistryImpl.cairo'
)

INITIALIZER_SELECTOR = get_selector_from_name('initializer')


async def main():
    parser = argparse.ArgumentParser()
    args = parse_arguments(parser)
    gateway_client, account_clients = create_clients(args)

    print("Declaring TokenRegistryImpl class...")
    registry_class = await declare_contract(
        account_clients['comoco_deployer'],
        compile_contract(REGISTRY_IMPL_FILE)
    )

    print("Deploying TokenRegistry contract...")
    registry_contract = await deploy_contract(
        gateway_client,
        compile_contract(REGISTRY_CONTRACT_FILE),
        [
            registry_class,
            INITIALIZER_SELECTOR,
            [
                account_clients['comoco_upgrader'].address,
                account_clients['comoco_registrar'].address
            ]
        ],
        wait_for_accept=True
    )

    print(f"TokenRegistry Address: 0x{registry_contract.address:x}")


if __name__ == '__main__':
    asyncio.run(main())
