import argparse
import asyncio

from starkware.starknet.public.abi import get_selector_from_name

from common import *


async def main():
    parser = argparse.ArgumentParser()
    args = parse_arguments(parser)
    gateway_client, account_clients = create_clients(args)

    registry_class = await declare_contract(
        account_clients['comoco_deployer'],
        'contracts/registry/TokenRegistryImpl.cairo'
    )

    registry_contract = await deploy_contract(
        gateway_client,
        'contracts/registry/TokenRegistry.cairo',
        [
            registry_class,
            get_selector_from_name('initializer'),
            [
                account_clients['comoco_upgrader'].address,
                account_clients['comoco_registrar'].address
            ]
        ]
    )

    print(hex(registry_contract.address))


if __name__ == '__main__':
    asyncio.run(main())
