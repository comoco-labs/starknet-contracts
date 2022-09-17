// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.common.royalty import Royalty

@contract_interface
namespace IDerivativeLicense {

    func version() -> (version: felt) {
    }

    func allowToTransfer(tokenId: Uint256) -> (allowed: felt) {
    }

    func allowToMint(tokenId: Uint256, owner: felt, to: felt) -> (allowed: felt) {
    }

    func royalties(tokenId: Uint256) -> (royalties_len: felt, royalties: Royalty*) {
    }

    func collectionSettings(key: felt) -> (value: felt) {
    }

    func collectionArraySettings(key: felt) -> (values_len: felt, values: felt*) {
    }

    func tokenSettings(tokenId: Uint256, key: felt) -> (value: felt) {
    }

    func tokenArraySettings(tokenId: Uint256, key: felt) -> (values_len: felt, values: felt*) {
    }

    func authorSettings(tokenId: Uint256, key: felt) -> (value: felt) {
    }

    func authorArraySettings(tokenId: Uint256, key: felt) -> (values_len: felt, values: felt*) {
    }

    func setCollectionSettings(key: felt, value: felt) {
    }

    func setCollectionArraySettings(key: felt, values_len: felt, values: felt*) {
    }

    func setTokenSettings(tokenId: Uint256, key: felt, value: felt) {
    }

    func setTokenArraySettings(tokenId: Uint256, key: felt, values_len: felt, values: felt*) {
    }

    func setAuthorSettings(tokenId: Uint256, key: felt, value: felt) {
    }

    func setAuthorArraySettings(tokenId: Uint256, key: felt, values_len: felt, values: felt*) {
    }

}
