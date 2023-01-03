// SPDX-License-Identifier: MIT

%lang starknet

from contracts.common.token import Token

@contract_interface
namespace ITokenRelation {

    func relationsWith(tokenId: felt, otherToken: Token) -> (relations_len: felt, relations: felt*) {
    }

    func relatedTokens(tokenId: felt, relation: felt) -> (tokens_len: felt, tokens: Token*) {
    }

}
