//
//  TokenDetailsStakingState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TokenDetailsStakingState {
    case loading
    case available(item: AvailableItem)
    case enable(item: EnableItem)
    case unavailable(item: UnavailableItem)
}

// MARK: - Items

extension TokenDetailsStakingState {
    struct AvailableItem {
        let title: String
        let description: String
        let actionTitle: String
        let action: () -> Void
    }

    struct EnableItem {
        let title: String
        let rewardsState: RewardsState
        let fiatBalance: AttributedString
        let cryptoBalance: String
        let action: () -> Void
    }

    enum RewardsState {
        case claimed(String)
        case auto
        case empty(String)
    }

    struct UnavailableItem {
        let title: String
        let description: String
        let action: (() -> Void)?
    }
}
