//
//  YieldModuleAvalability.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

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
