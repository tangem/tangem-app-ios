//
//  SwapSourceIgnoringExpressEligibility.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SwapSourceIgnoringExpressEligibility {
    static func canBecomeSource(for status: TokenActionAvailabilityProvider.SwapSourceActionAvailabilityStatus) -> Bool {
        switch status {
        case .available,
             .expressLoading,
             .expressUnreachable:
            return true
        case .jointAccountsComingSoon,
             .customToken,
             .blockchainLoading,
             .blockchainUnreachable,
             .hasOnlyCachedBalance,
             .cantSignLongTransactions,
             .missingAssetRequirement,
             .yieldModuleApproveNeeded:
            return false
        }
    }
}
