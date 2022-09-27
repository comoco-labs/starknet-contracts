// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy

//
// Constants
//

const VERSION = 1;

//
// Events
//

@event
func MappingInfoRegistered(l1Addr: felt, l2Addr: felt, sot: felt) {
}

@event
func MappingInfoUnregistered(l1Addr: felt, l2Addr: felt) {
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
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        proxyAdmin: felt,
        owner: felt
) {
    Proxy.initializer(proxyAdmin);
    Ownable.initializer(owner);
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

@view
func getImplementationHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        implementation: felt
) {
    let (implementation) = Proxy.get_implementation_hash();
    return (implementation=implementation);
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
    if (existingL2Addr * (existingL2Addr - l2Addr) != 0) {
        TokenRegistry_l1_addr_for_l2.write(existingL2Addr, 0);
        TokenRegistry_source_of_truth.write(l1Addr, existingL2Addr, 0);
        MappingInfoUnregistered.emit(l1Addr, existingL2Addr);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    let (existingL1Addr) = TokenRegistry_l1_addr_for_l2.read(l2Addr);
    if (existingL1Addr * (existingL1Addr - l1Addr) != 0) {
        TokenRegistry_l2_addr_for_l1.write(existingL1Addr, 0);
        TokenRegistry_source_of_truth.write(existingL1Addr, l2Addr, 0);
        MappingInfoUnregistered.emit(existingL1Addr, l2Addr);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
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
    MappingInfoUnregistered.emit(l1Addr, l2Addr);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
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
