// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.common.token import Token

@contract_interface
namespace ITokenRelation {

    func relationsWith(tokenId: Uint256, otherToken: Token) -> (relations_len: felt, relations: felt*) {
    }

    func relatedTokens(tokenId: Uint256, relation: felt) -> (tokens_len: felt, tokens: Token*) {
    }

}
