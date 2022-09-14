// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check

from contracts.common.royalty import Royalty

//
// Getters
//

@view
func version{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        version: felt
) {
    return (version=1);
}

@view
func allowTransfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        allowed: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    return (allowed=TRUE);
}

@view
func allowMint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        allowed: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    return (allowed=FALSE);
}

@view
func royalties{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        royalties_len: felt,
        royalties: Royalty*
) {
    alloc_locals;
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    let (local royalties: Royalty*) = alloc();
    return (royalties_len=0, royalties=royalties);
}

@view
func collectionSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt
) -> (
        value: felt
) {
    return (value=0);
}

@view
func tokenSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt
) -> (
        value: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    return (value=0);
}

//
// Externals
//

@external
func setCollectionSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt,
        value: felt
) {
    return ();
}

@external
func setTokenSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        value: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    return ();
}
