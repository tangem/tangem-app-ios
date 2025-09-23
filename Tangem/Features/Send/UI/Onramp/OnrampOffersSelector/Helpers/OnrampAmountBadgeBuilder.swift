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
        switch provider?.globalAttractiveType {
        case .best:
            return .best
        case .loss(let percent):
            let formattedPercent = percentFormatter.format(percent, option: .onramp)
            return .loss(percent: formattedPercent, signType: .init(from: percent))
        case .none:
            return .none
        }
    }
}
