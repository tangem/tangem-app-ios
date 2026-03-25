//
//  TangemPaySwapAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPaySwapAvailabilityProvider: SwapAvailabilityProvider {
    var isSwapAvailable: Bool {
        // TangemPay always supports swap
        return true
    }
}
