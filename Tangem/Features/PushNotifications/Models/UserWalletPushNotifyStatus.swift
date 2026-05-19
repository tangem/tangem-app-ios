//
//  UserWalletPushNotifyStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Represents the push notification status for a user's wallet
enum UserWalletPushNotifyStatus: Equatable {
    /// Still loading, initialization in progress
    case loading

    /// System notifications are disabled or not permitted
    case needSystemPermission

    /// System permissions granted, but disabled in app/on backend
    case disabledInApp

    /// Everything is OK: system permissions granted and enabled on backend
    case enabled

    /// Error loading/syncing
    case failed

    /// Returns true if notifications are currently enabled (only for .enabled state)
    var isActive: Bool {
        self == .enabled
    }

    var isNotInitialized: Bool {
        self == .loading || self == .failed
    }
}

extension UserWalletPushNotifyStatus: CustomStringConvertible {
    var description: String {
        switch self {
        case .loading:
            return "Loading"
        case .needSystemPermission:
            return "Need system permission"
        case .disabledInApp:
            return "Disabled in app"
        case .enabled:
            return "Enabled"
        case .failed:
            return "Failed"
        }
    }
}
