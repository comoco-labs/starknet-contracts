// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check

from contracts.common.token import Token

//
// Events
//

@event
func ParentTokensChanged(
        tokenId: Uint256,
        previousParentTokens_len: felt, previousParentTokens: Token*,
        newParentTokens_len: felt, newParentTokens: Token*) {
}

@event
func ChildTokensChanged(
        tokenId: Uint256,
        previousChildTokens_len: felt, previousChildTokens: Token*,
        newChildTokens_len: felt, newChildTokens: Token*) {
}

//
// Storage
//

@storage_var
func Derivable_parent_tokens_len(token_id: Uint256) -> (len: felt) {
}

@storage_var
func Derivable_parent_tokens(token_id: Uint256, index: felt) -> (token: Token) {
}

@storage_var
func Derivable_is_parent_token(token_id: Uint256, other_token: Token) -> (res: felt) {
}

@storage_var
func Derivable_child_tokens_len(token_id: Uint256) -> (len: felt) {
}

@storage_var
func Derivable_child_tokens(token_id: Uint256, index: felt) -> (token: Token) {
}

@storage_var
func Derivable_is_child_token(token_id: Uint256, other_token: Token) -> (res: felt) {
}

namespace Derivable {

    //
    // Getters
    //

    func parent_tokens_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256
    ) -> (
            parent_tokens_len: felt,
            parent_tokens: Token*
    ) {
        alloc_locals;
        with_attr error_message("Derivable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }

        let (local parent_tokens_len) = Derivable_parent_tokens_len.read(token_id);
        let (local parent_tokens: Token*) = alloc();
        _parent_tokens_of(token_id, parent_tokens_len, parent_tokens);
        return (parent_tokens_len=parent_tokens_len, parent_tokens=parent_tokens);
    }

    func child_tokens_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256
    ) -> (
            child_tokens_len: felt,
            child_tokens: Token*
    ) {
        alloc_locals;
        with_attr error_message("Derivable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }

        let (local child_tokens_len) = Derivable_child_tokens_len.read(token_id);
        let (local child_tokens: Token*) = alloc();
        _child_tokens_of(token_id, child_tokens_len, child_tokens);
        return (child_tokens_len=child_tokens_len, child_tokens=child_tokens);
    }

    func is_parent_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            other_token: Token
    ) -> felt {
        with_attr error_message("Derivable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        let (res) = Derivable_is_parent_token.read(token_id, other_token);
        return res;
    }

    func is_child_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            other_token: Token
    ) -> felt {
        with_attr error_message("Derivable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        let (res) = Derivable_is_child_token.read(token_id, other_token);
        return res;
    }

    //
    // Public
    //

    func set_parent_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            new_parent_tokens_len: felt,
            new_parent_tokens: Token*
    ) {
        alloc_locals;
        with_attr error_message("Derivable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }

        let (previous_parent_tokens_len, previous_parent_tokens) = parent_tokens_of(token_id);
        _clear_is_parent_token(token_id, previous_parent_tokens_len, previous_parent_tokens);
        _set_parent_tokens(token_id, new_parent_tokens_len, new_parent_tokens);
        Derivable_parent_tokens_len.write(token_id, new_parent_tokens_len);
        ParentTokensChanged.emit(
                token_id,
                previous_parent_tokens_len, previous_parent_tokens,
                new_parent_tokens_len, new_parent_tokens
        );
        return ();
    }

    func set_child_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            new_child_tokens_len: felt,
            new_child_tokens: Token*
    ) {
        alloc_locals;
        with_attr error_message("Derivable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }

        let (previous_child_tokens_len, previous_child_tokens) = child_tokens_of(token_id);
        _set_child_tokens(token_id, new_child_tokens_len, new_child_tokens);
        _clear_is_child_token(token_id, previous_child_tokens_len, previous_child_tokens);
        Derivable_child_tokens_len.write(token_id, new_child_tokens_len);
        ChildTokensChanged.emit(
                token_id,
                previous_child_tokens_len, previous_child_tokens,
                new_child_tokens_len, new_child_tokens
        );
        return ();
    }

}

//
// Private
//

func _parent_tokens_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        parent_tokens_index: felt,
        parent_tokens_ptr: Token*
) {
    if (parent_tokens_index == 0) {
        return ();
    }

    let (token) = Derivable_parent_tokens.read(token_id, parent_tokens_index - 1);
    assert [parent_tokens_ptr] = token;
    _parent_tokens_of(token_id, parent_tokens_index - 1, parent_tokens_ptr + Token.SIZE);
    return ();
}

func _child_tokens_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        child_tokens_index: felt,
        child_tokens_ptr: Token*
) {
    if (child_tokens_index == 0) {
        return ();
    }

    let (token) = Derivable_child_tokens.read(token_id, child_tokens_index - 1);
    assert [child_tokens_ptr] = token;
    _child_tokens_of(token_id, child_tokens_index - 1, child_tokens_ptr + Token.SIZE);
    return ();
}

func _clear_is_parent_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        parent_tokens_index: felt,
        parent_tokens_ptr: Token*
) {
    if (parent_tokens_index == 0) {
        return ();
    }

    Derivable_is_parent_token.write(token_id, [parent_tokens_ptr], FALSE);
    _clear_is_parent_token(token_id, parent_tokens_index - 1, parent_tokens_ptr + Token.SIZE);
    return ();
}

func _clear_is_child_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        child_tokens_index: felt,
        child_tokens_ptr: Token*
) {
    if (child_tokens_index == 0) {
        return ();
    }

    Derivable_is_child_token.write(token_id, [child_tokens_ptr], FALSE);
    _clear_is_child_token(token_id, child_tokens_index - 1, child_tokens_ptr + Token.SIZE);
    return ();
}

func _set_parent_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        parent_tokens_index: felt,
        parent_tokens_ptr: Token*
) {
    if (parent_tokens_index == 0) {
        return ();
    }

    Derivable_parent_tokens.write(token_id, parent_tokens_index - 1, [parent_tokens_ptr]);
    Derivable_is_parent_token.write(token_id, [parent_tokens_ptr], TRUE);
    _set_parent_tokens(token_id, parent_tokens_index - 1, parent_tokens_ptr + Token.SIZE);
    return ();
}

func _set_child_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        child_tokens_index: felt,
        child_tokens_ptr: Token*
) {
    if (child_tokens_index == 0) {
        return ();
    }

    Derivable_child_tokens.write(token_id, child_tokens_index - 1, [child_tokens_ptr]);
    Derivable_is_child_token.write(token_id, [child_tokens_ptr], TRUE);
    _set_child_tokens(token_id, child_tokens_index - 1, child_tokens_ptr + Token.SIZE);
    return ();
}
