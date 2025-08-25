//
//  UserWalletPushNotifyStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

/// Represents the push notification status for a user's wallet
enum UserWalletPushNotifyStatus: Equatable {
    /// Notifications are enabled
    case enabled

    /// Notifications are disabled by the user
    case disabled

    /// Notifications unAvailable for a specific blocked reason
    case unavailable(reason: UnavailableReason, enabledRemote: Bool)

    /// Returns `true` if notifications are currently enabled on server status and permission enabled
    var isActive: Bool {
        switch self {
        case .enabled:
            return true
        case .disabled:
            return false
        case .unavailable(let reason, let enabledRemote):
            // In case our push are not available on the device, but at the same time we must look at the status on the server. And if the status on the server is enabled, then we assume that push notifications are active state.
            return reason == .permissionDenied && enabledRemote
        }
    }

    var isNotInitialized: Bool {
        if case .unavailable(let reason, _) = self {
            return reason == .notInitialized
        }

        return false
    }
}

extension UserWalletPushNotifyStatus: CustomStringConvertible {
    var description: String {
        switch self {
        case .enabled:
            return "Enabled"
        case .disabled:
            return "Disabled by user"
        case .unavailable(let reason, _):
            return "Unavailable reason: (\(reason))"
        }
    }
}

extension UserWalletPushNotifyStatus {
    /// Reasons why push notifications may be blocked
    enum UnavailableReason: Error, CustomStringConvertible {
        /// When have problem with sync backend status
        case notInitialized

        /// The user has denied the necessary permissions to receive notifications
        case permissionDenied

        var description: String {
            switch self {
            case .notInitialized:
                return "Not initialized"
            case .permissionDenied:
                return "Permission denied"
            }
        }
    }
}
