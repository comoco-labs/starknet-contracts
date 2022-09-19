// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_check

//
// Storage
//

@storage_var
func Authorable_authors(token_id: Uint256) -> (author: felt) {
}

namespace Authorable {

    //
    // Getters
    //

    func author_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256
    ) -> (
            author: felt
    ) {
        with_attr error_mesage("Authorable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        let (author) = Authorable_authors.read(token_id);
        with_attr error_message("Authorable: author query for nonexistent token") {
            assert_not_zero(author);
        }
        return (author=author);
    }

    //
    // Public
    //

    func set_author{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            author: felt
    ) {
        with_attr error_mesage("Authorable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("Authorable: author is the zero address") {
            assert_not_zero(author);
        }
        Authorable_authors.write(token_id, author);
        return ();
    }

}
