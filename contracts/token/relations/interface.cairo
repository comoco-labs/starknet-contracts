// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.common.token import Token

@contract_interface
namespace ITokenRelation {

    func relatedTokens(tokenId: Uint256, relation: felt) -> (tokens_len: felt, tokens: Token*) {
    }

    func relationsWith(tokenId: Uint256, otherToken: Token) -> (relations_len: felt, relations: felt*) {
    }

}

@contract_interface
namespace IDerived {

    func parentTokensOf(tokenId: Uint256) -> (parentTokens_len: felt, parentTokens: Token*) {
    }

    func isParentToken(tokenId: Uint256, otherToken: Token) -> (res: felt) {
    }

}
