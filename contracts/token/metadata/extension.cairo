// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check

//
// Storage
//

@storage_var
func ERC721Ext_token_uri_len(token_id: Uint256) -> (len: felt) {
}

@storage_var
func ERC721Ext_token_uri(token_id: Uint256, index: felt) -> (token_uri: felt) {
}

namespace ERC721Ext {

    //
    // Getters
    //

    func token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256
    ) -> (
            token_uri_len: felt,
            token_uri: felt*
    ) {
        alloc_locals;
        with_attr error_message("ERC721Ext: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }

        let (local token_uri_len) = ERC721Ext_token_uri_len.read(token_id);
        let (local token_uri: felt*) = alloc();
        _token_uri(token_id, token_uri_len, token_uri);
        return (token_uri_len=token_uri_len, token_uri=token_uri);
    }

    //
    // Public
    //

    func set_token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            token_uri_len: felt,
            token_uri: felt*
    ) {
        alloc_locals;
        with_attr error_message("ERC721Ext: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }

        _set_token_uri(token_id, token_uri_len, token_uri);
        ERC721Ext_token_uri_len.write(token_id, token_uri_len);
        return ();
    }

}

//
// Private
//

func _token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        token_uri_index: felt,
        token_uri_ptr: felt*
) {
    if (token_uri_index == 0) {
        return ();
    }

    let (token_uri) = ERC721Ext_token_uri.read(token_id, token_uri_index - 1);
    assert [token_uri_ptr] = token_uri;
    _token_uri(token_id, token_uri_index - 1, token_uri_ptr + 1);
    return ();
}

func _set_token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        token_uri_index: felt,
        token_uri_ptr: felt*
) {
    if (token_uri_index == 0) {
        return ();
    }

    ERC721Ext_token_uri.write(token_id, token_uri_index - 1, [token_uri_ptr]);
    _set_token_uri(token_id, token_uri_index - 1, token_uri_ptr + 1);
    return ();
}
