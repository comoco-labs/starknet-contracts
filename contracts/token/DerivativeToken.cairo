# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165

from contracts.common.token import Token
from contracts.token.library.derived import Derived

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt
):
    Ownable.initializer(owner)
    return ()
end

#
# Getters
#

@view
func getOwner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (
        owner : felt
):
    let (owner) = Ownable.owner()
    return (owner)
end

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
func getParentTokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        parentTokens_len : felt,
        parentTokens : Token*
):
    let (parentTokens_len, parentTokens) = Derived.parent_tokens(tokenId)
    return (parentTokens_len, parentTokens)
end

#
# Externals
#

@external
func transferOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        newOwner : felt
):
    Ownable.transfer_ownership(newOwner)
    return ()
end

@external
func setParentTokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256,
        parentTokens_len : felt,
        parentTokens : Token*
):
    Derived.set_parent_tokens(tokenId, parentTokens_len, parentTokens)
    return ()
end
