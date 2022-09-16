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

const LICENSE_VERSION = 1;

// 1: allowed; 2: not allowed
const ALLOW_TRANSFER_KEY = 'allow_transfer';
const ALLOW_TRANSFER_DEFAULT = 1;

// 1: drag along; 2: not drag along
const DRAG_ALONG_KEY = 'drag_along';
const DRAG_ALONG_DEFAULT = 1;

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

//
// Getters
//

@view
func version{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        version: felt
) {
    return (version=LICENSE_VERSION);
}

@view
func allowTransfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        allowed: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    let (collectionValue) = DerivativeLicense_collection_settings.read(ALLOW_TRANSFER_KEY);
    let (tokenValue) = DerivativeLicense_token_settings.read(tokenId, ALLOW_TRANSFER_KEY);
    if ((collectionValue - 2) * (tokenValue - 2) == 0) {
        return (allowed=FALSE);
    }
    if ((collectionValue - 1) * (tokenValue - 1) == 0) {
        return (allowed=TRUE);
    }
    return (allowed=ALLOW_TRANSFER_DEFAULT);
}

@view
func allowMint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        to : felt
) -> (
        allowed: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    let (allowed) = inCollectionArraySettings(LICENSEES_KEY, to);
    if (allowed == FALSE) {
        let (allowed) = inTokenArraySettings(tokenId, LICENSEES_KEY, to);
    }
    return (allowed=allowed);
}

@view
func royalties{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
) -> (
        royalties_len: felt,
        royalties: Royalty*
) {
    alloc_locals;
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    let (local royalties: felt*) = alloc();

    let (collection_royalties_len) = DerivativeLicense_collection_settings.read(ROYALTIES_KEY);
    _collection_array_settings(ROYALTIES_KEY, collection_royalties_len, royalties);
    let (token_royalties_len) = DerivativeLicense_token_settings.read(tokenId, ROYALTIES_KEY);
    _token_array_settings(tokenId, ROYALTIES_KEY, token_royalties_len, royalties + collection_royalties_len);
    let (author_royalties_len) = DerivativeLicense_author_settings.read(tokenId, ROYALTIES_KEY);
    _author_array_settings(tokenId, ROYALTIES_KEY, author_royalties_len, royalties + collection_royalties_len + token_royalties_len);

    let royalties_len = collection_royalties_len + token_royalties_len + author_royalties_len;
    return (royalties_len=(royalties_len / 2), royalties=cast(royalties, Royalty*));
}

@view
func collectionSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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

@view
func collectionArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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

@view
func tokenSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt
) -> (
        value: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - ALLOW_TRANSFER_KEY) * (key - DRAG_ALONG_KEY) * (key - LICENSEES_KEY) * (key - ROYALTIES_KEY) = 0;
    }
    let (value) = DerivativeLicense_token_settings.read(tokenId, key);
    return (value=value);
}

@view
func tokenArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt
) -> (
        values_len: felt,
        values: felt*
) {
    alloc_locals;
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - LICENSEES_KEY) * (key - ROYALTIES_KEY) = 0;
    }
    let (local values: felt*) = alloc();
    let (values_len) = DerivativeLicense_token_settings.read(tokenId, key);
    _token_array_settings(tokenId, key, values_len, values);
    return (values_len=values_len, values=values);
}

@view
func authorSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt
) -> (
        value: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - ROYALTIES_KEY) = 0;
    }
    let (value) = DerivativeLicense_author_settings.read(tokenId, key);
    return (value=value);
}

@view
func authorArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt
) -> (
        values_len: felt,
        values: felt*
) {
    alloc_locals;
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - ROYALTIES_KEY) = 0;
    }
    let (local values: felt*) = alloc();
    let (values_len) = DerivativeLicense_author_settings.read(tokenId, key);
    _author_array_settings(tokenId, key, values_len, values);
    return (values_len=values_len, values=values);
}

//
// Externals
//

@external
func setCollectionSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt,
        value: felt
) {
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - ALLOW_TRANSFER_KEY) * (key - DRAG_ALONG_KEY) = 0;
    }
    DerivativeLicense_collection_settings.write(key, value);
    return ();
}

@external
func setCollectionArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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

@external
func setTokenSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        value: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - ALLOW_TRANSFER_KEY) * (key - DRAG_ALONG_KEY) = 0;
    }
    DerivativeLicense_token_settings.write(tokenId, key, value);
    return ();
}

@external
func setTokenArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        values_len: felt,
        values: felt*
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - LICENSEES_KEY) * (key - ROYALTIES_KEY) = 0;
    }
    _set_token_array_settings(tokenId, key, values_len, values);
    DerivativeLicense_token_settings.write(tokenId, key, values_len);
    return ();
}

@external
func setAuthorSettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        value: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert 1 = 0;  // No available key settable for author settings
    }
    DerivativeLicense_author_settings.write(tokenId, key, value);
    return ();
}

@external
func setAuthorArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        values_len: felt,
        values: felt*
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - ROYALTIES_KEY) = 0;
    }
    _set_author_array_settings(tokenId, key, values_len, values);
    DerivativeLicense_author_settings.write(tokenId, key, values_len);
    return ();
}

//
// Internals
//

func inCollectionArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        key: felt,
        elem: felt
) -> (
        res: felt
) {
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - LICENSEES_KEY) = 0;
    }
    let (valuesLen) = DerivativeLicense_collection_settings.read(key);
    let res = _in_collection_array_settings(key, valuesLen, elem);
    return (res=res);
}

func inTokenArraySettings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256,
        key: felt,
        elem: felt
) -> (
        res: felt
) {
    with_attr error_message("DerivativeLicense: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    with_attr error_message("DerivativeLicense: unrecognized key {key}") {
        assert (key - LICENSEES_KEY) = 0;
    }
    let (valuesLen) = DerivativeLicense_token_settings.read(tokenId, key);
    let res = _in_token_array_settings(tokenId, key, valuesLen, elem);
    return (res=res);
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
