//
//  YieldModuleViewConfigs.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemAssets

enum YieldModuleViewConfigs {
    enum YieldModuleNotificationBannerParams {
        case notEnoughFeeCurrency(feeCurrencyName: String, tokenIcon: ImageType, buttonAction: @MainActor @Sendable () -> Void)
        case approveNeeded(buttonAction: @MainActor @Sendable () -> Void)
        case feeUnreachable(buttonAction: @MainActor @Sendable () -> Void)
    }
}
