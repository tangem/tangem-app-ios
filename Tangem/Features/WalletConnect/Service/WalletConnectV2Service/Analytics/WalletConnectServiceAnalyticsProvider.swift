//
//  WalletConnectServiceAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletConnectServiceAnalyticsProvider {
    func logReceiveHandleSolanaALTTransactionRequest()
    func logCompleteHandleSolanaALTTransactionRequest(isSuccess: Bool)
}

// MARK: - CommonWalletConnectServiceAnalyticsProvider

struct CommonWalletConnectServiceAnalyticsProvider: WalletConnectServiceAnalyticsProvider {
    // MARK: - Private Properties

    private let dAppData: WalletConnectDAppData?

    init(dAppData: WalletConnectDAppData?) {
        self.dAppData = dAppData
    }

    // MARK: - WalletConnectServiceAnalyticsProvider

    func logReceiveHandleSolanaALTTransactionRequest() {
        Analytics.log(
            event: .walletConnectTransactionSolanaLarge,
            params: [
                Analytics.ParameterKey.walletConnectDAppName: dAppData?.name ?? "",
            ]
        )
    }

    func logCompleteHandleSolanaALTTransactionRequest(isSuccess: Bool) {
        Analytics.log(
            .walletConnectTransactionSolanaLargeStatus,
            params: [
                .status: .successOrFailed(for: isSuccess),
            ]
        )
    }
}
