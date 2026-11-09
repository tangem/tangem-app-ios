//
//  SwapReceiveIgnoringExpressEligibility.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SwapReceiveIgnoringExpressEligibility {
    static func canBecomeReceive(for status: TokenActionAvailabilityProvider.SwapReceiveActionAvailabilityStatus) -> Bool {
        switch status {
        case .available,
             .expressLoading,
             .expressUnreachable:
            return true
        case .customToken,
             .missingAssetRequirement:
            return false
        }
    }
}
