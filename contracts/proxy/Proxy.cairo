// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call, library_call_l1_handler

from openzeppelin.upgrades.library import Proxy

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        implementation: felt,
        selector: felt,
        calldata_len: felt,
        calldata: felt*
) {
    alloc_locals;
    Proxy._set_implementation_hash(implementation);
    if (selector != 0) {
        library_call(
                class_hash=implementation,
                function_selector=selector,
                calldata_size=calldata_len,
                calldata=calldata
        );
    }
    return ();
}

//
// Getter
//

@view
func getImplementation{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        implementation: felt
) {
    let (implementation) = Proxy.get_implementation_hash();
    return (implementation=implementation);
}

//
// Fallback
//

@external
@raw_input
@raw_output
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
) -> (
        retdata_size: felt,
        retdata: felt*
) {
    let (implementation) = Proxy.get_implementation_hash();
    let (retdata_size: felt, retdata: felt*) = library_call(
            class_hash=implementation,
            function_selector=selector,
            calldata_size=calldata_size,
            calldata=calldata
    );
    return (retdata_size=retdata_size, retdata=retdata);
}

@l1_handler
@raw_input
func __l1_default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
) {
    let (implementation) = Proxy.get_implementation_hash();
    library_call_l1_handler(
            class_hash=implementation,
            function_selector=selector,
            calldata_size=calldata_size,
            calldata=calldata
    );
    return ();
}
