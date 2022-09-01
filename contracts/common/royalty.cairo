from starkware.cairo.common.uint256 import Uint256

struct Royalty:
    member receiver : felt
    member fraction : Uint256
end
