//
//  CommonWalletTokenAutoSyncAnalyticsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonWalletTokenAutoSyncAnalyticsService {}

// MARK: - WalletTokenAutoSyncAnalyticsProvider

extension CommonWalletTokenAutoSyncAnalyticsService: WalletTokenAutoSyncAnalyticsProvider {
    func logInitialTokenSyncStarted(userWalletId: UserWalletId) {
        Analytics.log(
            .initialTokenSyncStarted,
            contextParams: .userWallet(userWalletId)
        )
    }

    func logInitialTokenSyncCompleted(userWalletId: UserWalletId) {
        Analytics.log(
            .initialTokenSyncCompleted,
            contextParams: .userWallet(userWalletId)
        )
    }
}
