//
//  CommonWalletAssetsDiscoveryAnalyticsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonWalletAssetsDiscoveryAnalyticsService {}

// MARK: - WalletAssetsDiscoveryAnalyticsProvider

extension CommonWalletAssetsDiscoveryAnalyticsService: WalletAssetsDiscoveryAnalyticsProvider {
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
