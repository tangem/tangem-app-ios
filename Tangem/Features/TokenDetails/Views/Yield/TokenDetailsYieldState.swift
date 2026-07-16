//
//  TokenDetailsYieldState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TokenDetailsYieldState {
    case loading
    case available(item: AvailableItem)
    case promoAvailable(item: PromoAvailableItem)
    case processing(item: ProcessingItem)
    case active(item: ActiveItem)
    case unavailable
}

// MARK: - Items

extension TokenDetailsYieldState {
    struct AvailableItem {
        let title: String
        let description: String
        let action: Action
    }

    struct PromoAvailableItem {
        let title: AttributedString
        let description: String
        let learnAction: Action
        let activateAction: Action
    }

    struct ProcessingItem {
        let type: ProcessingType
        let title: String
        let description: String
    }

    enum ProcessingType {
        case enabling
        case disabling
    }

    struct ActiveItem {
        let title: String
        let description: String
        let badgeType: () async -> ActiveBadgeType
        let action: Action
    }

    enum ActiveBadgeType {
        case attention
        case warning
        case none
    }

    struct Action {
        let title: String
        let closure: () -> Void
    }
}
