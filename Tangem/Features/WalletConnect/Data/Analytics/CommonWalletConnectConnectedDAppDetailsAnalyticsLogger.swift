//
//  CommonWalletConnectConnectedDAppDetailsAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class CommonWalletConnectConnectedDAppDetailsAnalyticsLogger: WalletConnectConnectedDAppDetailsAnalyticsLogger {
    private let dAppData: WalletConnectDAppData

    init(dAppData: WalletConnectDAppData) {
        self.dAppData = dAppData
    }

    func logDisconnectButtonTapped() {
        Analytics.log(
            event: .walletConnectDAppDetailsDisconnectButtonTapped,
            params: [
                .walletConnectDAppName: dAppData.name,
                .walletConnectDAppUrl: dAppData.domain.absoluteString,
            ]
        )
    }

    func logDAppDisconnected() {
        Analytics.log(
            event: .walletConnectDAppDisconnected,
            params: [
                .walletConnectDAppName: dAppData.name,
                .walletConnectDAppUrl: dAppData.domain.absoluteString,
            ]
        )
    }
}
