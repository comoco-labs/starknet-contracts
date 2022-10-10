// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.upgrades.library import Proxy

from contracts.common.royalty import Royalty
from contracts.common.token import Token
from contracts.license.interface import IDerivativeLicense
from contracts.registry.interface import ITokenRegistry
from contracts.token.interface import IDerivativeToken
from contracts.token.metadata.authorable import Authorable
from contracts.token.metadata.derivable import Derivable
from contracts.token.upgrades.license import LicenseProxy
from contracts.token.upgrades.registry import RegistryProxy

//
// Constants
//

const VERSION = 1;

const OWNER_ROLE = 'owner';
const ADMIN_ROLE = 'admin';

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        proxyAdmin: felt,
        name: felt,
        symbol: felt,
        owner: felt,
        license: felt,
        registry: felt
) {
    Proxy.initializer(proxyAdmin);
    ERC721.initializer(name, symbol);
    Ownable.initializer(owner);
    AccessControl.initializer();
    AccessControl._set_role_admin(ADMIN_ROLE, OWNER_ROLE);
    AccessControl._set_role_admin(OWNER_ROLE, OWNER_ROLE);
    AccessControl._grant_role(OWNER_ROLE, owner);
    LicenseProxy.initializer(license);
    RegistryProxy.initializer(registry);
    return ();
}

//
// Modifiers
//

func assert_only_owner_or_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    let (caller) = get_caller_address();
    let authorized = _is_owner_or_admin(caller);
    with_attr error_message("DerivativeToken: caller is not owner or admin") {
        assert authorized = TRUE;
    }
    return ();
}

func assert_only_token_author{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256
) {
    with_attr error_message("DerivativeToken: token_id is not a valid Uint256") {
        uint256_check(token_id);
    }
    let (caller) = get_caller_address();
    let authorized = _is_author_of(caller, token_id);
    with_attr error_message("DerivativeToken: caller is not token author") {
        assert authorized = TRUE;
    }
    return ();
}

//
// Getters
//

@view
func version{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        version: felt
) {
    return (version=VERSION);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        interfaceId: felt
) -> (
        success: felt
) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success=success);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        name: felt
) {
    let (name) = ERC721.name();
    return (name=name);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        symbol: felt
) {
    let (symbol) = ERC721.symbol();
    return (symbol=symbol);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt
) -> (
        balance: Uint256
) {
    let (balance) = ERC721.balance_of(owner);
    return (balance=balance);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        owner: felt
) {
    let (owner) = ERC721.owner_of(tokenId);
    return (owner=owner);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        approved: felt
) {
    let (approved) = ERC721.get_approved(tokenId);
    return (approved=approved);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt,
        operator: felt
) -> (
        isApproved: felt
) {
    let (isApproved) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved=isApproved);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        tokenURI: felt
) {
    let (tokenURI) = ERC721.token_uri(tokenId);
    return (tokenURI=tokenURI);
}

@view
func authorOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        author: felt
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (author) = Authorable.author_of(tokenId);
    return (author=author);
}

@view
func parentTokensOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        parentTokens_len: felt,
        parentTokens: Token*
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (parentTokens_len, parentTokens) = Derivable.parent_tokens_of(tokenId);
    return (parentTokens_len=parentTokens_len, parentTokens=parentTokens);
}

@view
func licenseVersion{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        version: felt
) {
    let (license) = LicenseProxy.license();
    let (version) = IDerivativeLicense.library_call_version(license);
    return (version=version);
}

@view
func allowToTransfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        allowed: felt
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    let (allowed) = IDerivativeLicense.library_call_allowToTransfer(license, tokenId);
    return (allowed=allowed);
}

@view
func allowTransfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        allowed: felt
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (parentTokens_len, parentTokens) = Derivable.parent_tokens_of(tokenId);
    let allowed = _allow_transfer(parentTokens_len, parentTokens);
    return (allowed=allowed);
}

@view
func allowToMint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        to: felt
) -> (
        allowed: felt
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    let (owner) = ERC721.owner_of(tokenId);
    let (allowed) = IDerivativeLicense.library_call_allowToMint(license, tokenId, owner, to);
    return (allowed=allowed);
}

@view
func royalties{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        royalties_len: felt,
        royalties: Royalty*
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    let (royalties_len, royalties) = IDerivativeLicense.library_call_royalties(license, tokenId);
    return (royalties_len=royalties_len, royalties=royalties);
}

@view
func isDragAlong{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        res: felt
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    let (res) = IDerivativeLicense.library_call_isDragAlong(license, tokenId);
    return (res=res);
}

@view
func collectionSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt
) -> (
        value: felt
) {
    let (license) = LicenseProxy.license();
    let (value) = IDerivativeLicense.library_call_collectionSettings(license, key);
    return (value=value);
}

@view
func collectionArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt
) -> (
        values_len: felt,
        values: felt*
) {
    let (license) = LicenseProxy.license();
    let (values_len, values) = IDerivativeLicense.library_call_collectionArraySettings(license, key);
    return (values_len=values_len, values=values);
}

@view
func tokenSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt
) -> (
        value: felt
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    let (value) = IDerivativeLicense.library_call_tokenSettings(license, tokenId, key);
    return (value=value);
}

@view
func tokenArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt
) -> (
        values_len: felt,
        values: felt*
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    let (values_len, values) = IDerivativeLicense.library_call_tokenArraySettings(license, tokenId, key);
    return (values_len=values_len, values=values);
}

@view
func authorSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt
) -> (
        value: felt
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    let (value) = IDerivativeLicense.library_call_authorSettings(license, tokenId, key);
    return (value=value);
}

@view
func authorArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt
) -> (
        values_len: felt,
        values: felt*
) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: query for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    let (values_len, values) = IDerivativeLicense.library_call_authorArraySettings(license, tokenId, key);
    return (values_len=values_len, values=values);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        owner: felt
) {
    let (owner) = Ownable.owner();
    return (owner=owner);
}

@view
func isAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        user: felt
) -> (
        res: felt
) {
    let (res) = AccessControl.has_role(ADMIN_ROLE, user);
    return (res=res);
}

@view
func license{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        license: felt
) {
    let (license) = LicenseProxy.license();
    return (license=license);
}

@view
func registry{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        registry: felt
) {
    let (registry) = RegistryProxy.registry();
    return (registry=registry);
}

@view
func getProxyAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        admin: felt
) {
    let (admin) = Proxy.get_admin();
    return (admin=admin);
}

//
// Externals
//

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt,
        tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        operator: felt,
        approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_: felt,
        to: felt,
        tokenId: Uint256
) {
    alloc_locals;
    let (caller) = get_caller_address();
    let authorized = _is_owner_or_admin(caller);
    if (authorized == FALSE) {
        let authorized = ERC721._is_approved_or_owner(caller, tokenId);
        with_attr error_message("DerivativeToken: caller is not authorized to transfer") {
            assert authorized = TRUE;
        }
        let (authorized) = allowTransfer(tokenId);
        with_attr error_message("DerivativeToken: token is not licensed to transfer") {
            assert authorized = TRUE;
        }
    }
    ERC721.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_: felt,
        to: felt,
        tokenId: Uint256,
        data_len: felt,
        data: felt*
) {
    alloc_locals;
    let (caller) = get_caller_address();
    let authorized = _is_owner_or_admin(caller);
    if (authorized == FALSE) {
        let authorized = ERC721._is_approved_or_owner(caller, tokenId);
        with_attr error_message("DerivativeToken: caller is not authorized to transfer") {
            assert authorized = TRUE;
        }
        let (authorized) = allowTransfer(tokenId);
        with_attr error_message("DerivativeToken: token is not licensed to transfer") {
            assert authorized = TRUE;
        }
    }
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt,
        tokenId: Uint256,
        parentTokens_len: felt,
        parentTokens: Token*
) {
    assert_only_owner_or_admin();
    let (registry) = RegistryProxy.registry();
    let (contract) = get_contract_address();
    let (_, sot) = ITokenRegistry.getMappingInfoForL2Address(registry, contract);
    if (sot == 1) {
        with_attr error_message("DerivativeToken: cannot set parent tokens when minting L1 sourced token") {
            assert parentTokens_len = 0;
        }
    }
    let allowed = _allow_mint(to, parentTokens_len, parentTokens);
    with_attr error_message("DerivativeToken: not licensed by parent tokens") {
        assert allowed = TRUE;
    }

    ERC721._mint(to, tokenId);
    Authorable.set_author(tokenId, to);
    Derivable.set_parent_tokens(tokenId, parentTokens_len, parentTokens);
    return ();
}

@external
func setTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        tokenURI: felt
) {
    assert_only_owner_or_admin();
    ERC721._set_token_uri(tokenId, tokenURI);
    return ();
}

@external
func setAuthor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        author: felt
) {
    assert_only_token_author(tokenId);
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: set for nonexistent token") {
        assert exists = TRUE;
    }
    Authorable.set_author(tokenId, author);
    return ();
}

@external
func setCollectionSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt,
        value: felt
) {
    Ownable.assert_only_owner();
    let (license) = LicenseProxy.license();
    IDerivativeLicense.library_call_setCollectionSettings(license, key, value);
    return ();
}

@external
func setCollectionArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt,
        values_len: felt,
        values: felt*
) {
    alloc_locals;
    Ownable.assert_only_owner();
    let (license) = LicenseProxy.license();
    IDerivativeLicense.library_call_setCollectionArraySettings(license, key, values_len, values);
    return ();
}

@external
func setTokenSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        value: felt
) {
    ERC721.assert_only_token_owner(tokenId);
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: set for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    IDerivativeLicense.library_call_setTokenSettings(license, tokenId, key, value);
    return ();
}

@external
func setTokenArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        values_len: felt,
        values: felt*
) {
    alloc_locals;
    ERC721.assert_only_token_owner(tokenId);
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: set for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    IDerivativeLicense.library_call_setTokenArraySettings(license, tokenId, key, values_len, values);
    return ();
}

@external
func setAuthorSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        value: felt
) {
    assert_only_token_author(tokenId);
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: set for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    IDerivativeLicense.library_call_setAuthorSettings(license, tokenId, key, value);
    return ();
}

@external
func setAuthorArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        values_len: felt,
        values: felt*
) {
    alloc_locals;
    assert_only_token_author(tokenId);
    let exists = ERC721._exists(tokenId);
    with_attr error_message("DerivativeToken: set for nonexistent token") {
        assert exists = TRUE;
    }
    let (license) = LicenseProxy.license();
    IDerivativeLicense.library_call_setAuthorArraySettings(license, tokenId, key, values_len, values);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    setAdmin(newOwner, FALSE);
    AccessControl.grant_role(OWNER_ROLE, newOwner);
    let (caller) = get_caller_address();
    AccessControl.renounce_role(OWNER_ROLE, caller);
    return ();
}

@external
func setAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        user: felt,
        granted: felt
) {
    with_attr error_message("DerivativeToken: user is the zero address") {
        assert_not_zero(user);
    }
    let (caller) = get_caller_address();
    with_attr error_message("DerivativeToken: cannot set caller as admin") {
        assert_not_equal(user, caller);
    }
    with_attr error_message("DerivativeToken: granted is not a Cairo boolean") {
        assert granted * (granted - 1) = 0;
    }
    if (granted == TRUE) {
        AccessControl.grant_role(ADMIN_ROLE, user);
    } else {
        AccessControl.revoke_role(ADMIN_ROLE, user);
    }
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newImplementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(newImplementation);
    return ();
}

@external
func upgradeLicense{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newLicense: felt
) {
    Proxy.assert_only_admin();
    LicenseProxy._set_license(newLicense);
    return ();
}

@external
func upgradeRegistry{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newRegistry: felt
) {
    Proxy.assert_only_admin();
    RegistryProxy._set_registry(newRegistry);
    return ();
}

@external
func setProxyAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newAdmin: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_admin(newAdmin);
    return ();
}

//
// Internals
//

// CAUTION: meant only for fixing accidental errors, but may be abused or cause inconsistency
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) {
    assert_only_owner_or_admin();
    ERC721._burn(tokenId);
    return ();
}

// CAUTION: meant only for fixing accidental errors, but may be abused or cause inconsistency
func setParentTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        parentTokens_len: felt,
        parentTokens: Token*
) {
    assert_only_owner_or_admin();
    let (owner) = ERC721.owner_of(tokenId);
    let allowed = _allow_mint(owner, parentTokens_len, parentTokens);
    with_attr error_message("DerivativeToken: not licensed by parent tokens") {
        assert allowed = TRUE;
    }
    Derivable.set_parent_tokens(tokenId, parentTokens_len, parentTokens);
    return ();
}

//
// Private
//

func _is_owner_or_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        user: felt
) -> felt {
    let (owner) = Ownable.owner();
    if (user == owner) {
        return TRUE;
    }
    let (res) = AccessControl.has_role(ADMIN_ROLE, user);
    return res;
}

func _is_author_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        user: felt,
        token_id: Uint256
) -> felt {
    let (author) = Authorable.author_of(token_id);
    if (user == author) {
        return TRUE;
    } else {
        return FALSE;
    }
}

func _allow_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        parent_tokens_index: felt,
        parent_tokens_ptr: Token*
) -> felt {
    if (parent_tokens_index == 0) {
        return TRUE;
    }
    let (allowed) = IDerivativeToken.allowToTransfer(parent_tokens_ptr.collection, parent_tokens_ptr.id);
    if (allowed == FALSE) {
        return FALSE;
    }
    let (allowed) = IDerivativeToken.allowTransfer(parent_tokens_ptr.collection, parent_tokens_ptr.id);
    if (allowed == FALSE) {
        return FALSE;
    }
    return _allow_transfer(parent_tokens_index - 1, parent_tokens_ptr + Token.SIZE);
}

func _allow_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt,
        parent_tokens_index: felt,
        parent_tokens_ptr: Token*
) -> felt {
    if (parent_tokens_index == 0) {
        return TRUE;
    }
    let (allowed) = IDerivativeToken.allowToMint(parent_tokens_ptr.collection, parent_tokens_ptr.id, to);
    if (allowed == FALSE) {
        return FALSE;
    }
    return _allow_mint(to, parent_tokens_index - 1, parent_tokens_ptr + Token.SIZE);
}
