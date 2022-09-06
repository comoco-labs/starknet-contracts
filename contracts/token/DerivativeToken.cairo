# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721

from contracts.common.royalty import Royalty
from contracts.common.token import Token
from contracts.license.interface import IDerivativeLicense
from contracts.registry.interface import ITokenRegistry
from contracts.token.metadata.authorable import Authorable
from contracts.token.metadata.derivable import Derivable
from contracts.token.proxy.license import LicenseProxy
from contracts.token.proxy.registry import RegistryProxy

#
# Constants
#

const OWNER_ROLE = 0
const ADMIN_ROLE = 1

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt,
        symbol : felt,
        owner : felt,
        license : felt,
        registry : felt
):
    ERC721.initializer(name, symbol)
    Ownable.initializer(owner)
    AccessControl.initializer()
    AccessControl._set_role_admin(ADMIN_ROLE, OWNER_ROLE)
    AccessControl._set_role_admin(OWNER_ROLE, OWNER_ROLE)
    AccessControl._grant_role(OWNER_ROLE, owner)
    LicenseProxy.initializer(license)
    RegistryProxy.initializer(registry)
    return ()
end

#
# Modifiers
#

func assert_only_owner_or_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
):
    let (authorized) = _is_owner_or_admin()
    with_attr error_message("DerivativeToken: caller is not owner or admin"):
        assert authorized = TRUE
    end
    return ()
end

#
# Getters
#

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        interfaceId : felt
) -> (
        success : felt
):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (
        name : felt
):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (
        symbol : felt
):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt
) -> (
        balance : Uint256
):
    let (balance) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        owner : felt
):
    let (owner) = ERC721.owner_of(tokenId)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        approved : felt
):
    let (approved) = ERC721.get_approved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt,
        operator : felt
) -> (
        isApproved : felt
):
    let (isApproved) = ERC721.is_approved_for_all(owner, operator)
    return (isApproved)
end

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        tokenURI : felt
):
    let (tokenURI) = ERC721.token_uri(tokenId)
    return (tokenURI)
end

@view
func authorOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        author : felt
):
    let (author) = Authorable.author_of(tokenId)
    return (author)
end

@view
func parentTokensOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        parentTokens_len : felt,
        parentTokens : Token*
):
    let (parentTokens_len, parentTokens) = Derivable.parent_tokens_of(tokenId)
    return (parentTokens_len, parentTokens)
end

@view
func childTokensOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        childTokens_len : felt,
        childTokens : Token*
):
    let (childTokens_len, childTokens) = Derivable.child_tokens_of(tokenId)
    return (childTokens_len, childTokens)
end

@view
func licenseVersion{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (
        version : felt
):
    let (license) = LicenseProxy.license()
    let (version) = IDerivativeLicense.library_call_version(license)
    return (version)
end

@view
func royalties{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        royalties_len : felt, royalties : Royalty*
):
    let (license) = LicenseProxy.license()
    let (royalties_len, royalties) = IDerivativeLicense.library_call_royalties(license, tokenId)
    return (royalties_len, royalties)
end

@view
func collectionSettings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        key : felt
) -> (
        value : felt
):
    let (license) = LicenseProxy.license()
    let (value) = IDerivativeLicense.library_call_collectionSettings(license, key)
    return (value)
end

@view
func tokenSettings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256, key : felt
) -> (
        value : felt
):
    let (license) = LicenseProxy.license()
    let (value) = IDerivativeLicense.library_call_tokenSettings(license, tokenId, key)
    return (value)
end

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (
        owner : felt
):
    let (owner) = Ownable.owner()
    return (owner)
end

@view
func isAdmin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        user : felt
) -> (
        res : felt
):
    let (res) = AccessControl.has_role(ADMIN_ROLE, user)
    return (res)
end

@view
func license{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (
        license : felt
):
    let (license) = LicenseProxy.license()
    return (license)
end

@view
func registry{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (
        registry : felt
):
    let (registry) = RegistryProxy.registry()
    return (registry)
end

#
# Externals
#

@external
func approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt,
        tokenId : Uint256
):
    ERC721.approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt,
        approved : felt
):
    ERC721.set_approval_for_all(operator, approved)
    return ()
end

@external
func transferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt,
        to : felt,
        tokenId : Uint256
):
    # TODO: Check DerivativeLicense
    ERC721.transfer_from(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt,
        to : felt,
        tokenId : Uint256,
        data_len : felt,
        data : felt*
):
    # TODO: Check DerivativeLicense
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data)
    return ()
end

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt,
        tokenId : Uint256
):
    # TODO: Check DerivativeLicense and TokenRegistry
    assert_only_owner_or_admin()
    ERC721._mint(to, tokenId)
    # ERC721._set_token_uri(tokenId, tokenURI)
    return ()
end

@external
func setCollectionSettings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        key : felt, value : felt
):
    Ownable.assert_only_owner()
    let (license) = LicenseProxy.license()
    IDerivativeLicense.library_call_setCollectionSettings(license, key, value)
    return ()
end

@external
func setTokenSettings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256, key : felt, value : felt
):
    ERC721.assert_only_token_owner(tokenId)
    let (license) = LicenseProxy.license()
    IDerivativeLicense.library_call_setTokenSettings(license, tokenId, key, value)
    return ()
end

@external
func transferOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        newOwner : felt
):
    Ownable.transfer_ownership(newOwner)
    setAdmin(newOwner, FALSE)
    AccessControl.grant_role(OWNER_ROLE, newOwner)
    let (caller) = get_caller_address()
    AccessControl.renounce_role(OWNER_ROLE, caller)
    return ()
end

@external
func setAdmin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        user : felt, granted : felt
):
    with_attr error_message("DerivativeToken: user is the zero address"):
        assert_not_zero(user)
    end
    let (caller) = get_caller_address()
    with_attr error_message("DerivativeToken: cannot set caller as admin"):
        assert_not_equal(user, caller)
    end
    with_attr error_message("DerivativeToken: granted is not a Cairo boolean"):
        assert granted * (granted - 1) = 0
    end
    if granted == TRUE:
        AccessControl.grant_role(ADMIN_ROLE, user)
    else:
        AccessControl.revoke_role(ADMIN_ROLE, user)
    end
    return ()
end

@external
func updateLicense{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        newLicense : felt
):
    assert_only_owner_or_admin()
    LicenseProxy._update_license(newLicense)
    return ()
end

@external
func updateRegistry{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        newRegistry : felt
):
    assert_only_owner_or_admin()
    RegistryProxy._update_registry(newRegistry)
    return ()
end

#
# Internals
#

func _is_owner_or_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (
        res : felt
):
    let (caller) = get_caller_address()

    let (owner) = Ownable.owner()
    if caller == owner:
        return (TRUE)
    end

    let (res) = AccessControl.has_role(ADMIN_ROLE, caller)
    return (res)
end
