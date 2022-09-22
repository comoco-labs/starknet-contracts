// SPDX-License-Identifier: MIT

%lang starknet

@contract_interface
namespace ITokenRegistry {

//
//  Initializer
//

//  func initializer(proxyAdmin: felt, owner: felt) {
//  }

//
//  Registry
//

    func getMappingInfoForL1Address(l1Addr: felt) -> (l2Addr: felt, sot: felt) {
    }

    func getMappingInfoForL2Address(l2Addr: felt) -> (l1Addr: felt, sot: felt) {
    }

    func getMappingInfoForAddresses(l1Addr: felt, l2Addr: felt) -> (sot: felt) {
    }

//  func setMappingInfoForAddresses(l1Addr: felt, l2Addr: felt, sot: felt) {
//  }

//  func clearMappingInfoForAddresses(l1Addr: felt, l2Addr: felt) {
//  }

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

//  func getImplementationHash() -> (implementation: felt) {
//  }

//  func upgrade(newImplementation: felt) {
//  }

//  func getProxyAdmin() -> (admin: felt) {
//  }

//  func setProxyAdmin(newAdmin: felt) {
//  }

}
