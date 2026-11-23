//
//  CommonWalletConnectAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class CommonWalletConnectAnalyticsLogger: WalletConnectAnalyticsLogger {
    func logDAppDisconnected(dAppData: WalletConnectDAppData) {
        Analytics.log(
            event: .walletConnectDAppDisconnected,
            params: [
                .walletConnectDAppName: dAppData.name,
                .walletConnectDAppUrl: dAppData.domain.absoluteString,
            ]
        )
    }
}
