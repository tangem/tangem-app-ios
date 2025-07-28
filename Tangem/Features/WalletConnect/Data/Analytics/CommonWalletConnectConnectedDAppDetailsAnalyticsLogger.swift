//
//  CommonWalletConnectConnectedDAppDetailsAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class CommonWalletConnectConnectedDAppDetailsAnalyticsLogger: WalletConnectConnectedDAppDetailsAnalyticsLogger {
    func logDisconnectButtonTapped(for dAppData: WalletConnectDAppData) {
        Analytics.log(
            event: .walletConnectDAppDetailsDisconnectButtonTapped,
            params: [
                .walletConnectDAppName: dAppData.name,
                .walletConnectDAppUrl: dAppData.domain.absoluteString,
            ]
        )
    }
}
