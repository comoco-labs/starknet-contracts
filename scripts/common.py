import argparse
import json
import pathlib
from typing import Optional, Union

from starknet_py.compile.compiler import create_contract_class
from starknet_py.contract import Contract
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.networks import TESTNET, MAINNET
from starknet_py.transactions.declare import make_declare_tx
from starknet_py.transactions.deploy import make_deploy_tx
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
    'comoco_admin',
    'comoco_bank'
)

tx_version = 1
deploy_token = None
output_file = 'deployments.txt'


def parse_arguments(parser: argparse.ArgumentParser):
    global tx_version, deploy_token, output_file
    parser.add_argument(
        '--network', dest='network', default='devnet',
        help='The name of the StarkNet network'
    )
    parser.add_argument(
        '--accounts_file', dest='accounts_file', default='accounts.json',
        help='The json file containing the accounts info'
    )
    parser.add_argument(
        '--version', dest='tx_version', default=tx_version, type=int,
        help='The version of the transaction to send in'
    )
    parser.add_argument(
        '--token', dest='deploy_token', default=deploy_token,
        help='The token allowing contract deployment for alpha-mainnet'
    )
    parser.add_argument(
        '--output', dest='output_file', default=output_file,
        help='The txt file to output the deployed contract addresses'
    )
    args = parser.parse_args()
    tx_version = args.tx_version
    deploy_token = args.deploy_token
    output_file = args.output_file
    return args


def _setup_accounts(
    network: str,
    gateway_client: GatewayClient,
    accounts: Union[dict, list]
) -> dict[str, AccountClient]:
    if isinstance(accounts, list):
        accounts = dict(zip(ACCOUNT_NAMES, accounts[:len(ACCOUNT_NAMES)]))
    else:
        accounts = accounts[network]
    account_clients = {}
    for account_name, account_info in accounts.items():
        account_client = AccountClient(
            client=gateway_client,
            address=account_info['address'],
            key_pair=KeyPair.from_private_key(int(account_info['private_key'], 0)),
            chain=CHAIN_IDS[network],
            supported_tx_version=tx_version
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


def load_compiled_contract(compiled_file: str) -> str:
    return pathlib.Path(compiled_file).read_text()


def load_abi(abi_file: str) -> AbiType:
    with open(abi_file, 'r') as f:
        return json.load(f)


def save_hash(name: str, hash: int):
    with open(output_file, 'a') as f:
        f.write(f"{name}: 0x{hash:x}\n")


async def declare_contract(
    gateway_client: GatewayClient,
    account_client: AccountClient,
    compiled_contract: str,
) -> int:
    if tx_version == 0:
        tx = make_declare_tx(compiled_contract=compiled_contract)
    else:
        tx = await account_client.sign_declare_transaction(
            compiled_contract=compiled_contract,
            auto_estimate=True
        )
    resp = await gateway_client.declare(tx, deploy_token)
    return resp.class_hash


async def deploy_contract(
    gateway_client: GatewayClient,
    compiled_contract: str,
    constructor_args: list,
    wait_for_accept: Optional[bool] = False
) -> int:
    compiled = create_contract_class(compiled_contract)
    translated_args = Contract._translate_constructor_args(compiled, constructor_args)
    tx = make_deploy_tx(
        compiled_contract=compiled,
        constructor_calldata=translated_args,
        version=tx_version
    )
    res = await gateway_client.deploy(tx, deploy_token)
    if wait_for_accept:
        await gateway_client.wait_for_tx(res.transaction_hash)
    return res.contract_address
