import argparse
import asyncio
import os

from starknet_py.contract import Contract
from starknet_py.net import AccountClient
from starknet_py.net.client_models import Calls

from common import (
    MAX_FEE,
    compile_contract,
    create_clients,
    get_abi,
    parse_arguments,
)


TOKEN_FILE = os.path.join(
    'contracts', 'token', 'DerivativeToken.cairo'
)

BATCH_SIZE = 100


async def batch_mint(
    account_client: AccountClient,
    calls: Calls,
    from_id: int,
    to_id: int
):
    print(f"Minting tokens from {from_id} to {to_id} at DerivativeToken...")
    resp = await account_client.execute(calls=calls, max_fee=MAX_FEE * BATCH_SIZE)
    await account_client.wait_for_tx(resp.transaction_hash)


async def mint_tokens(
    account_clients: dict[str, AccountClient],
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
            account_clients['comoco_agent'].address,
            id,
            [{'collection': int(addr, 0), 'id': id} for addr in parent_token_addresses]))
        if len(calls) == BATCH_SIZE:
            await batch_mint(account_clients['comoco_admin'], calls, batch_start_id, id)
            batch_start_id = id + 1
            calls.clear()
        id += 1
    if calls:
        await batch_mint(account_clients['comoco_admin'], calls, batch_start_id, id - 1)


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
        '--start', dest='start_id', required=True,
        help='The starting ID of tokens to mint'
    )
    parser.add_argument(
        '--total', dest='total_num', required=True,
        help='The total number of tokens to mint'
    )
    args = parse_arguments(parser)

    _, account_clients = create_clients(args)
    token_contract = Contract(
        args.token_address,
        get_abi(compile_contract(TOKEN_FILE)),
        account_clients['comoco_admin']
    )
    parent_token_addresses = args.parent_token_addresses or []
    await mint_tokens(
        account_clients,
        token_contract,
        int(args.start_id),
        int(args.total_num),
        parent_token_addresses
    )


if __name__ == '__main__':
    asyncio.run(main())
