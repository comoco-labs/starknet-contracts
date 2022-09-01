# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.common.token import Token

#
# Storage
#

@storage_var
func Derived_parent_tokens_len(token_id : Uint256) -> (len : felt):
end

@storage_var
func Derived_parent_tokens(token_id : Uint256, index : felt) -> (token : Token):
end

namespace Derived:

    #
    # Getters
    #

    func parent_tokens{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
    }(token_id : Uint256) -> (parent_tokens_len : felt, parent_tokens : Token*):
        alloc_locals
        let (local parent_tokens_len) = Derived_parent_tokens_len.read(token_id)
        let (local parent_tokens : Token*) = alloc()

        _parent_tokens(token_id, parent_tokens_len, parent_tokens)
        return (parent_tokens_len, parent_tokens)
    end

    #
    # Externals
    #

    func set_parent_tokens{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
    }(token_id : Uint256, parent_tokens_len : felt, parent_tokens : Token*):
        _set_parent_tokens(token_id, parent_tokens_len, parent_tokens)
        Derived_parent_tokens_len.write(token_id, parent_tokens_len)
        return ()
    end

    #
    # Internals
    #

    func _parent_tokens{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
    }(token_id : Uint256, parent_tokens_len : felt, parent_tokens : Token*):
        if parent_tokens_len == 0:
            return ()
        end

        let (token) = Derived_parent_tokens.read(token_id, parent_tokens_len - 1)
        assert [parent_tokens] = token
        _parent_tokens(token_id, parent_tokens_len - 1, parent_tokens + Token.SIZE)
        return ()
    end

    func _set_parent_tokens{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
    }(token_id : Uint256, parent_tokens_len : felt, parent_tokens : Token*):
        if parent_tokens_len == 0:
            return ()
        end

        Derived_parent_tokens.write(token_id, parent_tokens_len - 1, [parent_tokens])
        _set_parent_tokens(token_id, parent_tokens_len - 1, parent_tokens + Token.SIZE)
        return ()
    end

end
