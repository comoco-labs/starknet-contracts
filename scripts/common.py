import argparse
import json
import pathlib
from typing import Optional, Union

from starknet_py.compile.compiler import create_contract_class, starknet_compile
from starknet_py.contract import Contract
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.client import Client
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.networks import TESTNET, MAINNET
from starknet_py.transactions.declare import make_declare_tx
from starkware.starknet.public.abi import AbiType


NETWORKS = {
    'devnet': "http://localhost:5050",
    'testnet': TESTNET,
    'mainnet': MAINNET
}

CHAIN_IDS = {
    'devnet': StarknetChainId.TESTNET,
    'testnet': StarknetChainId.TESTNET,
    'mainnet': StarknetChainId.MAINNET
}

ACCOUNT_NAMES = (
    'comoco_dev',
    'comoco_bank',
    'comoco_registrar',
    'comoco_admin'
)

TX_VERSION = 1

MAX_FEE = int(1e16)


def parse_arguments(parser: argparse.ArgumentParser):
    global TX_VERSION
    parser.add_argument(
        '--network', dest='network', default='devnet',
        help='The name of the StarkNet network'
    )
    parser.add_argument(
        '--accounts_file', dest='accounts_file', default='accounts.json',
        help='The json file containing the accounts info'
    )
    parser.add_argument(
        '--tx_version', dest='tx_version', default=TX_VERSION, type=int,
        help='The version of the transaction to send in'
    )
    parser.add_argument(
        '--output', dest='output_file', default='deployments.txt',
        help='The txt file to output the deployed contract addresses'
    )
    args = parser.parse_args()
    TX_VERSION = args.tx_version
    return args


def _setup_accounts(
    network: str,
    client: Client,
    accounts: Union[dict, list]
) -> dict[str, AccountClient]:
    if isinstance(accounts, list):
        accounts = dict(zip(ACCOUNT_NAMES, accounts[:len(ACCOUNT_NAMES)]))
    else:
        accounts = accounts[network]
    account_clients = {}
    for account_name, account_info in accounts.items():
        account_client = AccountClient(
            client=client,
            address=account_info['address'],
            key_pair=KeyPair.from_private_key(int(account_info['private_key'], 0)),
            chain=CHAIN_IDS[network],
            supported_tx_version=TX_VERSION
        )
        account_clients[account_name] = account_client
    return account_clients


def create_clients(args) -> tuple[GatewayClient, dict[str, AccountClient]]:
    p = pathlib.Path(args.accounts_file).expanduser()
    with p.open() as f:
        accounts = json.load(f)

    gateway_client = GatewayClient(NETWORKS[args.network])
    account_clients = _setup_accounts(args.network, gateway_client, accounts)

    return gateway_client, account_clients


def compile_contract(contract_file: str) -> str:
    return starknet_compile(source=[contract_file])


def get_abi(compiled_contract: str) -> AbiType:
    return create_contract_class(compiled_contract=compiled_contract).abi


def replace_abi(contract: Contract, abi: AbiType) -> Contract:
    return Contract(contract.address, abi, contract.client)


async def declare_contract(
    account_client: AccountClient, compiled_contract: str
) -> int:
    if TX_VERSION == 0:
        tx = make_declare_tx(compiled_contract=compiled_contract)
    else:
        tx = await account_client.sign_declare_transaction(
            compiled_contract=compiled_contract,
            max_fee=MAX_FEE
        )
    resp = await account_client.declare(tx)
    return resp.class_hash


async def deploy_contract(
    client: Client, compiled_contract: str, constructor_args: list,
    wait_for_accept: Optional[bool] = False
) -> Contract:
    res = await Contract.deploy(
        client=client,
        compiled_contract=compiled_contract,
        constructor_args=constructor_args
    )
    if wait_for_accept:
        await res.wait_for_acceptance()
    return res.deployed_contract


def write_contract(
    file: str, name: str, hash: int
):
    with open(file, 'a') as f:
        f.write(f"{name}: 0x{hash:x}\n")
