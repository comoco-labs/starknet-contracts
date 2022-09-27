import argparse
import asyncio

from starkware.starknet.public.abi import get_selector_from_name

from common import (
    compile_contract,
    create_clients,
    declare_contract,
    deploy_contract,
    parse_arguments
)


COMPILED_REGISTRY_CONTRACT = compile_contract(
    'contracts/registry/TokenRegistry.cairo'
)
COMPILED_REGISTRY_IMPL_CONTRACT = compile_contract(
    'contracts/registry/TokenRegistryImpl.cairo'
)

INITIALIZER_SELECTOR = get_selector_from_name('initializer')


async def main():
    parser = argparse.ArgumentParser()
    args = parse_arguments(parser)
    gateway_client, account_clients = create_clients(args)

    print("Declaring TokenRegistryImpl class...")
    registry_class = await declare_contract(
        account_clients['comoco_deployer'],
        COMPILED_REGISTRY_IMPL_CONTRACT
    )

    print("Deploying TokenRegistry contract...")
    registry_contract = await deploy_contract(
        gateway_client,
        COMPILED_REGISTRY_CONTRACT,
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
