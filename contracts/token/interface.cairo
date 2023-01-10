// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IDerivativeToken {

//
//  Initializer
//

//  func initializer(proxyAdmin: felt, name: felt, symbol: felt, owner: felt, license: felt, registry: felt) {
//  }

//
//  ERC165
//

//  func supportsInterface(interfaceId: felt) -> (success: felt) {
//  }

//
//  ERC721
//

//  func name() -> (name: felt) {
//  }

//  func symbol() -> (symbol: felt) {
//  }

//  func tokenURI(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
//  }

//  func balanceOf(owner: felt) -> (balance: Uint256) {
//  }

//  func ownerOf(tokenId: Uint256) -> (owner: felt) {
//  }

//  func safeTransferFrom(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*) {
//  }

//  func transferFrom(from_: felt, to: felt, tokenId: Uint256) {
//  }

//  func approve(approved: felt, tokenId: Uint256) {
//  }

//  func setApprovalForAll(operator: felt, approved: felt) {
//  }

//  func getApproved(tokenId: Uint256) -> (approved: felt) {
//  }

//  func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt) {
//  }

//  func mint(to: felt, tokenId: Uint256, parentTokens_len: felt, parentTokens: Token*, tokenURI_len: felt, tokenURI: felt*) {
//  }

//  func setTokenURI(tokenId: Uint256, tokenURI_len: felt, tokenURI: felt*) {
//  }

//
//  Metadata
//

//  func authorOf(tokenId: Uint256) -> (author: felt) {
//  }

//  func setAuthor(tokenId: Uint256, author: felt) {
//  }

//  func parentTokensOf(tokenId: Uint256) -> (parentTokens_len: felt, parentTokens: Token*) {
//  }

//  func isParentToken(tokenId: Uint256, otherToken: Token) -> (res: felt) {
//  }

//  func setParentTokens(tokenId: Uint256, parentTokens_len: felt, parentTokens: Token*) {
//  }

//  func derivativeRightsOf(tokenId: Uint256) -> (derivativeRights_len: felt, derivativeRights: Token*) {
//  }

//  func isDerivativeRight(tokenId: Uint256, otherToken: Token) -> (res: felt) {
//  }

//  func addDerivativeRights(tokenId: Uint256, derivativeRights_len: felt, derivativeRights: Token*) {
//  }

//  func issueDerivativeOption(tokenId: Uint256, optionAddress: felt, optionValue: felt) -> (option: Token) {
//  }

//  func relatedTokens(tokenId: Uint256, relation: felt) -> (tokens_len: felt, tokens: Token*) {
//  }

//  func relationsWith(tokenId: Uint256, otherToken: Token) -> (relations_len: felt, relations: felt*) {
//  }

//
//  License
//

    func allowToTransfer(tokenId: Uint256) -> (allowed: felt) {
    }

    func allowTransferring(tokenId: Uint256) -> (allowed: felt) {
    }

    func allowToMint(tokenId: Uint256, to: felt) -> (allowed: felt) {
    }

//  func royalties(tokenId: Uint256) -> (royalties_len: felt, royalties: Royalty*) {
//  }

//  func isDragAlong(tokenId: Uint256) -> (res: felt) {
//  }

//  func collectionSettings(key: felt) -> (value: felt) {
//  }

//  func collectionArraySettings(key: felt) -> (values_len: felt, values: felt*) {
//  }

//  func tokenSettings(tokenId: Uint256, key: felt) -> (value: felt) {
//  }

//  func tokenArraySettings(tokenId: Uint256, key: felt) -> (values_len: felt, values: felt*) {
//  }

//  func authorSettings(tokenId: Uint256, key: felt) -> (value: felt) {
//  }

//  func authorArraySettings(tokenId: Uint256, key: felt) -> (values_len: felt, values: felt*) {
//  }

//  func setCollectionSettings(key: felt, value: felt) {
//  }

//  func setCollectionArraySettings(key: felt, values_len: felt, values: felt*) {
//  }

//  func setTokenSettings(tokenId: Uint256, key: felt, value: felt) {
//  }

//  func setTokenArraySettings(tokenId: Uint256, key: felt, values_len: felt, values: felt*) {
//  }

//  func setAuthorSettings(tokenId: Uint256, key: felt, value: felt) {
//  }

//  func setAuthorArraySettings(tokenId: Uint256, key: felt, values_len: felt, values: felt*) {
//  }

//
//  Access
//

//  func owner() -> (owner: felt) {
//  }

//  func transferOwnership(newOwner: felt) {
//  }

//  func isAdmin(user: felt) -> (res: felt) {
//  }

//  func setAdmin(user: felt, granted: felt) {
//  }

//
//  Upgrade
//

//  func version() -> (version: felt) {
//  {

//  func upgrade(newImplementation: felt) {
//  }

//  func registry() -> (registry: felt) {
//  }

//  func upgradeRegistry(newRegistry: felt) {
//  }

//  func getProxyAdmin() -> (admin: felt) {
//  }

//  func setProxyAdmin(newAdmin: felt) {
//  }

}
