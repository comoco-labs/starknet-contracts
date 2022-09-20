import os
import pytest

from starkware.starknet.testing.starknet import Starknet

from utils import (str_to_felt, to_uint)


REGISTRY_OWNER_ADDRESS = 0x1111111111111111111111111111111111111111
COLLECTION_OWNER_ADDRESS = 0x2222222222222222222222222222222222222222
COLLECTION_ADMIN_ADDRESS = 0x3333333333333333333333333333333333333333

REGISTRY_CONTRACT_FILE = os.path.join('contracts', 'registry', 'TokenRegistry.cairo')
LICENSE_CONTRACT_FILE = os.path.join('contracts', 'license', 'DerivativeLicense.cairo')
TOKEN_CONTRACT_FILE = os.path.join('contracts', 'token', 'DerivativeToken.cairo')

NAME = str_to_felt('name')
SYMBOL = str_to_felt('symbol')

ORIGINAL_TOKEN_ID = to_uint(10)
ORIGINAL_TOKEN_OWNER_ADDRESS = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
DERIVATIVE_TOKEN_ID = to_uint(11)
DERIVATIVE_TOKEN_OWNER_ADDRESS = 0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB


@pytest.mark.asyncio
async def test_contracts():
    starknet = await Starknet.empty()

    registry_contract = await starknet.deploy(
        source=REGISTRY_CONTRACT_FILE,
        constructor_calldata=[REGISTRY_OWNER_ADDRESS]
    )

    license_class = await starknet.declare(
        source=LICENSE_CONTRACT_FILE
    )

    token_contract = await starknet.deploy(
        source=TOKEN_CONTRACT_FILE,
        constructor_calldata=[
            NAME,
            SYMBOL,
            COLLECTION_OWNER_ADDRESS,
            license_class.class_hash,
            registry_contract.contract_address
        ]
    )

    # Set Registry

    await registry_contract.setMappingInfoForAddresses(0xDEADBEEF, token_contract.contract_address, 1).execute(caller_address=REGISTRY_OWNER_ADDRESS)
    execution_info = await registry_contract.getMappingInfoForL1Address(0xBADC0FFEE).call()
    assert execution_info.result == (0, 0)
    execution_info = await registry_contract.getMappingInfoForAddresses(0xDEADBEEF, token_contract.contract_address).call()
    assert execution_info.result == (1,)

    # Access Control

    execution_info = await token_contract.owner().call()
    assert execution_info.result == (COLLECTION_OWNER_ADDRESS,)
    execution_info = await token_contract.isAdmin(COLLECTION_ADMIN_ADDRESS).call()
    assert execution_info.result == (0,)

    await token_contract.setAdmin(COLLECTION_ADMIN_ADDRESS, 1).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.isAdmin(COLLECTION_ADMIN_ADDRESS).call()
    assert execution_info.result == (1,)

    # Mint Original

    await token_contract.mint(ORIGINAL_TOKEN_OWNER_ADDRESS, ORIGINAL_TOKEN_ID, []).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.authorOf(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == (ORIGINAL_TOKEN_OWNER_ADDRESS,)
    execution_info = await token_contract.parentTokensOf(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == ([],)

    # License: version

    execution_info = await token_contract.licenseVersion().call()
    assert execution_info.result == (1,)

    # License: royalties

    await token_contract.setCollectionArraySettings(str_to_felt('royalties'), [123, 5, 456, 10]).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.collectionArraySettings(str_to_felt('royalties')).call()
    assert execution_info.result == ([123, 5, 456, 10],)

    await token_contract.setAuthorArraySettings(ORIGINAL_TOKEN_ID, str_to_felt('royalties'), [789, 15]).execute(caller_address=ORIGINAL_TOKEN_OWNER_ADDRESS)
    execution_info = await token_contract.authorArraySettings(ORIGINAL_TOKEN_ID, str_to_felt('royalties')).call()
    assert execution_info.result == ([789, 15],)

    execution_info = await token_contract.royalties(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == ([(123, 5), (456, 10), (789, 15)],)

    # License: licensees

    execution_info = await token_contract.allowToMint(ORIGINAL_TOKEN_ID, ORIGINAL_TOKEN_OWNER_ADDRESS).call()
    assert execution_info.result == (1,)
    execution_info = await token_contract.allowToMint(ORIGINAL_TOKEN_ID, DERIVATIVE_TOKEN_OWNER_ADDRESS).call()
    assert execution_info.result == (0,)

    await token_contract.setTokenArraySettings(ORIGINAL_TOKEN_ID, str_to_felt('licensees'), [DERIVATIVE_TOKEN_OWNER_ADDRESS]).execute(caller_address=ORIGINAL_TOKEN_OWNER_ADDRESS)
    execution_info = await token_contract.allowToMint(ORIGINAL_TOKEN_ID, DERIVATIVE_TOKEN_OWNER_ADDRESS).call()
    assert execution_info.result == (1,)

    # Clear Registry

    await registry_contract.clearMappingInfoForAddresses(0xDEADBEEF, token_contract.contract_address).execute(caller_address=REGISTRY_OWNER_ADDRESS)
    execution_info = await registry_contract.getMappingInfoForL2Address(token_contract.contract_address).call()
    assert execution_info.result == (0, 0)

    # Mint Derivative

    await token_contract.mint(DERIVATIVE_TOKEN_OWNER_ADDRESS, DERIVATIVE_TOKEN_ID, [(token_contract.contract_address, ORIGINAL_TOKEN_ID)]).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.authorOf(DERIVATIVE_TOKEN_ID).call()
    assert execution_info.result == (DERIVATIVE_TOKEN_OWNER_ADDRESS,)
    execution_info = await token_contract.parentTokensOf(DERIVATIVE_TOKEN_ID).call()
    assert execution_info.result == ([(token_contract.contract_address, ORIGINAL_TOKEN_ID)],)

    # License: allow_transfer

    execution_info = await token_contract.allowToTransfer(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == (1,)
    execution_info = await token_contract.allowTransfer(DERIVATIVE_TOKEN_ID).call()
    assert execution_info.result == (1,)

    await token_contract.setCollectionSettings(str_to_felt('allow_transfer'), 1).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.collectionSettings(str_to_felt('allow_transfer')).call()
    assert execution_info.result == (1,)
    execution_info = await token_contract.allowToTransfer(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == (1,)
    execution_info = await token_contract.allowTransfer(DERIVATIVE_TOKEN_ID).call()
    assert execution_info.result == (1,)

    await token_contract.setTokenSettings(ORIGINAL_TOKEN_ID, str_to_felt('allow_transfer'), 2).execute(caller_address=ORIGINAL_TOKEN_OWNER_ADDRESS)
    execution_info = await token_contract.tokenSettings(ORIGINAL_TOKEN_ID, str_to_felt('allow_transfer')).call()
    assert execution_info.result == (2,)
    execution_info = await token_contract.allowToTransfer(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == (0,)
    execution_info = await token_contract.allowTransfer(DERIVATIVE_TOKEN_ID).call()
    assert execution_info.result == (0,)
