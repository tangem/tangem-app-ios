//
//  YieldModuleAvailability.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Represents the current yield module state for a token.
/// Used in the token details screen to determine whether to show yield-related notifications or views.
///
/// - checking: Initial state, nothing is shown.
/// - eligible: Token supports yield but user hasn’t entered yet (show `YieldModuleAvailableNotification`).
/// - active: User is currently in yield (show `YieldStatusView` with active state).
/// - enter / exit: User is entering or exiting yield (show `YieldStatusView` with loading indicators).
/// - notApplicable: Yield not available (non-EVM token or missing data).
enum YieldModuleAvailability: Equatable {
    case checking
    case eligible(YieldAvailableNotificationViewModel)
    case active(YieldStatusViewModel)
    case notApplicable
    case enter(YieldStatusViewModel)
    case exit(YieldStatusViewModel)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.checking, .checking),
             (.eligible, .eligible),
             (.active, .active),
             (.enter, .enter),
             (.exit, .exit),
             (.notApplicable, .notApplicable):
            return true
        default:
            return false
        }
    }
}
