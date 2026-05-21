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
        case .polygon(false):
            return "0x8c86c76aA4eB91F6F371F38dC775B36a3509fa03"
        default:
            return nil
        }
    }
}
