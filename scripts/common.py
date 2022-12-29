import argparse
import json
import pathlib
from typing import Optional, Union

from starknet_py.contract import Contract, DeclareResult, DeployResult
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.networks import MAINNET, TESTNET, TESTNET2
from starkware.starknet.public.abi import AbiType


NETWORKS = {
    'devnet': "http://localhost:5050",
    'testnet': TESTNET,
    'testnet2': TESTNET2,
    'mainnet': MAINNET
}

CHAIN_IDS = {
    'devnet': StarknetChainId.TESTNET,
    'testnet': StarknetChainId.TESTNET,
    'testnet2': StarknetChainId.TESTNET2,
    'mainnet': StarknetChainId.MAINNET
}

ACCOUNT_NAMES = (
    'comoco_dev',
    'comoco_admin',
    'comoco_bank'
)

deploy_token = None
output_file = 'deployments.txt'


def parse_arguments(parser: argparse.ArgumentParser):
    global deploy_token, output_file
    parser.add_argument(
        '--network', dest='network', default='devnet',
        help='The name of the StarkNet network'
    )
    parser.add_argument(
        '--accounts_file', dest='accounts_file', default='accounts.json',
        help='The json file containing the accounts info'
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
            supported_tx_version=1
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
    account_client: AccountClient,
    compiled_contract: str,
    wait_for_accept: Optional[bool] = True
) -> DeclareResult:
    declare_result = await Contract.declare(
        account=account_client,
        compiled_contract=compiled_contract,
        auto_estimate=True
    )
    if wait_for_accept:
        await declare_result.wait_for_acceptance()
    return declare_result


async def deploy_contract(
    declare_result: DeclareResult,
    constructor_args: list,
    wait_for_accept: Optional[bool] = True
) -> DeployResult:
    deploy_result = await declare_result.deploy(
        constructor_args=constructor_args,
        auto_estimate=True
    )
    if wait_for_accept:
        await deploy_result.wait_for_acceptance()
    return deploy_result
