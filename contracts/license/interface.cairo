// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.common.royalty import Royalty

@contract_interface
namespace IDerivativeLicense {

    func version() -> (version: felt) {
    }

    func allowTransfer(tokenId: Uint256) -> (allowed: felt) {
    }

    func allowMint(tokenId: Uint256) -> (allowed: felt) {
    }

    func royalties(tokenId: Uint256) -> (royalties_len: felt, royalties: Royalty*) {
    }

    func collectionSettings(key: felt) -> (value: felt) {
    }

    func tokenSettings(tokenId: Uint256, key: felt) -> (value: felt) {
    }

    func setCollectionSettings(key: felt, value: felt) {
    }

    func setTokenSettings(tokenId: Uint256, key: felt, value: felt) {
    }

}
