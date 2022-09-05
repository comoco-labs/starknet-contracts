# SPDX-License-Identifier: MIT

%lang starknet

@contract_interface
namespace ITokenRegistry:

    func getMappingInfoForL1Address(l1Addr : felt) -> (l2Addr : felt, sot : felt):
    end

    func getMappingInfoForL2Address(l2Addr : felt) -> (l1Addr : felt, sot : felt):
    end

    func getMappingInfoForAddresses(l1Addr : felt, l2Addr : felt) -> (sot : felt):
    end

end