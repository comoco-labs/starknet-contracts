// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check

from openzeppelin.introspection.erc165.library import ERC165

from contracts.common.token import Token
from contracts.token.relations.library import IDERIVATIVERIGHTRELATION_ID

//
// Events
//

@event
func DerivativeRightsAdded(tokenId: Uint256, derivativeRights_len: felt, derivativeRights: Token*) {
}

//
// Storage
//

@storage_var
func Optionable_derivative_rights_len(token_id: Uint256) -> (len: felt) {
}

@storage_var
func Optionable_derivative_rights(token_id: Uint256, index: felt) -> (token: Token) {
}

@storage_var
func Optionable_is_derivative_right(token_id: Uint256, other_token: Token) -> (res: felt) {
}

namespace Optionable {

    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
        ERC165.register_interface(IDERIVATIVERIGHTRELATION_ID);
        return ();
    }

    //
    // Getters
    //

    func derivative_rights_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256
    ) -> (
            derivative_rights_len: felt,
            derivative_rights: Token*
    ) {
        alloc_locals;
        with_attr error_message("Optionable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }

        let (local derivative_rights_len) = Optionable_derivative_rights_len.read(token_id);
        let (local derivative_rights: Token*) = alloc();
        _derivative_rights_of(token_id, derivative_rights_len, 0, derivative_rights);
        return (derivative_rights_len=derivative_rights_len, derivative_rights=derivative_rights);
    }

    func is_derivative_right{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            other_token: Token
    ) -> felt {
        with_attr error_message("Optionable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        let (res) = Optionable_is_derivative_right.read(token_id, other_token);
        return res;
    }

    //
    // Public
    //

    func add_derivative_rights{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            derivative_rights_len: felt,
            derivative_rights: Token*
    ) {
        alloc_locals;
        with_attr error_message("Optionable: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }

        let (previous_derivative_rights_len) = Optionable_derivative_rights_len.read(token_id);
        local new_derivative_rights_len = previous_derivative_rights_len + derivative_rights_len;
        _add_derivative_rights(token_id, new_derivative_rights_len, previous_derivative_rights_len, derivative_rights);
        Optionable_derivative_rights_len.write(token_id, new_derivative_rights_len);
        DerivativeRightsAdded.emit(token_id, derivative_rights_len, derivative_rights);
        return ();
    }

}

//
// Private
//

func _derivative_rights_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        derivative_rights_len: felt,
        derivative_rights_index: felt,
        derivative_rights_ptr: Token*
) {
    if (derivative_rights_index == derivative_rights_len) {
        return ();
    }

    let (token) = Optionable_derivative_rights.read(token_id, derivative_rights_index);
    assert [derivative_rights_ptr] = token;
    _derivative_rights_of(token_id, derivative_rights_len, derivative_rights_index + 1, derivative_rights_ptr + Token.SIZE);
    return ();
}

func _add_derivative_rights{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        derivative_rights_len: felt,
        derivative_rights_index: felt,
        derivative_rights_ptr: Token*
) {
    if (derivative_rights_index == derivative_rights_len) {
        return ();
    }

    Optionable_derivative_rights.write(token_id, derivative_rights_index, [derivative_rights_ptr]);
    Optionable_is_derivative_right.write(token_id, [derivative_rights_ptr], TRUE);
    _add_derivative_rights(token_id, derivative_rights_len, derivative_rights_index + 1, derivative_rights_ptr + Token.SIZE);
    return ();
}
