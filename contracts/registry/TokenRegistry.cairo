// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.upgrades.library import Proxy

from contracts.registry.interface import IOwner

//
// Constants
//

const VERSION = 3;

//
// Events
//

@event
func PrimaryTokenAddressChanged(secondaryAddr: felt, previousPrimaryAddr: felt, newPrimaryAddr: felt) {
}

//
// Storage
//

@storage_var
func TokenRegistry_primary_token_addr(secondary_addr: felt) -> (primary_addr: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        proxyAdmin: felt
) {
    Proxy.initializer(proxyAdmin);
    return ();
}

//
// Modifiers
//

func assert_only_contract_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
) {
    let (caller) = get_caller_address();
    let (owner) = IOwner.owner(address);
    with_attr error_message("TokenRegistry: caller is not contract owner") {
        assert caller = owner;
    }
    return ();
}

//
// Getters
//

@view
func version{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        version: felt
) {
    return (version=VERSION);
}

@view
func getPrimaryTokenAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        secondaryAddr: felt
) -> (
        primaryAddr: felt
) {
    with_attr error_message("TokenRegistry: secondaryAddr is the zero address") {
        assert_not_zero(secondaryAddr);
    }
    let (primaryAddr) = TokenRegistry_primary_token_addr.read(secondaryAddr);
    return (primaryAddr=primaryAddr);
}

@view
func getProxyAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        admin: felt
) {
    let (admin) = Proxy.get_admin();
    return (admin=admin);
}

//
// Externals
//

@external
func setPrimaryTokenAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        secondaryAddr: felt,
        newPrimaryAddr: felt
) {
    with_attr error_message("TokenRegistry: secondaryAddr is the zero address") {
        assert_not_zero(secondaryAddr);
    }
    assert_only_contract_owner(secondaryAddr);
    let (previousPrimaryAddr) = TokenRegistry_primary_token_addr.read(secondaryAddr);
    TokenRegistry_primary_token_addr.write(secondaryAddr, newPrimaryAddr);
    PrimaryTokenAddressChanged.emit(secondaryAddr, previousPrimaryAddr, newPrimaryAddr);
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newImplementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(newImplementation);
    return ();
}

@external
func setProxyAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newAdmin: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_admin(newAdmin);
    return ();
}
