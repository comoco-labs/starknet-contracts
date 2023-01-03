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
    load_abi,
    parse_arguments,
)


TOKEN_ABI_FILE = os.path.join(
    'artifacts', 'abis', 'DerivativeToken.json'
)

BATCH_SIZE = 100


async def batch_mint(
    account_client: AccountClient,
    calls: Calls,
    from_id: int,
    to_id: int
):
    print(f"Minting tokens from {from_id} to {to_id} at DerivativeToken...")
    resp = await account_client.execute(calls=calls, max_fee=MAX_FEE * len(calls))
    try:
        await account_client.wait_for_tx(resp.transaction_hash)
    except TransactionFailedError as e:
        print(e, file=sys.stderr)


async def mint_tokens(
    account_client: AccountClient,
    token_contract: Contract,
    start_id: int,
    total_num: int,
    parent_token_addresses: list[str]
):
    id = start_id
    batch_start_id = id
    calls = []
    while id < start_id + total_num:
        calls.append(token_contract.functions['mint'].prepare(
            account_client.address,
            id,
            [{'collection': int(addr, 0), 'id': id} for addr in parent_token_addresses],
            []
        ))
        if len(calls) == BATCH_SIZE:
            await batch_mint(account_client, calls, batch_start_id, id)
            batch_start_id = id + 1
            calls.clear()
        id += 1
    if calls:
        await batch_mint(account_client, calls, batch_start_id, id - 1)


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--token_address', dest='token_address', required=True,
        help='The address of the deployed DerivativeToken contract'
    )
    parser.add_argument(
        '--derived_from', dest='parent_token_addresses', action='append',
        help='The list of addresses from which the token contract is derived'
    )
    parser.add_argument(
        '--start', dest='start_id', type=int, required=True,
        help='The starting ID of tokens to mint'
    )
    parser.add_argument(
        '--total', dest='total_num', type=int, required=True,
        help='The total number of tokens to mint'
    )
    args = parse_arguments(parser)

    _, account_clients = create_clients(args)
    token_contract = Contract(
        args.token_address,
        load_abi(TOKEN_ABI_FILE),
        account_clients['comoco_admin']
    )
    parent_token_addresses = args.parent_token_addresses or []
    await mint_tokens(
        account_clients['comoco_admin'],
        token_contract,
        args.start_id,
        args.total_num,
        parent_token_addresses
    )


if __name__ == '__main__':
    asyncio.run(main())
