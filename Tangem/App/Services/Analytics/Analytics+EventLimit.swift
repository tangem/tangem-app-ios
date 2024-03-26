//
//  Analytics+EventLimit.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum EventLimit {
        // One time per app session. Use extraEventId to limit repeating events with different params
        case appSession(extraEventId: String? = nil)
        // One time per app session and per user wallet. Use extraEventId to limit repeating events with different params
        case userWalletSession(userWalletId: UserWalletId, extraEventId: String? = nil)
        // No limits
        case unlimited
    }
}

extension Analytics.EventLimit {
    var isLimited: Bool {
        switch self {
        case .appSession, .userWalletSession:
            return true
        case .unlimited:
            return false
        }
    }

    var contextScope: AnalyticsContextScope {
        switch self {
        case .appSession(let extraEventId):
            return .common(extraEventId: extraEventId)
        case .userWalletSession(let userWalletId, let extraEventId):
            return .userWallet(userWalletId: userWalletId, extraEventId: extraEventId)
        case .unlimited:
            return .common(extraEventId: nil)
        }
    }
}
