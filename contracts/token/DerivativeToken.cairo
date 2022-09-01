# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.common.token import Token
from contracts.token.library.derived import Derived

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
}():
    return ()
end

#
# Getters
#

@view
func parent_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
}(token_id : Uint256) -> (parent_tokens_len : felt, parent_tokens : Token*):
    let (parent_tokens_len, parent_tokens) = Derived.parent_tokens(token_id)
    return (parent_tokens_len, parent_tokens)
end

#
# Externals
#

@external
func set_parent_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
}(token_id : Uint256, parent_tokens_len : felt, parent_tokens : Token*):
    Derived.set_parent_tokens(token_id, parent_tokens_len, parent_tokens)
    return ()
end
