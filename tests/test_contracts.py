import os
import pytest

from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet, StarknetContract

from utils import assert_revert, str_to_felt, to_uint


PROXY_ADMIN_ADDRESS = 0x1111111111111111111111111111111111111111
REGISTRY_OWNER_ADDRESS = 0x2222222222222222222222222222222222222222
COLLECTION_OWNER_ADDRESS = 0x3333333333333333333333333333333333333333
COLLECTION_ADMIN_ADDRESS = 0x4444444444444444444444444444444444444444

PROXY_FILE = os.path.join('contracts', 'proxy', 'Proxy.cairo')
REGISTRY_FILE = os.path.join('contracts', 'registry', 'TokenRegistry.cairo')
TOKEN_FILE = os.path.join('contracts', 'token', 'DerivativeToken.cairo')
LICENSE_FILE = os.path.join('contracts', 'license', 'DerivativeLicense.cairo')

INITIALIZER_SELECTOR = get_selector_from_name('initializer')
NAME = str_to_felt('name')
SYMBOL = str_to_felt('symbol')

ORIGINAL_TOKEN_ID = to_uint(10)
ORIGINAL_TOKEN_OWNER_ADDRESS = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
DERIVED_TOKEN_ID = to_uint(11)
DERIVED_TOKEN_OWNER_ADDRESS = 0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB


@pytest.fixture(scope='module')
async def contracts_init():
    starknet = await Starknet.empty()

    registry_class = await starknet.declare(REGISTRY_FILE)
    token_class = await starknet.declare(TOKEN_FILE)
    license_class = await starknet.declare(LICENSE_FILE)

    registry_contract = await starknet.deploy(
        source=PROXY_FILE,
        constructor_calldata=[
            registry_class.class_hash,
            INITIALIZER_SELECTOR,
            2,
            PROXY_ADMIN_ADDRESS,
            REGISTRY_OWNER_ADDRESS
        ]
    )
    registry_contract = registry_contract.replace_abi(registry_class.abi)

    token_contract = await starknet.deploy(
        source=PROXY_FILE,
        constructor_calldata=[
            token_class.class_hash,
            INITIALIZER_SELECTOR,
            6,
            PROXY_ADMIN_ADDRESS,
            NAME,
            SYMBOL,
            COLLECTION_OWNER_ADDRESS,
            license_class.class_hash,
            registry_contract.contract_address
        ]
    )
    token_contract = token_contract.replace_abi(token_class.abi)

    return starknet.state, registry_contract, token_contract


@pytest.fixture
def contracts_factory(contracts_init):
    state, registry_contract, token_contract = contracts_init

    _state = state.copy()
    registry_contract = StarknetContract(
        _state,
        registry_contract.abi,
        registry_contract.contract_address,
        registry_contract.deploy_call_info
    )
    token_contract = StarknetContract(
        _state,
        token_contract.abi,
        token_contract.contract_address,
        token_contract.deploy_call_info
    )

    return registry_contract, token_contract


@pytest.mark.asyncio
async def test_TokenRegistry(contracts_factory):
    registry_contract, _ = contracts_factory

    execution_info = await registry_contract.getMappingInfoForAddresses(0xDEADBEEF, 0xBADC0FFEE).call()
    assert execution_info.result == (0,)

    await assert_revert(
        registry_contract.setMappingInfoForAddresses(0xDEADBEEF, 0xBADC0FFEE, 1).execute())
    await registry_contract.setMappingInfoForAddresses(0xDEADBEEF, 0xBADC0FFEE, 1).execute(caller_address=REGISTRY_OWNER_ADDRESS)
    execution_info = await registry_contract.getMappingInfoForL1Address(0xDEADBEEF).call()
    assert execution_info.result == (0xBADC0FFEE, 1)

    await registry_contract.setMappingInfoForAddresses(0xDEADBEEF, 0xFEEDF00D, 2).execute(caller_address=REGISTRY_OWNER_ADDRESS)
    execution_info = await registry_contract.getMappingInfoForL1Address(0xDEADBEEF).call()
    assert execution_info.result == (0xFEEDF00D, 2)
    execution_info = await registry_contract.getMappingInfoForL2Address(0xBADC0FFEE).call()
    assert execution_info.result == (0, 0)

    await registry_contract.clearMappingInfoForAddresses(0xDEADBEEF, 0xFEEDF00D).execute(caller_address=REGISTRY_OWNER_ADDRESS)
    execution_info = await registry_contract.getMappingInfoForAddresses(0xDEADBEEF, 0xFEEDF00D).call()
    assert execution_info.result == (0,)


@pytest.mark.asyncio
async def test_DerivativeToken_access(contracts_factory):
    _, token_contract = contracts_factory

    execution_info = await token_contract.owner().call()
    assert execution_info.result == (COLLECTION_OWNER_ADDRESS,)

    execution_info = await token_contract.isAdmin(COLLECTION_ADMIN_ADDRESS).call()
    assert execution_info.result == (0,)

    await token_contract.setAdmin(COLLECTION_ADMIN_ADDRESS, 1).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.isAdmin(COLLECTION_ADMIN_ADDRESS).call()
    assert execution_info.result == (1,)

    await token_contract.transferOwnership(COLLECTION_ADMIN_ADDRESS).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.owner().call()
    assert execution_info.result == (COLLECTION_ADMIN_ADDRESS,)

    execution_info = await token_contract.isAdmin(COLLECTION_OWNER_ADDRESS).call()
    assert execution_info.result == (0,)


@pytest.mark.asyncio
async def test_DerivativeToken_royalties(contracts_factory):
    _, token_contract = contracts_factory

    await token_contract.mint(ORIGINAL_TOKEN_OWNER_ADDRESS, ORIGINAL_TOKEN_ID, []).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.ownerOf(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == (ORIGINAL_TOKEN_OWNER_ADDRESS,)
    execution_info = await token_contract.authorOf(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == (ORIGINAL_TOKEN_OWNER_ADDRESS,)

    await token_contract.setCollectionArraySettings(str_to_felt('royalties'), [123, 5]).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.collectionArraySettings(str_to_felt('royalties')).call()
    assert execution_info.result == ([123, 5],)

    await token_contract.setTokenArraySettings(ORIGINAL_TOKEN_ID, str_to_felt('royalties'), [456, 10]).execute(caller_address=ORIGINAL_TOKEN_OWNER_ADDRESS)
    execution_info = await token_contract.tokenArraySettings(ORIGINAL_TOKEN_ID, str_to_felt('royalties')).call()
    assert execution_info.result == ([456, 10],)

    await token_contract.setAuthorArraySettings(ORIGINAL_TOKEN_ID, str_to_felt('royalties'), [789, 15]).execute(caller_address=ORIGINAL_TOKEN_OWNER_ADDRESS)
    execution_info = await token_contract.authorArraySettings(ORIGINAL_TOKEN_ID, str_to_felt('royalties')).call()
    assert execution_info.result == ([789, 15],)

    execution_info = await token_contract.royalties(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == ([(123, 5), (456, 10), (789, 15)],)


@pytest.mark.asyncio
async def test_DerivativeToken_mint(contracts_factory):
    _, token_contract = contracts_factory

    await token_contract.mint(ORIGINAL_TOKEN_OWNER_ADDRESS, ORIGINAL_TOKEN_ID, []).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.parentTokensOf(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == ([],)

    execution_info = await token_contract.allowToMint(ORIGINAL_TOKEN_ID, ORIGINAL_TOKEN_OWNER_ADDRESS).call()
    assert execution_info.result == (1,)
    execution_info = await token_contract.allowToMint(ORIGINAL_TOKEN_ID, DERIVED_TOKEN_OWNER_ADDRESS).call()
    assert execution_info.result == (0,)

    await assert_revert(
        token_contract.mint(DERIVED_TOKEN_OWNER_ADDRESS, DERIVED_TOKEN_ID, [(token_contract.contract_address, ORIGINAL_TOKEN_ID)]).execute(caller_address=COLLECTION_OWNER_ADDRESS),
        reverted_with="not licensed")

    await token_contract.setTokenArraySettings(ORIGINAL_TOKEN_ID, str_to_felt('licensees'), [DERIVED_TOKEN_OWNER_ADDRESS]).execute(caller_address=ORIGINAL_TOKEN_OWNER_ADDRESS)
    execution_info = await token_contract.allowToMint(ORIGINAL_TOKEN_ID, DERIVED_TOKEN_OWNER_ADDRESS).call()
    assert execution_info.result == (1,)

    await token_contract.mint(DERIVED_TOKEN_OWNER_ADDRESS, DERIVED_TOKEN_ID, [(token_contract.contract_address, ORIGINAL_TOKEN_ID)]).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.parentTokensOf(DERIVED_TOKEN_ID).call()
    assert execution_info.result == ([(token_contract.contract_address, ORIGINAL_TOKEN_ID)],)


@pytest.mark.asyncio
async def test_DerivativeToken_transfer(contracts_factory):
    _, token_contract = contracts_factory

    await token_contract.mint(ORIGINAL_TOKEN_OWNER_ADDRESS, ORIGINAL_TOKEN_ID, []).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    await token_contract.mint(ORIGINAL_TOKEN_OWNER_ADDRESS, DERIVED_TOKEN_ID, [(token_contract.contract_address, ORIGINAL_TOKEN_ID)]).execute(caller_address=COLLECTION_OWNER_ADDRESS)

    execution_info = await token_contract.allowToTransfer(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == (1,)
    execution_info = await token_contract.allowTransfer(DERIVED_TOKEN_ID).call()
    assert execution_info.result == (1,)

    await token_contract.setCollectionSettings(str_to_felt('allow_transfer'), 1).execute(caller_address=COLLECTION_OWNER_ADDRESS)
    execution_info = await token_contract.collectionSettings(str_to_felt('allow_transfer')).call()
    assert execution_info.result == (1,)
    execution_info = await token_contract.allowToTransfer(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == (1,)
    execution_info = await token_contract.allowTransfer(DERIVED_TOKEN_ID).call()
    assert execution_info.result == (1,)

    await token_contract.setTokenSettings(ORIGINAL_TOKEN_ID, str_to_felt('allow_transfer'), 2).execute(caller_address=ORIGINAL_TOKEN_OWNER_ADDRESS)
    execution_info = await token_contract.tokenSettings(ORIGINAL_TOKEN_ID, str_to_felt('allow_transfer')).call()
    assert execution_info.result == (2,)
    execution_info = await token_contract.allowToTransfer(ORIGINAL_TOKEN_ID).call()
    assert execution_info.result == (0,)
    execution_info = await token_contract.allowTransfer(DERIVED_TOKEN_ID).call()
    assert execution_info.result == (0,)
