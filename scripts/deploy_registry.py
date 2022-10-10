import argparse
import asyncio
import os

from starkware.starknet.public.abi import get_selector_from_name

from common import (
    create_clients,
    declare_contract,
    deploy_contract,
    load_compiled_contract,
    parse_arguments,
    save_hash
)


COMPILED_PROXY_FILE = os.path.join(
    'artifacts', 'Proxy.json'
)
COMPILED_REGISTRY_FILE = os.path.join(
    'artifacts', 'TokenRegistry.json'
)

INITIALIZER_SELECTOR = get_selector_from_name('initializer')


async def main():
    parser = argparse.ArgumentParser()
    args = parse_arguments(parser)
    gateway_client, account_clients = create_clients(args)

    print("Declaring TokenRegistry class...")
    registry_class_hash = await declare_contract(
        gateway_client,
        account_clients['comoco_dev'],
        load_compiled_contract(COMPILED_REGISTRY_FILE)
    )
    save_hash('Registry Class', registry_class_hash)

    print("Deploying TokenRegistry contract...")
    registry_contract_address = await deploy_contract(
        gateway_client,
        load_compiled_contract(COMPILED_PROXY_FILE),
        [
            registry_class_hash,
            INITIALIZER_SELECTOR,
            [
                account_clients['comoco_dev'].address,
                account_clients['comoco_registrar'].address
            ]
        ],
        wait_for_accept=True
    )
    save_hash('Registry Contract', registry_contract_address)


if __name__ == '__main__':
    asyncio.run(main())
