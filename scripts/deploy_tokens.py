import argparse
import asyncio

from common import *


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--registry_address', dest='registry_address', required=True,
        help='The address of the deployed TokenRegistry contract'
    )
    args = parse_arguments(parser)
    gateway_client, account_clients = create_clients(args)


if __name__ == '__main__':
    asyncio.run(main())
