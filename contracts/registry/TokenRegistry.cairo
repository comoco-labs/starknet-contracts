// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable.library import Ownable

//
// Events
//

@event
func MappingInfoRegistered(l1Addr: felt, l2Addr: felt, sot: felt) {
}

@event
func MappingInfoUnregistered(l1Addr: felt, l2Addr: felt, sot: felt) {
}

//
// Storage
//

@storage_var
func TokenRegistry_l2_addr_for_l1(l1_addr: felt) -> (l2_addr: felt) {
}

@storage_var
func TokenRegistry_l1_addr_for_l2(l2_addr: felt) -> (l1_addr: felt) {
}

@storage_var
func TokenRegistry_source_of_truth(l1_addr: felt, l2_addr: felt) -> (sot: felt) {
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt
) {
    Ownable.initializer(owner);
    return ();
}

//
// Getters
//

@view
func getMappingInfoForL1Address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        l1Addr: felt
) -> (
        l2Addr: felt,
        sot: felt
) {
    with_attr error_message("TokenRegistry: l1Addr is the zero address") {
        assert_not_zero(l1Addr);
    }
    let (l2Addr) = TokenRegistry_l2_addr_for_l1.read(l1Addr);
    if (l2Addr == 0) {
        return (l2Addr=0, sot=0);
    }
    let (sot) = TokenRegistry_source_of_truth.read(l1Addr, l2Addr);
    return (l2Addr=l2Addr, sot=sot);
}

@view
func getMappingInfoForL2Address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        l2Addr: felt
) -> (
        l1Addr: felt,
        sot: felt
) {
    with_attr error_message("TokenRegistry: l2Addr is the zero address") {
        assert_not_zero(l2Addr);
    }
    let (l1Addr) = TokenRegistry_l1_addr_for_l2.read(l2Addr);
    if (l1Addr == 0) {
        return (l1Addr=0, sot=0);
    }
    let (sot) = TokenRegistry_source_of_truth.read(l1Addr, l2Addr);
    return (l1Addr=l1Addr, sot=sot);
}

@view
func getMappingInfoForAddresses{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        l1Addr: felt,
        l2Addr: felt
) -> (
        sot: felt
) {
    with_attr error_message("TokenRegistry: either l1Addr or l2Addr is the zero address") {
        assert_not_zero(l1Addr * l2Addr);
    }
    let (sot) = TokenRegistry_source_of_truth.read(l1Addr, l2Addr);
    return (sot=sot);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        owner: felt
) {
    let (owner) = Ownable.owner();
    return (owner=owner);
}

//
// Externals
//

@external
func setMappingInfoForAddresses{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        l1Addr: felt,
        l2Addr: felt,
        sot: felt
) {
    Ownable.assert_only_owner();
    with_attr error_message("TokenRegistry: either l1Addr or l2Addr is the zero address") {
        assert_not_zero(l1Addr * l2Addr);
    }
    with_attr error_message("TokenRegistry: sot must be either 1 or 2") {
        assert (sot - 1) * (sot - 2) = 0;
    }
    let (existingL2Addr) = TokenRegistry_l2_addr_for_l1.read(l1Addr);
    with_attr error_message("TokenRegistry: l1Addr already exists") {
        assert existingL2Addr = 0;
    }
    let (existingL1Addr) = TokenRegistry_l1_addr_for_l2.read(l2Addr);
    with_attr error_message("TokenRegistry: l2Addr already exists") {
        assert existingL1Addr = 0;
    }
    TokenRegistry_l2_addr_for_l1.write(l1Addr, l2Addr);
    TokenRegistry_l1_addr_for_l2.write(l2Addr, l1Addr);
    TokenRegistry_source_of_truth.write(l1Addr, l2Addr, sot);
    MappingInfoRegistered.emit(l1Addr, l2Addr, sot);
    return ();
}

@external
func clearMappingInfoForAddresses{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        l1Addr: felt,
        l2Addr: felt
) {
    Ownable.assert_only_owner();
    with_attr error_message("TokenRegistry: either l1Addr or l2Addr is the zero address") {
        assert_not_zero(l1Addr * l2Addr);
    }
    let (sot) = TokenRegistry_source_of_truth.read(l1Addr, l2Addr);
    with_attr error_message("TokenRegistry: l1Addr and l2Addr mapping does not exist") {
        assert_not_zero(sot);
    }
    TokenRegistry_l2_addr_for_l1.write(l1Addr, 0);
    TokenRegistry_l1_addr_for_l2.write(l2Addr, 0);
    TokenRegistry_source_of_truth.write(l1Addr, l2Addr, 0);
    MappingInfoUnregistered.emit(l1Addr, l2Addr, sot);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}
