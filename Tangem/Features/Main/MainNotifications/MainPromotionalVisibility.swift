//
//  MainPromotionalVisibility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MainPromotionalVisibility: Int, Comparable {
    case hidden
    case tangemPayPromoOnly
    case all

    var isMarketingVisible: Bool {
        self == .all
    }

    var isTangemPayPromoVisible: Bool {
        self != .hidden
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct MainPromotionalVisibilityResolver {
    func resolve(systemNotifications: [NotificationViewInput], hasOtherSystemContent: Bool) -> MainPromotionalVisibility {
        if hasOtherSystemContent {
            return .hidden
        }

        let events = systemNotifications
            .map { $0.settings.event as? GeneralNotificationEvent }
            .filter { $0 != .devCard }

        if events.isEmpty {
            return .all
        }

        if events.allSatisfy({ $0 == .addFunds }) {
            return .tangemPayPromoOnly
        }

        return .hidden
    }
}
