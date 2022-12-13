// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check

from contracts.common.royalty import Royalty

//
// Constants
//

// 1: allowed; 2: not allowed
const ALLOW_TRANSFER_KEY = 'allow_transfer';
const ALLOW_TRANSFER_DEFAULT = TRUE;

// 1: drag along; 2: not drag along
const DRAG_ALONG_KEY = 'drag_along';
const DRAG_ALONG_DEFAULT = FALSE;

// Array of licensee addresses
const LICENSEES_KEY = 'licensees';

// Array of unpacked Royalty structs
const ROYALTIES_KEY = 'royalties';

//
// Storage
//

@storage_var
func DerivativeLicense_collection_settings(key: felt) -> (value: felt) {
}

@storage_var
func DerivativeLicense_collection_array_settings(key: felt, index: felt) -> (value: felt) {
}

@storage_var
func DerivativeLicense_token_settings(token_id: Uint256, key: felt) -> (value: felt) {
}

@storage_var
func DerivativeLicense_token_array_settings(token_id: Uint256, key: felt, index: felt) -> (value: felt) {
}

@storage_var
func DerivativeLicense_author_settings(token_id: Uint256, key: felt) -> (value: felt) {
}

@storage_var
func DerivativeLicense_author_array_settings(token_id: Uint256, key: felt, index: felt) -> (value: felt) {
}

namespace DerivativeLicense {

    //
    // Getters
    //

    func allow_to_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256
    ) -> (
            allowed: felt
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        let (collection_value) = DerivativeLicense_collection_settings.read(ALLOW_TRANSFER_KEY);
        let (token_value) = DerivativeLicense_token_settings.read(token_id, ALLOW_TRANSFER_KEY);
        if ((collection_value - 2) * (token_value - 2) == 0) {
            return (allowed=FALSE);
        }
        if ((collection_value - 1) * (token_value - 1) == 0) {
            return (allowed=TRUE);
        }
        return (allowed=ALLOW_TRANSFER_DEFAULT);
    }

    func allow_to_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            owner: felt,
            to : felt
    ) -> (
            allowed: felt
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        if (to == owner) {
            return (allowed=TRUE);
        }
        let (allowed) = in_collection_array_settings(LICENSEES_KEY, to);
        if (allowed == FALSE) {
            let (allowed) = in_token_array_settings(token_id, LICENSEES_KEY, to);
        }
        return (allowed=allowed);
    }

    func royalties{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256
    ) -> (
            royalties_len: felt,
            royalties: Royalty*
    ) {
        alloc_locals;
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        let (local royalties: felt*) = alloc();

        let (collection_royalties_len) = DerivativeLicense_collection_settings.read(ROYALTIES_KEY);
        _collection_array_settings(ROYALTIES_KEY, collection_royalties_len, royalties);
        let (token_royalties_len) = DerivativeLicense_token_settings.read(token_id, ROYALTIES_KEY);
        _token_array_settings(token_id, ROYALTIES_KEY, token_royalties_len, royalties + collection_royalties_len);
        let (author_royalties_len) = DerivativeLicense_author_settings.read(token_id, ROYALTIES_KEY);
        _author_array_settings(token_id, ROYALTIES_KEY, author_royalties_len, royalties + collection_royalties_len + token_royalties_len);

        let royalties_len = collection_royalties_len + token_royalties_len + author_royalties_len;
        return (royalties_len=(royalties_len / Royalty.SIZE), royalties=cast(royalties, Royalty*));
    }

    func is_drag_along{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256
    ) -> (
            res: felt
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        let (collection_value) = DerivativeLicense_collection_settings.read(DRAG_ALONG_KEY);
        let (token_value) = DerivativeLicense_token_settings.read(token_id, DRAG_ALONG_KEY);
        if ((collection_value - 1) * (token_value - 1) == 0) {
            return (res=TRUE);
        }
        if ((collection_value - 2) * (token_value - 2) == 0) {
            return (res=FALSE);
        }
        return (res=DRAG_ALONG_DEFAULT);
    }

    func collection_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            key: felt
    ) -> (
            value: felt
    ) {
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - ALLOW_TRANSFER_KEY) * (key - DRAG_ALONG_KEY) * (key - LICENSEES_KEY) * (key - ROYALTIES_KEY) = 0;
        }
        let (value) = DerivativeLicense_collection_settings.read(key);
        return (value=value);
    }

    func collection_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            key: felt
    ) -> (
            values_len: felt,
            values: felt*
    ) {
        alloc_locals;
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - LICENSEES_KEY) * (key - ROYALTIES_KEY) = 0;
        }
        let (local values: felt*) = alloc();
        let (values_len) = DerivativeLicense_collection_settings.read(key);
        _collection_array_settings(key, values_len, values);
        return (values_len=values_len, values=values);
    }

    func token_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            key: felt
    ) -> (
            value: felt
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - ALLOW_TRANSFER_KEY) * (key - DRAG_ALONG_KEY) * (key - LICENSEES_KEY) * (key - ROYALTIES_KEY) = 0;
        }
        let (value) = DerivativeLicense_token_settings.read(token_id, key);
        return (value=value);
    }

    func token_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            key: felt
    ) -> (
            values_len: felt,
            values: felt*
    ) {
        alloc_locals;
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - LICENSEES_KEY) * (key - ROYALTIES_KEY) = 0;
        }
        let (local values: felt*) = alloc();
        let (values_len) = DerivativeLicense_token_settings.read(token_id, key);
        _token_array_settings(token_id, key, values_len, values);
        return (values_len=values_len, values=values);
    }

    func author_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            key: felt
    ) -> (
            value: felt
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - ROYALTIES_KEY) = 0;
        }
        let (value) = DerivativeLicense_author_settings.read(token_id, key);
        return (value=value);
    }

    func author_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            key: felt
    ) -> (
            values_len: felt,
            values: felt*
    ) {
        alloc_locals;
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - ROYALTIES_KEY) = 0;
        }
        let (local values: felt*) = alloc();
        let (values_len) = DerivativeLicense_author_settings.read(token_id, key);
        _author_array_settings(token_id, key, values_len, values);
        return (values_len=values_len, values=values);
    }

    func in_collection_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            key: felt,
            elem: felt
    ) -> (
            res: felt
    ) {
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - LICENSEES_KEY) = 0;
        }
        let (values_len) = DerivativeLicense_collection_settings.read(key);
        let res = _in_collection_array_settings(key, values_len, elem);
        return (res=res);
    }

    func in_token_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            key: felt,
            elem: felt
    ) -> (
            res: felt
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - LICENSEES_KEY) = 0;
        }
        let (values_len) = DerivativeLicense_token_settings.read(token_id, key);
        let res = _in_token_array_settings(token_id, key, values_len, elem);
        return (res=res);
    }

    //
    // Public
    //

    func set_collection_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            key: felt,
            value: felt
    ) {
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - ALLOW_TRANSFER_KEY) * (key - DRAG_ALONG_KEY) = 0;
        }
        DerivativeLicense_collection_settings.write(key, value);
        return ();
    }

    func set_collection_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            key: felt,
            values_len: felt,
            values: felt*
    ) {
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - LICENSEES_KEY) * (key - ROYALTIES_KEY) = 0;
        }
        _set_collection_array_settings(key, values_len, values);
        DerivativeLicense_collection_settings.write(key, values_len);
        return ();
    }

    func set_token_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            key: felt,
            value: felt
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - ALLOW_TRANSFER_KEY) * (key - DRAG_ALONG_KEY) = 0;
        }
        DerivativeLicense_token_settings.write(token_id, key, value);
        return ();
    }

    func set_token_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            key: felt,
            values_len: felt,
            values: felt*
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - LICENSEES_KEY) * (key - ROYALTIES_KEY) = 0;
        }
        _set_token_array_settings(token_id, key, values_len, values);
        DerivativeLicense_token_settings.write(token_id, key, values_len);
        return ();
    }

    func set_author_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            key: felt,
            value: felt
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert 1 = 0;  // No available key settable for author settings
        }
        DerivativeLicense_author_settings.write(token_id, key, value);
        return ();
    }

    func set_author_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_id: Uint256,
            key: felt,
            values_len: felt,
            values: felt*
    ) {
        with_attr error_message("DerivativeLicense: token_id is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("DerivativeLicense: unrecognized key {key}") {
            assert (key - ROYALTIES_KEY) = 0;
        }
        _set_author_array_settings(token_id, key, values_len, values);
        DerivativeLicense_author_settings.write(token_id, key, values_len);
        return ();
    }

}

//
// Private
//

func _collection_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt,
        index: felt,
        value_ptr: felt*
) {
    if (index == 0) {
        return ();
    }

    let (value) = DerivativeLicense_collection_array_settings.read(key, index - 1);
    assert [value_ptr] = value;
    _collection_array_settings(key, index - 1, value_ptr + 1);
    return ();
}

func _token_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        key: felt,
        index: felt,
        value_ptr: felt*
) {
    if (index == 0) {
        return ();
    }

    let (value) = DerivativeLicense_token_array_settings.read(token_id, key, index - 1);
    assert [value_ptr] = value;
    _token_array_settings(token_id, key, index - 1, value_ptr + 1);
    return ();
}

func _author_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        key: felt,
        index: felt,
        value_ptr: felt*
) {
    if (index == 0) {
        return ();
    }

    let (value) = DerivativeLicense_author_array_settings.read(token_id, key, index - 1);
    assert [value_ptr] = value;
    _author_array_settings(token_id, key, index - 1, value_ptr + 1);
    return ();
}

func _in_collection_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt,
        index: felt,
        elem: felt
) -> felt {
    if (index == 0) {
        return FALSE;
    }
    let (value) = DerivativeLicense_collection_array_settings.read(key, index - 1);
    if (elem == value) {
        return TRUE;
    }
    return _in_collection_array_settings(key, index - 1, elem);
}

func _in_token_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        key: felt,
        index: felt,
        elem: felt
) -> felt {
    if (index == 0) {
        return FALSE;
    }
    let (value) = DerivativeLicense_token_array_settings.read(token_id, key, index - 1);
    if (elem == value) {
        return TRUE;
    }
    return _in_token_array_settings(token_id, key, index - 1, elem);
}

func _set_collection_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt,
        index: felt,
        value_ptr: felt*
) {
    if (index == 0) {
        return ();
    }

    DerivativeLicense_collection_array_settings.write(key, index - 1, [value_ptr]);
    _set_collection_array_settings(key, index - 1, value_ptr + 1);
    return ();
}

func _set_token_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        key: felt,
        index: felt,
        value_ptr: felt*
) {
    if (index == 0) {
        return ();
    }

    DerivativeLicense_token_array_settings.write(token_id, key, index - 1, [value_ptr]);
    _set_token_array_settings(token_id, key, index - 1, value_ptr + 1);
    return ();
}

func _set_author_array_settings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256,
        key: felt,
        index: felt,
        value_ptr: felt*
) {
    if (index == 0) {
        return ();
    }

    DerivativeLicense_author_array_settings.write(token_id, key, index - 1, [value_ptr]);
    _set_author_array_settings(token_id, key, index - 1, value_ptr + 1);
    return ();
}
