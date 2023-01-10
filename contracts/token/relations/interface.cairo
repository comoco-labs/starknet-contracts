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
namespace IParentRelation {

    func parentTokensOf(tokenId: Uint256) -> (parentTokens_len: felt, parentTokens: Token*) {
    }

    func isParentToken(tokenId: Uint256, otherToken: Token) -> (res: felt) {
    }

}

@contract_interface
namespace IChildRelation {

    func childTokensOf(tokenId: Uint256) -> (childTokens_len: felt, childTokens: Token*) {
    }

    func isChildToken(tokenId: Uint256, otherToken: Token) -> (res: felt) {
    }

}

@contract_interface
namespace IDerivativeRightRelation {

    func derivativeRightsOf(tokenId: Uint256) -> (derivativeRights_len: felt, derivativeRights: Token*) {
    }

    func isDerivativeRight(tokenId: Uint256, otherToken: Token) -> (res: felt) {
    }

}
