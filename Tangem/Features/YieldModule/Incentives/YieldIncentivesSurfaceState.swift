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
    /// Pending rewards only — no Claim CTA and no invented USD value.
    case pendingOnly
    /// Claimable but below the backend recommendation threshold — the Claim CTA stays disabled.
    case belowThreshold
    /// A supported claimable reward is recommended; fresh calldata still gates the actual signing.
    case claimAvailable
    /// Duplicate claim actions stay disabled until the result is reconciled.
    case claimInFlight

    static func make(
        campaignActive: Bool,
        summary: YieldIncentivesRewardsSummary?,
        isClaimInFlight: Bool
    ) -> YieldIncentivesSurfaceState {
        guard campaignActive else {
            return .none
        }

        if isClaimInFlight {
            return .claimInFlight
        }

        guard let summary else {
            return .apyOverlayOnly
        }

        if !summary.claimableRewards.isEmpty {
            return summary.isClaimRecommended ? .claimAvailable : .belowThreshold
        }

        if !summary.pendingRewards.isEmpty {
            return .pendingOnly
        }

        // Only unsupported or zero-amount rewards — nothing claimable or pending to surface.
        return .apyOverlayOnly
    }
}
