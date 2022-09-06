# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check

from contracts.common.royalty import Royalty

#
# Getters
#

@view
func version{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (
        version : felt
):
    return ('version')
end

@view
func allowTransfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        allowed : felt
):
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256"):
        uint256_check(tokenId)
    end
    return (TRUE)
end

@view
func allowMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        allowed : felt
):
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256"):
        uint256_check(tokenId)
    end
    return (FALSE)
end

@view
func royalties{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
) -> (
        royalties_len : felt, royalties : Royalty*
):
    alloc_locals
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256"):
        uint256_check(tokenId)
    end
    let (local royalties : Royalty*) = alloc()
    return (0, royalties)
end

@view
func collectionSettings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        key : felt
) -> (
        value : felt
):
    return (0)
end

@view
func tokenSettings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256, key : felt
) -> (
        value : felt
):
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256"):
        uint256_check(tokenId)
    end
    return (0)
end

#
# Externals
#

@external
func setCollectionSettings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        key : felt, value : felt
):
    return ()
end

@external
func setTokenSettings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256, key : felt, value : felt
):
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256"):
        uint256_check(tokenId)
    end
    return ()
end
