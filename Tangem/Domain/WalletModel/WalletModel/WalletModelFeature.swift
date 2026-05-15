//
//  WalletModelFeature.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import TangemMacro

@CaseFlagable
enum WalletModelFeature {
    case nft(networkService: NFTNetworkService)

    case dynamicAddresses(manager: DynamicAddressesManager)

    @available(*, unavailable, message: "This feature is not implemented yet")
    case staking

    /// - Note: This is a **V2** transaction history, do not confuse with the legacy one (`TransactionHistoryService`).
    case transactionHistory(sync: any TransactionHistorySyncing)
}

// MARK: - Convenience accessors

extension Array where Element == WalletModelFeature {
    var dynamicAddressesManager: DynamicAddressesManager? {
        for case .dynamicAddresses(let manager) in self {
            return manager
        }
        return nil
    }

    var transactionHistorySync: (any TransactionHistorySyncing)? {
        for case .transactionHistory(let sync) in self {
            return sync
        }
        return nil
    }
}
