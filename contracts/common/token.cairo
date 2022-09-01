from starkware.cairo.common.uint256 import Uint256

struct Token:
    member collection : felt
    member id : Uint256
end
