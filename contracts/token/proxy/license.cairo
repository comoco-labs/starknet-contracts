// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

//
// Events
//

@event
func LicenseChanged(previousLicense: felt, newLicense: felt) {
}

//
// Storage
//

@storage_var
func LicenseProxy_license() -> (license: felt) {
}

namespace LicenseProxy {

    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        license: felt
    ) {
        _update_license(license);
        return ();
    }

    //
    // Getters
    //

    func license{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (
            license: felt
    ) {
        let (license) = LicenseProxy_license.read();
        return (license=license);
    }

    //
    // Internals
    //

    func _update_license{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            new_license: felt
    ) {
        with_attr error_message("LicenseProxy: new_license is the zero address") {
            assert_not_zero(new_license);
        }
        let (previous_license) = LicenseProxy_license.read();
        LicenseProxy_license.write(new_license);
        LicenseChanged.emit(previous_license, new_license);
        return ();
    }

}
