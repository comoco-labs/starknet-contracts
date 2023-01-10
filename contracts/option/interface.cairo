// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IDerivativeOption {

//
//  Initializer
//

//  func initializer(proxyAdmin: felt, owner: felt) {
//  }

//
//  ERC165
//

//  func supportsInterface(interfaceId: felt) -> (success: felt) {
//  }

//
//  ERC1155
//

//  func uri(id: Uint256) -> (uri: felt) {
//  }

    func balanceOf(account: felt, id: Uint256) -> (balance: Uint256) {
    }

    func balanceOfBatch(accounts_len: felt, accounts: felt*, ids_len: felt, ids: Uint256*) -> (balances_len: felt, balances: Uint256*) {
    }

//  func isApprovedForAll(account: felt, operator: felt) -> (approved: felt) {
//  }

//  func setApprovalForAll(operator: felt, approved: felt) {
//  }

//  func safeTransferFrom(from_: felt, to: felt, id: Uint256, value: Uint256, data_len: felt, data: felt*) {
//  }

//  func safeBatchTransferFrom(from_: felt, to: felt, ids_len: felt, ids: Uint256*, values_len: felt, values: Uint256*, data_len: felt, data: felt*) {
//  }

    func mint(to: felt, value: Uint256) -> (id: Uint256) {
    }

    func mintBatch(to: felt, values_len: felt, values: Uint256*) -> (ids_len: felt, ids: Uint256*) {
    }

    func burn(from_: felt, id: Uint256, value: Uint256) {
    }

    func burnBatch(from_: felt, ids_len: felt, ids: Uint256*, values_len: felt, values: Uint256*) {
    }

//
//  Access
//

//  func owner() -> (owner: felt) {
//  }

//  func transferOwnership(newOwner: felt) {
//  }

//
//  Upgrade
//

//  func version() -> (version: felt) {
//  {

//  func upgrade(newImplementation: felt) {
//  }

//  func getProxyAdmin() -> (admin: felt) {
//  }

//  func setProxyAdmin(newAdmin: felt) {
//  }

}
