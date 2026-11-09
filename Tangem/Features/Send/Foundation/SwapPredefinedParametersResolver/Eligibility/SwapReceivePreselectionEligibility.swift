//
//  SwapReceivePreselectionEligibility.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SwapReceivePreselectionEligibility {
    static func canBecomeReceive(for status: TokenActionAvailabilityProvider.SwapReceiveActionAvailabilityStatus) -> Bool {
        switch status {
        case .available,
             .expressLoading,
             .expressUnreachable,
             .missingAssetRequirement:
            return true
        case .customToken:
            return false
        }
    }
}
