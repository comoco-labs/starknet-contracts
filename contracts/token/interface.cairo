// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IDerivativeToken {

    func allowToTransfer(tokenId: Uint256) -> (allowed: felt) {
    }

    func allowTransfer(tokenId: Uint256) -> (allowed: felt) {
    }

    func allowToMint(tokenId: Uint256, to: felt) -> (allowed: felt) {
    }

}
