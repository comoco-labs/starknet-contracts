// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct Royalty {
    receiver: felt,
    fraction: Uint256,
}
