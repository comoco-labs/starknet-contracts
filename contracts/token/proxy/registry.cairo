// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

//
// Events
//

@event
func RegistryChanged(previousRegistry: felt, newRegistry: felt) {
}

//
// Storage
//

@storage_var
func RegistryProxy_registry() -> (registry: felt) {
}

namespace RegistryProxy {

    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        registry: felt
    ) {
        _update_registry(registry);
        return ();
    }

    //
    // Getters
    //

    func registry{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (
            registry: felt
    ) {
        let (registry) = RegistryProxy_registry.read();
        return (registry=registry);
    }

    //
    // Internals
    //

    func _update_registry{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            new_registry: felt
    ) {
        with_attr error_message("RegistryProxy: new_registry is the zero address") {
            assert_not_zero(new_registry);
        }
        let (previous_registry) = RegistryProxy_registry.read();
        RegistryProxy_registry.write(new_registry);
        RegistryChanged.emit(previous_registry, new_registry);
        return ();
    }

}
