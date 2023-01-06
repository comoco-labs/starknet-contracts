// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc1155.library import ERC1155
from openzeppelin.upgrades.library import Proxy

//
// Constants
//

const VERSION = 1;

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        proxyAdmin: felt,
        owner: felt
) {
    Proxy.initializer(proxyAdmin);
    ERC1155.initializer('');
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
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        interfaceId: felt
) -> (
        success: felt
) {
    return ERC165.supports_interface(interfaceId);
}

@view
func uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        id: Uint256
) -> (
        uri: felt
) {
    return ERC1155.uri(id);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt,
        id: Uint256
) -> (
        balance: Uint256
) {
    return ERC1155.balance_of(account, id);
}

@view
func balanceOfBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        accounts_len: felt,
        accounts: felt*,
        ids_len: felt,
        ids: Uint256*
) -> (
        balances_len: felt,
        balances: Uint256*
) {
    return ERC1155.balance_of_batch(accounts_len, accounts, ids_len, ids);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt,
        operator: felt
) -> (
        approved: felt
) {
    return ERC1155.is_approved_for_all(account, operator);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        owner: felt
) {
    return Ownable.owner();
}

@view
func getProxyAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (
        admin: felt
) {
    return Proxy.get_admin();
}

//
// Externals
//

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        operator: felt,
        approved: felt
) {
    ERC1155.set_approval_for_all(operator, approved);
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_: felt,
        to: felt,
        id: Uint256,
        value: Uint256,
        data_len: felt,
        data: felt*
) {
    ERC1155.safe_transfer_from(from_, to, id, value, data_len, data);
    return ();
}

@external
func safeBatchTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_: felt,
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        values_len: felt,
        values: Uint256*,
        data_len: felt,
        data: felt*,
) {
    ERC1155.safe_batch_transfer_from(from_, to, ids_len, ids, values_len, values, data_len, data);
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt,
        id: Uint256,
        value: Uint256,
        data_len: felt,
        data: felt*
) {
    Ownable.assert_only_owner();
    ERC1155._mint(to, id, value, data_len, data);
    return ();
}

@external
func mintBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        values_len: felt,
        values: Uint256*,
        data_len: felt,
        data: felt*,
) {
    Ownable.assert_only_owner();
    ERC1155._mint_batch(to, ids_len, ids, values_len, values, data_len, data);
    return ();
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_: felt,
        id: Uint256,
        value: Uint256
) {
    ERC1155.assert_owner_or_approved(from_);
    ERC1155._burn(from_, id, value);
    return ();
}

@external
func burnBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_: felt,
        ids_len: felt,
        ids: Uint256*,
        values_len: felt,
        values: Uint256*
) {
    ERC1155.assert_owner_or_approved(from_);
    ERC1155._burn_batch(from_, ids_len, ids, values_len, values);
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