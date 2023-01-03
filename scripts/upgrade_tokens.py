import argparse
import asyncio
import os
import sys

from starknet_py.contract import Contract
from starknet_py.net import AccountClient
from starknet_py.net.client_models import Calls
from starknet_py.transaction_exceptions import TransactionFailedError

from common import (
    MAX_FEE,
    create_clients,
    declare_contract,
    load_abi,
    load_compiled_contract,
    parse_arguments,
    save_hash
)


COMPILED_TOKEN_FILE = os.path.join(
    'artifacts', 'DerivativeToken.json'
)

TOKEN_ABI_FILE = os.path.join(
    'artifacts', 'abis', 'DerivativeToken.json'
)


async def batch_upgrade(
    account_client: AccountClient,
    calls: Calls,
):
    print(f"Upgrading all DerivativeToken contracts...")
    resp = await account_client.execute(calls=calls, max_fee=MAX_FEE * len(calls))
    try:
        await account_client.wait_for_tx(resp.transaction_hash)
    except TransactionFailedError as e:
        print(e, file=sys.stderr)


async def upgrade_tokens(
    account_client: AccountClient,
    token_addresses: list[str],
    token_class_hash: int
):
    calls = []
    for token_address in token_addresses:
        token_contract = Contract(
            token_address,
            load_abi(TOKEN_ABI_FILE),
            account_client
        )
        calls.append(token_contract.functions['upgrade'].prepare(token_class_hash))
    await batch_upgrade(account_client, calls)


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--token_address', dest='token_addresses', action='append',
        help='The list of DerivativeToken addresses for whose implementation to upgrade'
    )
    args = parse_arguments(parser)
    _, account_clients = create_clients(args)

    print("Declaring DerivativeToken class...")
    token_declare_result = await declare_contract(
        account_clients['comoco_dev'],
        load_compiled_contract(COMPILED_TOKEN_FILE)
    )
    save_hash('Token Class', token_declare_result.class_hash)

    if args.token_addresses:
        await upgrade_tokens(
            account_clients['comoco_dev'],
            args.token_addresses,
            token_declare_result.class_hash
        )


if __name__ == '__main__':
    asyncio.run(main())
