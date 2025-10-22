//
//  YieldModuleNotificationBannerParams.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets

enum YieldModuleNotificationBannerParams {
    enum Position {
        case `default`
        case approveTop
    }

    case notEnoughFeeCurrency(feeCurrencyName: String, tokenIcon: ImageType, buttonAction: @MainActor @Sendable () -> Void)
    case approveNeeded(buttonAction: @MainActor @Sendable () -> Void)
    case feeUnreachable(buttonAction: @MainActor @Sendable () -> Void)

    var isApproveNeeded: Bool {
        switch self {
        case .approveNeeded:
            return true
        default:
            return false
        }
    }

    var bannedPosition: Position {
        switch self {
        case .approveNeeded:
            return .approveTop
        default:
            return .default
        }
    }
}
