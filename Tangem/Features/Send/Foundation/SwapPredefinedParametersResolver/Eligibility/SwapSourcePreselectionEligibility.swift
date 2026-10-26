//
//  SwapSourcePreselectionEligibility.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SwapSourcePreselectionEligibility {
    static func canBecomeSource(for status: TokenActionAvailabilityProvider.SwapSourceActionAvailabilityStatus) -> Bool {
        switch status {
        case .available,
             .blockchainLoading,
             .blockchainUnreachable,
             .hasOnlyCachedBalance,
             .expressLoading,
             .expressUnreachable,
             .missingAssetRequirement:
            return true
        case .jointAccountsComingSoon,
             .customToken,
             .yieldModuleApproveNeeded,
             .cantSignLongTransactions:
            return false
        }
    }
}
