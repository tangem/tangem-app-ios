//
//  YieldModuleImplementationAddresses.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum YieldModuleImplementationAddresses {
    /// Returns the latest known implementation address for the yield module on the given blockchain, if available.
    public static func latestImplementation(for blockchain: Blockchain) -> String? {
        switch blockchain {
        case .ethereum(false):
            return "0xa6a6afa45D22aE7a55abC5cbBF426Fc8Dd45b846"
        case .bsc(false):
            return "0x6bBB8DDB265A6bae01422fF815a77e72D71F4e17"
        case .polygon(false):
            return "0x66084220E3dFdd1D8C8F1F868C103F9418DEce7c"
        case .arbitrum(false):
            return "0xDC8123e7E28D8cC12c3420CF8c8D6eceD9db4c71"
        case .base(false):
            return "0x66cC410eC0Dd4013b7dA0a003404F6c503109093"
        case .optimism(false):
            return "0xe1d0BF13C427C4B2e25Df0CA29E1Faa2d10458f3"
        case .avalanche(false):
            return "0xe1d0BF13C427C4B2e25Df0CA29E1Faa2d10458f3"
        default:
            return nil
        }
    }
}
