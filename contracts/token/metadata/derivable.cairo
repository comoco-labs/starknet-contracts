# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check

from contracts.common.token import Token

#
# Storage
#

@storage_var
func Derivable_parent_tokens_len(token_id : Uint256) -> (len : felt):
end

@storage_var
func Derivable_parent_tokens(token_id : Uint256, index : felt) -> (token : Token):
end

@storage_var
func Derivable_child_tokens_len(token_id : Uint256) -> (len : felt):
end

@storage_var
func Derivable_child_tokens(token_id : Uint256, index : felt) -> (token : Token):
end

namespace Derivable:

    #
    # Getters
    #

    func parent_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            token_id : Uint256
    ) -> (
            parent_tokens_len : felt,
            parent_tokens : Token*
    ):
        alloc_locals
        with_attr error_message("Derivable: token_id is not a valid Uint256"):
            uint256_check(token_id)
        end

        let (local parent_tokens_len) = Derivable_parent_tokens_len.read(token_id)
        let (local parent_tokens : Token*) = alloc()
        _parent_tokens(token_id, parent_tokens_len, parent_tokens)
        return (parent_tokens_len, parent_tokens)
    end

    func child_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            token_id : Uint256
    ) -> (
            child_tokens_len : felt,
            child_tokens : Token*
    ):
        alloc_locals
        with_attr error_message("Derivable: token_id is not a valid Uint256"):
            uint256_check(token_id)
        end

        let (local child_tokens_len) = Derivable_child_tokens_len.read(token_id)
        let (local child_tokens : Token*) = alloc()
        _child_tokens(token_id, child_tokens_len, child_tokens)
        return (child_tokens_len, child_tokens)
    end

    #
    # Externals
    #

    func set_parent_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            token_id : Uint256,
            parent_tokens_len : felt,
            parent_tokens : Token*
    ):
        with_attr error_message("Derivable: token_id is not a valid Uint256"):
            uint256_check(token_id)
        end

        _set_parent_tokens(token_id, parent_tokens_len, parent_tokens)
        Derivable_parent_tokens_len.write(token_id, parent_tokens_len)
        return ()
    end

    func set_child_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            token_id : Uint256,
            child_tokens_len : felt,
            child_tokens : Token*
    ):
         with_attr error_message("Derivable: token_id is not a valid Uint256"):
            uint256_check(token_id)
        end

        _set_child_tokens(token_id, child_tokens_len, child_tokens)
        Derivable_child_tokens_len.write(token_id, child_tokens_len)
        return ()
    end

    #
    # Internals
    #

    func _parent_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            token_id : Uint256,
            parent_tokens_len : felt,
            parent_tokens : Token*
    ):
        if parent_tokens_len == 0:
            return ()
        end

        let (token) = Derivable_parent_tokens.read(token_id, parent_tokens_len - 1)
        assert [parent_tokens] = token
        _parent_tokens(token_id, parent_tokens_len - 1, parent_tokens + Token.SIZE)
        return ()
    end

    func _child_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            token_id : Uint256,
            child_tokens_len : felt,
            child_tokens : Token*
    ):
        if child_tokens_len == 0:
            return ()
        end

        let (token) = Derivable_child_tokens.read(token_id, child_tokens_len - 1)
        assert [child_tokens] = token
        _child_tokens(token_id, child_tokens_len - 1, child_tokens + Token.SIZE)
        return ()
    end

    func _set_parent_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            token_id : Uint256,
            parent_tokens_len : felt,
            parent_tokens : Token*
    ):
        if parent_tokens_len == 0:
            return ()
        end

        Derivable_parent_tokens.write(token_id, parent_tokens_len - 1, [parent_tokens])
        _set_parent_tokens(token_id, parent_tokens_len - 1, parent_tokens + Token.SIZE)
        return ()
    end

    func _set_child_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            token_id : Uint256,
            child_tokens_len : felt,
            child_tokens : Token*
    ):
        if child_tokens_len == 0:
            return ()
        end

        Derivable_child_tokens.write(token_id, child_tokens_len - 1, [child_tokens])
        _set_child_tokens(token_id, child_tokens_len - 1, child_tokens + Token.SIZE)
        return ()
    end

end
