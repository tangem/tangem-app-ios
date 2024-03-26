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
        // One time per app session
        case appSession
        // One time per app session and per user wallet
        case userWalletSession(userWalletId: UserWalletId)
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
        case .appSession, .unlimited:
            return .common
        case .userWalletSession(let userWalletId):
            return .userWallet(userWalletId)
        }
    }
}
