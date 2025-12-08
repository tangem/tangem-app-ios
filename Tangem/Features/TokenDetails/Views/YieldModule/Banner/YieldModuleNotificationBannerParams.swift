//
//  YieldModuleNotificationBannerParams.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import Foundation
import TangemMacro

@CaseFlagable
enum YieldModuleNotificationBannerParams: Identifiable {
    enum Position {
        case `default`
        case approveTop
    }

    case notEnoughFeeCurrency(feeCurrencyName: String, tokenIcon: ImageType, buttonAction: @MainActor @Sendable () -> Void)
    case approveNeeded(buttonAction: @MainActor @Sendable () -> Void)
    case feeUnreachable(buttonAction: @MainActor @Sendable () -> Void)
    case hasUndepositedAmounts(amount: String, currencySymbol: String)
    case highFees

    var id: String {
        switch self {
        case .notEnoughFeeCurrency:
            "notEnoughFeeCurrency"
        case .approveNeeded:
            "approveNeeded"
        case .feeUnreachable:
            "feeUnreachable"
        case .hasUndepositedAmounts:
            "hasUndepositedAmounts"
        case .highFees:
            "highFees"
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
