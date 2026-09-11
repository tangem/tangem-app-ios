//
//  OnrampAmountBadgeBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct OnrampAmountBadgeBuilder {
    private let percentFormatter: PercentFormatter = .init()

    func mapToOnrampAmountBadge(provider: OnrampProvider?) -> OnrampAmountBadge.Badge? {
        if provider?.isRestricted == true {
            return .restricted
        }

        switch provider?.globalAttractiveType {
        case .best:
            return .best
        // Show only negative loss badge
        case .loss(let percent) where percent < 0,
             .great(.some(let percent)) where percent < 0:
            let formattedPercent = percentFormatter.format(percent, option: .onramp)
            return .loss(percent: formattedPercent, signType: .init(from: percent))
        case .none, .loss, .great:
            return .none
        }
    }
}
