import argparse
import asyncio
import os

from starkware.starknet.public.abi import get_selector_from_name

from common import (
    compile_contract,
    create_clients,
    declare_contract,
    deploy_contract,
    parse_arguments,
    write_contract
)


PROXY_FILE = os.path.join(
    'contracts', 'proxy', 'Proxy.cairo'
)
REGISTRY_FILE = os.path.join(
    'contracts', 'registry', 'TokenRegistry.cairo'
)

INITIALIZER_SELECTOR = get_selector_from_name('initializer')


async def main():
    parser = argparse.ArgumentParser()
    args = parse_arguments(parser)
    gateway_client, account_clients = create_clients(args)

    print("Declaring TokenRegistry class...")
    registry_class = await declare_contract(
        account_clients['comoco_dev'],
        compile_contract(REGISTRY_FILE)
    )
    write_contract(args.output_file, 'Registry Class', registry_class)

    print("Deploying TokenRegistry contract...")
    registry_contract = await deploy_contract(
        gateway_client,
        compile_contract(PROXY_FILE),
        [
            registry_class,
            INITIALIZER_SELECTOR,
            [
                account_clients['comoco_dev'].address,
                account_clients['comoco_registrar'].address
            ]
        ],
        wait_for_accept=True
    )
    write_contract(args.output_file, 'Registry Contract', registry_contract.address)


if __name__ == '__main__':
    asyncio.run(main())
