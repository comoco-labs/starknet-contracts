// SPDX-License-Identifier: MIT

%lang starknet

@contract_interface
namespace ITokenRegistry {

//
//  Initializer
//

//  func initializer(proxyAdmin: felt) {
//  }

//
//  Registry
//

    func getPrimaryTokenAddress(secondaryAddr: felt) -> (primaryAddr: felt) {
    }

//  func setPrimaryTokenAddress(secondaryAddr: felt, newPrimaryAddr: felt) {
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

@contract_interface
namespace IOwner {

    func owner() -> (owner: felt) {
    }

//  func transfer_ownership(new_owner: felt) {
//  }

//  func renounce_ownership() {
//  }

}
