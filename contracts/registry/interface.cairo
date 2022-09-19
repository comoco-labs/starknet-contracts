// SPDX-License-Identifier: MIT

%lang starknet

@contract_interface
namespace ITokenRegistry {

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

}
