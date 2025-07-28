//
//  CommonWalletConnectAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class CommonWalletConnectAnalyticsLogger: WalletConnectAnalyticsLogger {
    func logScreenOpened() {
        Analytics.log(.walletConnectScreenOpened)
    }

    func logDisconnectAllButtonTapped() {
        Analytics.log(.walletConnectDisconnectAllButtonTapped)
    }
}
