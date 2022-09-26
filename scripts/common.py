import argparse
import json
import pathlib

from starknet_py.compile.compiler import create_contract_class, starknet_compile
from starknet_py.contract import Contract
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.client import Client
from starknet_py.net.client_models import Hash
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.networks import TESTNET, MAINNET
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

MAX_FEE = int(1e16)


def parse_arguments(parser: argparse.ArgumentParser):
    parser.add_argument(
        '--network', dest='network', required=True,
        help='The name of the Starknet network'
    )
    parser.add_argument(
        '--accounts_file', dest='accounts_file',
        default='~/.starknet_accounts/starknet_open_zeppelin_accounts.json',
        help='The json file containing the accounts info'
    )
    return parser.parse_args()


def create_clients(args) -> tuple[GatewayClient, dict[str, AccountClient]]:
    p = pathlib.Path(args.accounts_file).expanduser()
    with p.open() as f:
        accounts = json.load(f)[args.network]

    gateway_client = GatewayClient(NETWORKS[args.network])
    account_clients = _setup_accounts(args.network, gateway_client, accounts)

    return gateway_client, account_clients


def _setup_accounts(network, client, accounts):
    account_clients = {}
    for account_name, account_info in accounts.items():
        account_client = AccountClient(
            client=client,
            address=account_info['address'],
            key_pair=KeyPair.from_private_key(int(account_info['private_key'], 0)),
            chain=CHAIN_IDS[network],
            supported_tx_version=1
        )
        account_clients[account_name] = account_client
    return account_clients


async def declare_contract(
    account_client: AccountClient, contract_file: str
) -> Hash:
    tx = await account_client.sign_declare_transaction(
        compilation_source=[contract_file],
        max_fee=MAX_FEE
    )
    resp = await account_client.declare(tx)
    return resp.class_hash


async def deploy_contract(
    client: Client, contract_file: str, constructor_args: list
) -> Contract:
    res = await Contract.deploy(
        client=client,
        compilation_source=[contract_file],
        constructor_args=constructor_args
    )
    return res.deployed_contract


def get_abi(
    contract_file: str
) -> AbiType:
    compiled_contract = starknet_compile(source=[contract_file])
    contract_class = create_contract_class(compiled_contract=compiled_contract)
    return contract_class.abi


def replace_abi(
    contract: Contract, abi: list
) -> Contract:
    return Contract(contract.address, abi, contract.client)
