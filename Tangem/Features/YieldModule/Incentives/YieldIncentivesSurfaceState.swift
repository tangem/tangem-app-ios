//
//  YieldIncentivesSurfaceState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// What incentive UI an active yield module shows, in the spec's precedence order.
enum YieldIncentivesSurfaceState: Equatable {
    case none
    case apyOverlayOnly
    /// Claimable but below the backend recommendation threshold — the Claim CTA stays disabled.
    case belowThreshold
    /// A supported claimable reward is recommended; fresh calldata still gates the actual signing.
    case claimAvailable
    /// Claimable rewards still listed while a submitted claim is reconciled — duplicate claim actions stay disabled.
    case claimInFlight

    static func make(
        campaignActive: Bool,
        summary: YieldIncentivesRewardsSummary?,
        isClaimInFlight: Bool
    ) -> YieldIncentivesSurfaceState {
        guard campaignActive else {
            return .none
        }

        guard let summary else {
            return .apyOverlayOnly
        }

        if !summary.claimableRewards.isEmpty {
            if isClaimInFlight {
                return .claimInFlight
            }

            return summary.isClaimRecommended ? .claimAvailable : .belowThreshold
        }

        return .apyOverlayOnly
    }
}
