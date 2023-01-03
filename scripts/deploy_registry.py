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
    _, account_clients = create_clients(args)

    print("Declaring TokenRegistry class...")
    registry_declare_result = await declare_contract(
        account_clients['comoco_dev'],
        load_compiled_contract(COMPILED_REGISTRY_FILE)
    )
    save_hash('Registry Class', registry_declare_result.class_hash)

    print("Declaring Proxy class...")
    proxy_declare_result = await declare_contract(
        account_clients['comoco_dev'],
        load_compiled_contract(COMPILED_PROXY_FILE)
    )

    print("Deploying TokenRegistry contract...")
    registry_deploy_result = await deploy_contract(
        proxy_declare_result,
        [
            registry_declare_result.class_hash,
            INITIALIZER_SELECTOR,
            [
                account_clients['comoco_dev'].address
            ]
        ]
    )
    save_hash('Registry Contract', registry_deploy_result.deployed_contract.address)


if __name__ == '__main__':
    asyncio.run(main())
