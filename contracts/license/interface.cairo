# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.common.royalty import Royalty

@contract_interface
namespace IDerivativeLicense:

    func version() -> (version : felt):
    end

    func allowTransfer(tokenId : Uint256) -> (allowed : felt):
    end

    func allowMint(tokenId : Uint256) -> (allowed : felt):
    end

    func royalties(tokenId : Uint256) -> (royalties_len : felt, royalties : Royalty*):
    end

    func collectionSettings(key : felt) -> (value : felt):
    end

    func tokenSettings(tokenId : Uint256, key : felt) -> (value : felt):
    end

    func setCollectionSettings(key : felt, value : felt):
    end

    func setTokenSettings(tokenId : Uint256, key : felt, value : felt):
    end

end
